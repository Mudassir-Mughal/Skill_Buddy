const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  uid: { type: String },
  Fullname: { type: String },
  phone: { type: String },
  gender: { type: String },
  role: { type: String },
  education: { type: String },
  country: { type: String },
  skillsToTeach: [{ type: String }],
  skillsToTeachVector: [{ type: Number }],
  skillsToLearn: [{ type: String }],
  skillsToLearnVector: [{ type: Number }],
  profileSet: { type: Boolean, default: false },
  lastClickedSkill: {
    name: { type: String },
    index: { type: Number },
    timestamp: { type: Date }
  },
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', UserSchema);
