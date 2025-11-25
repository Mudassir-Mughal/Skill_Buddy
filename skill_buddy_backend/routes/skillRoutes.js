const express = require('express');
const router = express.Router();
const skillController = require('../controllers/skillController');

router.post('/', skillController.addSkill);
router.put('/:id', skillController.updateSkill);
router.get('/', skillController.getSkills);
router.get('/:id', skillController.getSkillById);
router.delete('/:id', skillController.deleteSkill);

module.exports = router;

