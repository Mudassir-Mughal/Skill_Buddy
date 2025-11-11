const mongoose = require('mongoose');

const RequestSchema = new mongoose.Schema({
  skillId: { type: String, required: true },
  title: { type: String, required: true },
  senderId: { type: String, required: true },
  receiverId: { type: String, required: true },
  status: { type: String, default: 'pending' },
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Request', RequestSchema);

