const mongoose = require('mongoose');

const chatRoomSchema = new mongoose.Schema({
  chatRoomId: { type: String, required: true, unique: true },
  participants: [{ type: String, required: true }],
  lastMessage: { type: String },
  lastMessageTime: { type: Date },
  lastSenderId: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('ChatRoom', chatRoomSchema);

