const mongoose = require('mongoose');

const SkillSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  instructor: { type: String, default: '' },
  title: { type: String, required: true },
  description: { type: String, required: true },
  expertlevel: { type: String, default: 'Beginner' },
  totalClasses: { type: Number, default: 0 },
  duration: { type: String, default: '' },
  exchangeFor: { type: [String], default: [] },
  price: { type: Number, default: 0 },
  timestamp: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Skill', SkillSchema);

