const ChatMessage = require('../models/chat');
const ChatRoom = require('../models/ChatRoom');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');

// Cloudinary config (ensure .env is set)
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

exports.getChatHistory = async (req, res) => {
  try {
    const { userId, receiverId } = req.params;
    const chatRoomId = userId < receiverId ? `${userId}_${receiverId}` : `${receiverId}_${userId}`;
    let messages = await ChatMessage.find({ chatRoomId }).sort({ timestamp: 1 }).lean();
    res.json(messages.map(m => ({ ...m, _id: m._id.toString() })));
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch chat history', error: err.message });
  }
};

exports.saveMessage = async (req, res) => {
  try {
    let msg = req.body;
    // No encryption
    const chatMsg = new ChatMessage({
      ...msg,
      timestamp: msg.timestamp ? new Date(msg.timestamp) : new Date(),
    });
    await chatMsg.save();

    // Upsert ChatRoom after saving message
    const chatRoomId = msg.chatRoomId;
    const participants = msg.participants || [msg.senderId, msg.receiverId];
    let lastMessage = '';
    if (msg.type === 'text') {
      lastMessage = msg.message && msg.message.trim() !== '' ? msg.message : '[Text]';
    } else if (msg.type === 'image') {
      lastMessage = '[Image]';
    } else if (msg.type === 'document') {
      lastMessage = '[Document]';
    } else {
      lastMessage = '[Message]';
    }
    await ChatRoom.findOneAndUpdate(
      { chatRoomId },
      {
        chatRoomId,
        participants,
        lastMessage,
        lastMessageTime: chatMsg.timestamp,
        lastSenderId: msg.senderId,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.status(201).json({ message: 'Message saved', chatMsg });
  } catch (err) {
    res.status(500).json({ message: 'Failed to save message', error: err.message });
  }
};

exports.getChatPartners = async (req, res) => {
  try {
    const { userId } = req.params;
    const messages = await ChatMessage.find({
      $or: [{ senderId: userId }, { receiverId: userId }]
    }).lean();
    const partnerIds = new Set();
    messages.forEach(msg => {
      if (msg.senderId !== userId) partnerIds.add(msg.senderId);
      if (msg.receiverId !== userId) partnerIds.add(msg.receiverId);
    });
    res.json([...partnerIds]);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch chat partners', error: err.message });
  }
};

exports.getChatList = async (req, res) => {
  try {
    const { userId } = req.params;

    console.log('Querying chat rooms for userId:', userId);

    const chatRooms = await ChatRoom.find({
      participants: { $in: [String(userId)] }
    })
      .sort({ lastMessageTime: -1 })
      .lean();

    console.log('Found chatRooms:', chatRooms);

    res.json(chatRooms.map(room => ({ ...room, _id: room._id.toString() })));
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch chat list', error: err.message });
  }
};

exports.uploadFile = async (req, res) => {
  try {
    const { type } = req.body;
    const file = req.file;
    if (!file) return res.status(400).json({ error: 'No file uploaded' });
    let resourceType = type === 'image' ? 'image' : 'raw';
    const uploadStream = cloudinary.uploader.upload_stream(
      { resource_type: resourceType, folder: 'chat_uploads', use_filename: true, unique_filename: false },
      (error, result) => {
        if (error) return res.status(500).json({ error: error.message });
        res.json({ url: result.secure_url, fileName: file.originalname });
      }
    );
    streamifier.createReadStream(file.buffer).pipe(uploadStream);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
