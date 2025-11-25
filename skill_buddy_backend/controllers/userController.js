const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');

exports.signup = async (req, res) => {
  const { email, password } = req.body;
  try {
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already exists' });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ email, password: hashedPassword });
    await user.save();
    res.status(201).json({ message: 'User registered successfully', userId: user._id });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    const token = jwt.sign({ userId: user._id }, 'your_jwt_secret', { expiresIn: '1d' });
    res.json({ token, userId: user._id });
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.updateUser = async (req, res) => {
  try {
    const update = req.body;
    if (update.password) delete update.password;
    const user = await User.findByIdAndUpdate(req.params.id, update, { new: true, runValidators: true });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json({ message: 'Profile updated successfully', user });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update profile', error: err.message });
  }
};

exports.getAllUsers = async (req, res) => {
  try {
    // Exclude password field for security
    let users = await User.find().select('-password');
    // Filter out users with missing or empty skill vectors
    users = users.filter(u => {
      const teach = Array.isArray(u.skillsToTeachVector) ? u.skillsToTeachVector : [];
      const learn = Array.isArray(u.skillsToLearnVector) ? u.skillsToLearnVector : [];
      // Vectors must be non-empty and same length
      return teach.length > 0 && learn.length > 0 && teach.length === learn.length;
    });
    // Debug log for backend (safe syntax)
    console.log('Returned users for similarity:', users.map(function(u) {
      return {
        _id: u._id,
        Fullname: u.Fullname,
        skillsToTeachVector: u.skillsToTeachVector,
        skillsToLearnVector: u.skillsToLearnVector
      };
    }));
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch users', error: err.message });
  }
};

exports.saveLastClickedSkill = async (req, res) => {
  try {
    const { userId, skillName, skillIndex } = req.body;
    if (!userId || !skillName || skillIndex == null) {
      return res.status(400).json({ message: 'Missing parameters' });
    }
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    user.lastClickedSkill = { name: skillName, index: skillIndex, timestamp: new Date() };
    await user.save();
    res.json({ message: 'Last clicked skill saved', lastClickedSkill: user.lastClickedSkill });
  } catch (err) {
    res.status(500).json({ message: 'Failed to save last clicked skill', error: err.message });
  }
};

exports.getUserByEmail = async (req, res) => {
  const email = req.query.email;
  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }
  try {
    const user = await User.findOne({ email }).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.googleSignup = async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }
  try {
    let user = await User.findOne({ email });
    if (!user) {
      user = new User({ email, password: 'google-oauth', profileSet: false }); // Explicitly set password for Google users
      await user.save();
      console.log('Google user created:', user);
    } else {
      console.log('Google user exists:', user);
    }
    res.status(201).json({ userId: user._id, email: user.email, profileSet: user.profileSet, role: user.role });
  } catch (err) {
    console.error('Google signup error:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// --- OTP-based Forgot Password ---
exports.forgotPassword = async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: 'Email is required' });
  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });
    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expire = new Date(Date.now() + 10 * 60 * 1000); // 10 min
    user.resetOtp = otp;
    user.resetOtpExpire = expire;
    await user.save();
    // Send OTP email
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL,
        pass: process.env.EMAIL_PASSWORD
      }
    });
    await transporter.sendMail({
      from: process.env.EMAIL,
      to: user.email,
      subject: 'Skill Buddy Password Reset OTP',
      text: `Your OTP for password reset is: ${otp}. It will expire in 10 minutes.`
    });
    return res.json({ message: 'OTP sent to email' });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.verifyOtp = async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ message: 'Email and OTP are required' });
  try {
    const user = await User.findOne({ email });
    if (!user || !user.resetOtp || !user.resetOtpExpire) return res.status(400).json({ message: 'OTP not requested' });
    if (user.resetOtp !== otp) return res.status(400).json({ message: 'Invalid OTP' });
    if (user.resetOtpExpire < new Date()) return res.status(400).json({ message: 'OTP expired' });
    return res.json({ message: 'OTP verified' });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.resetPassword = async (req, res) => {
  const { email, newPassword } = req.body;
  if (!email || !newPassword) return res.status(400).json({ message: 'Email and newPassword are required' });
  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    user.resetOtp = null;
    user.resetOtpExpire = null;
    await user.save();
    return res.json({ message: 'Password updated' });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.checkEmailExists = async (req, res) => {
  const email = req.query.email;
  if (!email) {
    return res.status(400).json({ exists: false, message: 'Email is required' });
  }
  try {
    const user = await User.findOne({ email });
    res.json({ exists: !!user });
  } catch (err) {
    res.status(500).json({ exists: false, message: 'Server error' });
  }
};
