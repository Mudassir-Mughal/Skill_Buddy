const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema({
  chatRoomId: { type: String, required: true },
  senderId: { type: String, required: true },
  receiverId: { type: String, required: true },
  type: { type: String, enum: ['text', 'image', 'document'], default: 'text' },
  message: { type: String },
  url: { type: String },
  fileName: { type: String },
  timestamp: { type: Date, default: Date.now },
  participants: [{ type: String }],
});

module.exports = mongoose.model('ChatMessage', chatMessageSchema);

