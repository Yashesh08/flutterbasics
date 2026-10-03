const mongoose = require('mongoose');

const menuItemSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    category: {
      type: String,
      required: true,
      trim: true,
      enum: ['Meals', 'Snacks', 'Drinks', 'Desserts', 'Beverages', 'Combos'],
      default: 'Meals',
    },
    prepTime: {
      type: String,
      required: true,
      default: '10 min',
    },
    imageUrl: {
      type: String,
      default: '',
    },
    available: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('MenuItem', menuItemSchema);
