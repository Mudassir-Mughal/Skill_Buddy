const mongoose = require('mongoose');

const LessonSchema = new mongoose.Schema({
  instructorId: { type: String, required: true },
  studentId: { type: String, required: true },
  outline: { type: String, required: true },
  date: { type: String, required: true }, // Format: YYYY-MM-DD
  start_time: { type: String, required: true }, // Format: HH:mm
  end_time: { type: String, required: true }, // Format: HH:mm
  enabled: { type: Boolean, default: false },
  lessonId: { type: String },
  roomId: { type: String },
  status: { type: String, default: 'scheduled' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Lesson', LessonSchema);

