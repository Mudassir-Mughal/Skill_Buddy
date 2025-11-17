const ChatMessage = require('../models/chat');

exports.getChatHistory = async (req, res) => {
  try {
    const { userId, receiverId } = req.params;
    const chatRoomId = userId < receiverId ? `${userId}_${receiverId}` : `${receiverId}_${userId}`;
    const messages = await ChatMessage.find({ chatRoomId }).sort({ timestamp: 1 }).lean();
    res.json(messages.map(m => ({ ...m, _id: m._id.toString() })));
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch chat history', error: err.message });
  }
};

exports.saveMessage = async (req, res) => {
  try {
    const msg = req.body;
    const chatMsg = new ChatMessage({
      ...msg,
      timestamp: msg.timestamp ? new Date(msg.timestamp) : new Date(),
    });
    await chatMsg.save();
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
