const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.post('/signup', userController.signup);
router.post('/login', userController.login);
router.get('/by-email', userController.getUserByEmail);
router.get('/:id', userController.getUser);
router.put('/:id', userController.updateUser);
router.get('/', userController.getAllUsers);
router.post('/saveLastClickedSkill', userController.saveLastClickedSkill);
router.post('/google-signup', userController.googleSignup);
router.post('/forgot-password', userController.forgotPassword);
router.post('/verify-otp', userController.verifyOtp);
router.post('/reset-password', userController.resetPassword);
router.get('/check-email', userController.checkEmailExists);

module.exports = router;
