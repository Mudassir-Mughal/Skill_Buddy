const Lesson = require('../models/lesson');

exports.createLesson = async (req, res) => {
  try {
    const lesson = new Lesson(req.body);
    await lesson.save();
    res.status(201).json(lesson);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.updateLesson = async (req, res) => {
  try {
    const lesson = await Lesson.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!lesson) return res.status(404).json({ message: 'Lesson not found' });
    res.json(lesson);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.deleteLesson = async (req, res) => {
  try {
    const lesson = await Lesson.findByIdAndDelete(req.params.id);
    if (!lesson) {
      return res.status(404).json({ message: 'Lesson not found' });
    }
    res.json({ message: 'Lesson deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete lesson', error: err.message });
  }
};

exports.getLessons = async (req, res) => {
  try {
    const { instructorId, studentId } = req.query;
    let filter = {};
    if (instructorId && studentId) {
      filter = {
        $or: [
          { instructorId: instructorId },
          { studentId: studentId }
        ]
      };
    } else if (instructorId) {
      filter.instructorId = instructorId;
    } else if (studentId) {
      filter.studentId = studentId;
    }
    const lessons = await Lesson.find(filter).sort({ date: 1, start_time: 1 });
    res.json(lessons);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getLessonById = async (req, res) => {
  try {
    const lesson = await Lesson.findById(req.params.id);
    if (!lesson) return res.status(404).json({ message: 'Lesson not found' });
    res.json(lesson);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

