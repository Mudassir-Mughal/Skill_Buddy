const express = require('express');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();
app.use(bodyParser.json());

// API endpoint to send notification to a device
app.post('/send-notification', async (req, res) => {
  const { token, title, body, data } = req.body;
  if (!token || !title || !body) {
    return res.status(400).json({ error: "token, title, body required" });
  }
  const message = {
    notification: { title, body },
    token,
    data: data || {},
  };
  try {
    const response = await admin.messaging().send(message);
    res.json({ success: true, response });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/', (req, res) => res.send('FCM backend running.'));
const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`FCM server running on port ${PORT}`));