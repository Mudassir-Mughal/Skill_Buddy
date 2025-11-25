const express = require('express');
const router = express.Router();
const lessonController = require('../controllers/lessonController');

router.post('/', lessonController.createLesson);
router.put('/:id', lessonController.updateLesson);
router.delete('/:id', lessonController.deleteLesson);
router.get('/', lessonController.getLessons);
router.get('/:id', lessonController.getLessonById);

module.exports = router;

