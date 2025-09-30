// server.js
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const nodemailer = require("nodemailer");

const app = express();
app.use(cors());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

let otpStore = {}; // { email: { otp: "123456", expiry: Date } }

// 📩 Email transport (using Gmail SMTP for demo)
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "yourgmail@gmail.com", // your Gmail
    pass: "yourapppassword"      // Gmail App Password (not normal password)
  }
});

// 1️⃣ Send OTP
app.post("/send-otp", (req, res) => {
  const { email } = req.body;
  const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP
  const expiry = Date.now() + 5 * 60 * 1000; // 5 minutes

  otpStore[email] = { otp, expiry };

  const mailOptions = {
    from: "yourgmail@gmail.com",
    to: email,
    subject: "Your OTP Code",
    text: `Your OTP is ${otp}. It will expire in 5 minutes.`
  };

  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      return res.status(500).json({ success: false, error });
    }
    res.json({ success: true, message: "OTP sent successfully!" });
  });
});

// 2️⃣ Verify OTP
app.post("/verify-otp", (req, res) => {
  const { email, otp } = req.body;
  const record = otpStore[email];

  if (!record) return res.status(400).json({ success: false, message: "No OTP found" });
  if (Date.now() > record.expiry) return res.status(400).json({ success: false, message: "OTP expired" });
  if (record.otp !== otp) return res.status(400).json({ success: false, message: "Invalid OTP" });

  res.json({ success: true, message: "OTP verified" });
});

// 3️⃣ Reset Password (dummy)
app.post("/reset-password", (req, res) => {
  const { email, password } = req.body;

  // Here you should hash and save password in DB. For demo we just log it.
  console.log(`Password for ${email} changed to: ${password}`);

  res.json({ success: true, message: "Password reset successfully!" });
});

const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
