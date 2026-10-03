const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    menuItemId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MenuItem',
      required: true,
    },
    name: { type: String, required: true },
    price: { type: Number, required: true },
    quantity: { type: Number, required: true, min: 1 },
    subtotal: { type: Number, required: true },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    studentName: { type: String, required: true, trim: true },
    studentEmail: { type: String, required: true, trim: true, lowercase: true },
    items: { type: [orderItemSchema], required: true, validate: (v) => v.length > 0 },
    totalAmount: { type: Number, required: true },
    status: {
      type: String,
      enum: ['pending', 'preparing', 'ready', 'collected', 'cancelled'],
      default: 'pending',
    },
    specialInstructions: { type: String, default: '', trim: true },
    estimatedPrepTime: { type: String, default: '' },
  },
  { timestamps: true }
);

// Index for efficient queries by student and status
orderSchema.index({ studentEmail: 1, createdAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('Order', orderSchema);
