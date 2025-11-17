const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

router.get('/:userId/:receiverId', chatController.getChatHistory);
router.post('/', chatController.saveMessage);
router.get('/partners/:userId', chatController.getChatPartners);

module.exports = router;

