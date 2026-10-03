/// Represents a single item within a placed order.
class OrderItem {
  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menuItemId']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
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
    this.specialInstructions = '',
    this.estimatedPrepTime = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String studentName;
  final String studentEmail;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String specialInstructions;
  final String estimatedPrepTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        studentName: json['studentName'] as String? ?? '',
        studentEmail: json['studentEmail'] as String? ?? '',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'pending',
        specialInstructions: json['specialInstructions'] as String? ?? '',
        estimatedPrepTime: json['estimatedPrepTime'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  Order copyWith({String? status}) => Order(
        id: id,
        studentName: studentName,
        studentEmail: studentEmail,
        items: items,
        totalAmount: totalAmount,
        status: status ?? this.status,
        specialInstructions: specialInstructions,
        estimatedPrepTime: estimatedPrepTime,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

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

  /// Whether the order is still active (not completed or cancelled).
  bool get isActive =>
      status == 'pending' || status == 'preparing' || status == 'ready';
}
