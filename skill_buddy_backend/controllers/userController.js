const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

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
      user = new User({ email, profileSet: false });
      await user.save();
    }
    res.status(201).json(user);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
