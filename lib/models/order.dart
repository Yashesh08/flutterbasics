import 'package:flutter/material.dart';

/// Represents a single item within a placed order.
class OrderItem {
  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.prepTime = '',
  });

  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String prepTime;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menuItemId']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        prepTime: json['prepTime'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
        'prepTime': prepTime,
      };
}

/// Represents a full order placed by a student.
class Order {
  const Order({
    required this.id,
    required this.studentName,
    required this.studentEmail,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.userId,
    this.orderType = 'dine-in',
    this.expectedReadyAt,
    this.specialInstructions = '',
    this.estimatedPrepTime = '',
    this.queuePosition = 1,
    this.ordersAhead = 0,
    this.queueWaitTime = '0 min',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String studentName;
  final String studentEmail;
  final List<OrderItem> items;
  final double totalAmount;
  final String orderType;
  final String status;
  final DateTime? expectedReadyAt;
  final String specialInstructions;
  final String estimatedPrepTime;
  final int queuePosition;
  final int ordersAhead;
  final String queueWaitTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        userId: json['userId']?.toString(),
        studentName: json['studentName'] as String? ?? '',
        studentEmail: json['studentEmail'] as String? ?? '',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        orderType: json['orderType'] as String? ?? 'dine-in',
        status: json['status'] as String? ?? 'pending',
        expectedReadyAt: json['expectedReadyAt'] != null
            ? DateTime.tryParse(json['expectedReadyAt'] as String)
            : null,
        specialInstructions: json['specialInstructions'] as String? ?? '',
        estimatedPrepTime: json['estimatedPrepTime'] as String? ?? '',
        queuePosition: (json['queuePosition'] as num?)?.toInt() ?? 1,
        ordersAhead: (json['ordersAhead'] as num?)?.toInt() ?? 0,
        queueWaitTime: json['queueWaitTime'] as String? ?? '0 min',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'userId': userId,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'items': items.map((i) => i.toJson()).toList(),
        'totalAmount': totalAmount,
        'orderType': orderType,
        'status': status,
        if (expectedReadyAt != null)
          'expectedReadyAt': expectedReadyAt!.toIso8601String(),
        'specialInstructions': specialInstructions,
        'estimatedPrepTime': estimatedPrepTime,
        'queuePosition': queuePosition,
        'ordersAhead': ordersAhead,
        'queueWaitTime': queueWaitTime,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  Order copyWith({
    String? status,
    String? orderType,
    DateTime? expectedReadyAt,
    String? estimatedPrepTime,
    int? queuePosition,
    int? ordersAhead,
    String? queueWaitTime,
  }) =>
      Order(
        id: id,
        userId: userId,
        studentName: studentName,
        studentEmail: studentEmail,
        items: items,
        totalAmount: totalAmount,
        orderType: orderType ?? this.orderType,
        status: status ?? this.status,
        expectedReadyAt: expectedReadyAt ?? this.expectedReadyAt,
        specialInstructions: specialInstructions,
        estimatedPrepTime: estimatedPrepTime ?? this.estimatedPrepTime,
        queuePosition: queuePosition ?? this.queuePosition,
        ordersAhead: ordersAhead ?? this.ordersAhead,
        queueWaitTime: queueWaitTime ?? this.queueWaitTime,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  bool get isTakeaway => orderType.toLowerCase() == 'takeaway';
  bool get isDineIn => orderType.toLowerCase() == 'dine-in';

  String get formattedOrderType => isTakeaway ? 'Takeaway' : 'Dine-In';

  IconData get orderTypeIcon =>
      isTakeaway ? Icons.takeout_dining : Icons.restaurant;

  String get formattedReadyTime {
    if (expectedReadyAt != null) {
      final local = expectedReadyAt!.toLocal();
      final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    return estimatedPrepTime.isNotEmpty ? estimatedPrepTime : '10 min';
  }

  /// Human-friendly status label.
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'collected':
        return 'Collected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Color associated with order status.
  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'collected':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Whether the order is still active (not completed or cancelled).
  bool get isActive =>
      status == 'pending' || status == 'preparing' || status == 'ready';

  /// Queue position display string (e.g. 'Queue #3').
  String get queuePositionBadge => 'Queue #$queuePosition';

  /// Human-friendly queue status explanation.
  String get queueSummary {
    if (ordersAhead == 0) {
      return 'First in kitchen queue (Immediate prep)';
    }
    return '$ordersAhead order${ordersAhead > 1 ? 's' : ''} ahead in kitchen queue';
  }

  /// Full queue wait breakdown for user display.
  String get queueWaitBreakdown =>
      'Queue wait: ~$queueWaitTime • Est. Total: $estimatedPrepTime';
}
