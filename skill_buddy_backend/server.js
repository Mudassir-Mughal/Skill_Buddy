require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
app.use(express.json());
app.use(cors());

// Import routes
const userRoutes = require('./routes/userRoutes');
const skillRoutes = require('./routes/skillRoutes');
const requestRoutes = require('./routes/requestRoutes');
const lessonRoutes = require('./routes/lessonRoutes');
const chatRoutes = require('./routes/chatRoutes');

// Use routes
app.use('/api/users', userRoutes);
app.use('/api/skills', skillRoutes);
app.use('/api/requests', requestRoutes);
app.use('/api/lessons', lessonRoutes);
app.use('/api/chats', chatRoutes);

// Test route
app.get('/', (req, res) => {
  res.send('Skill Buddy Backend is running!');
});

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
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
      const ChatMessage = require('./models/chat');
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
