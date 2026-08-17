const mongoose = require('mongoose');

const savedCodeSchema = new mongoose.Schema(
  {
    email: { type: String },
    originalCode: { type: String, required: true },
    correctedCode: { type: String },
    errors: { type: String },
    language: { type: String },
  },
  { timestamps: true }
);

// Prevent model overwrite errors on Vercel serverless hot-reloads
module.exports = mongoose.models.SavedCode || mongoose.model('SavedCode', savedCodeSchema);