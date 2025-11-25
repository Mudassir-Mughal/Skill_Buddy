const Skill = require('../models/skill');
const mongoose = require('mongoose');

exports.addSkill = async (req, res) => {
  try {
    const skill = new Skill(req.body);
    await skill.save();
    res.status(201).json({ message: 'Skill added successfully', skill });
  } catch (err) {
    res.status(500).json({ message: 'Failed to add skill', error: err.message });
  }
};

exports.updateSkill = async (req, res) => {
  try {
    const skill = await Skill.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!skill) {
      return res.status(404).json({ message: 'Skill not found' });
    }
    res.json({ message: 'Skill updated successfully', skill });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update skill', error: err.message });
  }
};

exports.getSkills = async (req, res) => {
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
};

exports.deleteSkill = async (req, res) => {
  try {
    const skill = await Skill.findByIdAndDelete(req.params.id);
    if (!skill) {
      return res.status(404).json({ message: 'Skill not found' });
    }
    res.json({ message: 'Skill deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete skill', error: err.message });
  }
};

exports.getSkillById = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid skill id' });
    }
    const skill = await Skill.findById(req.params.id);
    if (!skill) {
      return res.status(404).json({ message: 'Skill not found' });
    }
    res.json(skill);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch skill', error: err.message });
  }
};

