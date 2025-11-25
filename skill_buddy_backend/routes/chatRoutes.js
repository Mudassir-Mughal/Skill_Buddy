const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const multer = require('multer');

// Multer config for memory storage (max 50MB)
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

// Specific routes first
router.get('/partners/:userId', chatController.getChatPartners);
router.get('/chatlist/:userId', chatController.getChatList);

// File upload route
router.post('/upload', upload.single('file'), chatController.uploadFile);

// General chat routes last
router.get('/:userId/:receiverId', chatController.getChatHistory);
router.post('/', chatController.saveMessage);

module.exports = router;
