require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const http = require('http');
const { Server } = require('socket.io');

const User = require('./models/User');
const Test = require('./models/test');
const Skill = require('./models/skill');
const Request = require('./models/request');
const ChatMessage = require('./models/chat');
const Lesson = require('./models/lesson');

const app = express();
app.use(express.json());
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Test route
app.get('/', (req, res) => {
  res.send('Skill Buddy Backend is running!');
});

// Signup endpoint
app.post('/api/signup', async (req, res) => {
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
});

// Login endpoint
app.post('/api/login', async (req, res) => {
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
});

// /test-db route to create a sample document
app.post('/test-db', async (req, res) => {
  try {
    const { name } = req.body;
    const testDoc = new Test({ name });
    await testDoc.save();
    res.status(201).json({ message: 'Test document saved successfully', document: testDoc });
  } catch (err) {
    res.status(500).json({ message: 'Failed to save test document', error: err.message });
  }
});

// Get user profile by ID
app.get('/api/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Update user profile by ID
app.put('/api/users/:id', async (req, res) => {
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
});

// Add a new skill
app.post('/api/skills', async (req, res) => {
  try {
    const skill = new Skill(req.body);
    await skill.save();
    res.status(201).json({ message: 'Skill added successfully', skill });
  } catch (err) {
    res.status(500).json({ message: 'Failed to add skill', error: err.message });
  }
});

// Update an existing skill
app.put('/api/skills/:id', async (req, res) => {
  try {
    const skill = await Skill.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!skill) {
      return res.status(404).json({ message: 'Skill not found' });
    }
    res.json({ message: 'Skill updated successfully', skill });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update skill', error: err.message });
  }
});

// Get all skills or search skills by title
app.get('/api/skills', async (req, res) => {
  try {
    const { userId, search } = req.query;
    let filter = {};
    if (userId) {
      filter.userId = userId;
    }
    if (search && search.trim() !== '') {
      filter.title = { $regex: search, $options: 'i' };
    }
    const skills = await Skill.find(filter).lean();
    res.json(skills.map(skill => ({ ...skill, _id: skill._id.toString() })));
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch skills', error: err.message });
  }
});

// Delete a skill by ID
app.delete('/api/skills/:id', async (req, res) => {
  try {
    const skill = await Skill.findByIdAndDelete(req.params.id);
    if (!skill) {
      return res.status(404).json({ message: 'Skill not found' });
    }
    res.json({ message: 'Skill deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete skill', error: err.message });
  }
});

// Get a single skill by ID
app.get('/api/skills/:id', async (req, res) => {
  try {
    console.log('Requested skill id:', req.params.id);
    const allSkills = await Skill.find({});
    console.log('All skills in DB:', allSkills.map(s => s._id.toString()));
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      console.log('Invalid ObjectId received:', req.params.id);
      return res.status(400).json({ message: 'Invalid skill id' });
    }
    const skill = await Skill.findById(req.params.id);
    if (!skill) {
      console.log('Skill not found for id:', req.params.id);
      return res.status(404).json({ message: 'Skill not found' });
    }
    res.json(skill);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch skill', error: err.message });
  }
});

// Create a new request
app.post('/api/requests', async (req, res) => {
  try {
    const { skillId, title, senderId, receiverId, status, timestamp } = req.body;
    const existing = await Request.findOne({ skillId, senderId });
    if (existing) {
      return res.status(409).json({ message: 'Request already sent' });
    }
    const request = new Request({ skillId, title, senderId, receiverId, status, timestamp });
    await request.save();
    res.status(201).json({ message: 'Request sent', request });
  } catch (err) {
    res.status(500).json({ message: 'Failed to send request', error: err.message });
  }
});

// Get requests for a user
app.get('/api/requests', async (req, res) => {
  try {
    const { senderId, receiverId, skillId } = req.query;
    let filter = {};
    if (senderId) filter.senderId = senderId;
    if (receiverId) filter.receiverId = receiverId;
    if (skillId) filter.skillId = skillId;
    const requests = await Request.find(filter).lean();
    res.json(requests);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch requests', error: err.message });
  }
});

// Delete a request by ID
app.delete('/api/requests/:id', async (req, res) => {
  try {
    const request = await Request.findByIdAndDelete(req.params.id);
    if (!request) {
      return res.status(404).json({ message: 'Request not found' });
    }
    res.json({ message: 'Request deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete request', error: err.message });
  }
});

// Update a request status (accept/decline)
app.patch('/api/requests/:id', async (req, res) => {
  try {
    const update = req.body;
    const request = await Request.findByIdAndUpdate(req.params.id, update, { new: true, runValidators: true });
    if (!request) {
      return res.status(404).json({ message: 'Request not found' });
    }
    res.json({ message: 'Request updated successfully', request });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update request', error: err.message });
  }
});

// Create a lesson
app.post('/api/lessons', async (req, res) => {
  try {
    const lesson = new Lesson(req.body);
    await lesson.save();
    res.status(201).json(lesson);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Update a lesson by ID
app.put('/api/lessons/:id', async (req, res) => {
  try {
    const lesson = await Lesson.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!lesson) return res.status(404).json({ message: 'Lesson not found' });
    res.json(lesson);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Delete a lesson by ID
app.delete('/api/lessons/:id', async (req, res) => {
  try {
    const lesson = await Lesson.findByIdAndDelete(req.params.id);
    if (!lesson) {
      return res.status(404).json({ message: 'Lesson not found' });
    }
    res.json({ message: 'Lesson deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete lesson', error: err.message });
  }
});

// Get all lessons for an instructor or student
app.get('/api/lessons', async (req, res) => {
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
});

// Get a lesson by ID
app.get('/api/lessons/:id', async (req, res) => {
  try {
    const lesson = await Lesson.findById(req.params.id);
    if (!lesson) return res.status(404).json({ message: 'Lesson not found' });
    res.json(lesson);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// --- Socket.IO Chat Events ---
io.on('connection', (socket) => {
  console.log('Socket connected:', socket.id);

  socket.on('joinChat', ({ chatRoomId, userId }) => {
    socket.join(chatRoomId);
    console.log(`User ${userId} joined chatRoom ${chatRoomId}`);
  });

  socket.on('sendMessage', async (msg) => {
    try {
      // Save to MongoDB
      const chatMsg = new ChatMessage({
        ...msg,
        timestamp: msg.timestamp ? new Date(msg.timestamp) : new Date(),
      });
      await chatMsg.save();
      io.to(msg.chatRoomId).emit('receiveMessage', chatMsg.toObject());
      console.log('Message sent and broadcasted:', chatMsg);
    } catch (err) {
      console.error('Error saving chat message:', err);
    }
  });

  socket.on('disconnect', () => {
    console.log('Socket disconnected:', socket.id);
  });
});

// --- REST API for chat history and send ---
app.get('/api/chats/:userId/:receiverId', async (req, res) => {
  try {
    const { userId, receiverId } = req.params;
    const chatRoomId = userId < receiverId ? `${userId}_${receiverId}` : `${receiverId}_${userId}`;
    const messages = await ChatMessage.find({ chatRoomId }).sort({ timestamp: 1 }).lean();
    res.json(messages.map(m => ({ ...m, _id: m._id.toString() })));
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch chat history', error: err.message });
  }
});

app.post('/api/chats', async (req, res) => {
  try {
    const msg = req.body;
    const chatMsg = new ChatMessage({
      ...msg,
      timestamp: msg.timestamp ? new Date(msg.timestamp) : new Date(),
    });
    await chatMsg.save();
    res.status(201).json({ message: 'Message saved', chatMsg });
  } catch (err) {
    res.status(500).json({ message: 'Failed to save message', error: err.message });
  }
});

// Get all chat partners for a user
app.get('/api/chats/partners/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    // Find all chat messages where user is sender or receiver
    const messages = await ChatMessage.find({
      $or: [{ senderId: userId }, { receiverId: userId }]
    }).lean();

    // Extract unique partner IDs
    const partnerIds = new Set();
    messages.forEach(msg => {
      if (msg.senderId !== userId) partnerIds.add(msg.senderId);
      if (msg.receiverId !== userId) partnerIds.add(msg.receiverId);
    });
    res.json([...partnerIds]);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch chat partners', error: err.message });
  }
});

// --------------------
// ✅ MongoDB Connection (moved to bottom)
// --------------------
const mongoURI = `mongodb+srv://mughalmudassir33_db_user:${process.env.MONGODB_PASSWORD}@skillbuddy.4bmdj4u.mongodb.net/SkillBuddy?retryWrites=true&w=majority`;

mongoose.connect(mongoURI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => {
    console.log('MongoDB Atlas connected');
    const PORT = 3000;
    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });
