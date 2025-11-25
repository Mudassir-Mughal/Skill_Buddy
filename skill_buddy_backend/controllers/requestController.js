const Request = require('../models/request');

exports.createRequest = async (req, res) => {
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
};

exports.getRequests = async (req, res) => {
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
};

exports.deleteRequest = async (req, res) => {
  try {
    const request = await Request.findByIdAndDelete(req.params.id);
    if (!request) {
      return res.status(404).json({ message: 'Request not found' });
    }
    res.json({ message: 'Request deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete request', error: err.message });
  }
};

exports.updateRequest = async (req, res) => {
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
};

