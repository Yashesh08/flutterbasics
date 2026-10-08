const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    menuItemId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MenuItem',
      required: true,
    },
    name: { type: String, required: true },
    price: { type: Number, required: true, min: 0 },
    quantity: { type: Number, required: true, min: 1 },
    subtotal: { type: Number, required: true, min: 0 },
    prepTime: { type: String, default: '10 min' },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: false,
    },
    studentName: { type: String, required: true, trim: true },
    studentEmail: { type: String, required: true, trim: true, lowercase: true },
    items: {
      type: [orderItemSchema],
      required: true,
      validate: [(v) => Array.isArray(v) && v.length > 0, 'Order must contain at least one item.'],
    },
    totalAmount: { type: Number, required: true, min: 0 },
    orderType: {
      type: String,
      enum: ['dine-in', 'takeaway'],
      default: 'dine-in',
    },
    status: {
      type: String,
      enum: ['awaiting_payment', 'pending', 'preparing', 'ready', 'collected', 'cancelled'],
      default: 'pending',
    },
    paymentMethod: {
      type: String,
      enum: ['online', 'offline'],
      default: 'online',
    },
    paymentStatus: {
      type: String,
      enum: ['paid', 'pending_payment', 'failed'],
      default: 'paid',
    },
    tokenNumber: {
      type: String,
      default: null,
      trim: true,
    },
    expectedReadyAt: {
      type: Date,
      required: false,
    },
    estimatedPrepTime: {
      type: String,
      default: '',
    },
    queuePosition: {
      type: Number,
      default: null,
    },
    ordersAhead: {
      type: Number,
      default: null,
    },
    queueWaitTime: {
      type: String,
      default: '0 min',
    },
    specialInstructions: {
      type: String,
      default: '',
      trim: true,
    },
  },
  { timestamps: true }
);

// Index for efficient queries by student and status
orderSchema.index({ userId: 1, createdAt: -1 });
orderSchema.index({ studentEmail: 1, createdAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });
orderSchema.index({ orderType: 1 });

module.exports = mongoose.model('Order', orderSchema);
