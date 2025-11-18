const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.post('/signup', userController.signup);
router.post('/login', userController.login);
router.get('/:id', userController.getUser);
router.put('/:id', userController.updateUser);
router.get('/', userController.getAllUsers);
router.post('/saveLastClickedSkill', userController.saveLastClickedSkill);
router.get('/by-email', userController.getUserByEmail);
router.post('/google-signup', userController.googleSignup);

module.exports = router;
