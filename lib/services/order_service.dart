import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import 'api_config.dart';

/// Service that handles order-related API calls.
/// Falls back to a local in-memory store when the server is unreachable.
class OrderService {
  OrderService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? defaultApiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  // ── In-memory fallback store ──────────────────────────────────────────
  final List<Order> _localOrders = [];
  int _localIdCounter = 1;

  // ── Place Order ───────────────────────────────────────────────────────
  Future<Order> placeOrder({
    required String studentName,
    required String studentEmail,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? userId,
    String orderType = 'dine-in',
    String specialInstructions = '',
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/orders'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (userId != null && userId.isNotEmpty) 'userId': userId,
          'studentName': studentName,
          'studentEmail': studentEmail,
          'items': items,
          'totalAmount': totalAmount,
          'orderType': orderType,
          'specialInstructions': specialInstructions,
        }),
      );

      if (response.statusCode == 201) {
        final order = Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        _localOrders.insert(0, order);
        return order;
      }
      throw Exception('Failed to place order: ${response.statusCode}');
    } catch (_) {
      return _placeOrderLocally(
        userId: userId,
        studentName: studentName,
        studentEmail: studentEmail,
        items: items,
        totalAmount: totalAmount,
        orderType: orderType,
        specialInstructions: specialInstructions,
      );
    }
  }

  // ── Fetch Kitchen Queue & ETA Estimation ─────────────────────────────
  Future<Map<String, dynamic>> fetchQueueEstimate({int? itemPrepMinutes}) async {
    try {
      final queryParams = <String, String>{};
      if (itemPrepMinutes != null) {
        queryParams['prepTime'] = '$itemPrepMinutes';
      }
      final uri = Uri.parse('$_baseUrl/api/orders/queue-estimate')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch queue estimate: ${response.statusCode}');
    } catch (_) {
      final activeCount = _localOrders.where((o) => o.isActive).length;
      final queueWait = activeCount == 0 ? 0 : ((activeCount + 1) ~/ 2) * 3;
      final basePrep = itemPrepMinutes ?? 8;
      final totalEta = basePrep + queueWait + 3;
      return {
        'ordersInQueue': activeCount,
        'ordersAhead': activeCount,
        'queuePosition': activeCount + 1,
        'queueWaitMinutes': queueWait,
        'itemPrepMinutes': basePrep,
        'bufferMinutes': 3,
        'totalEtaMinutes': totalEta,
        'estimatedPrepTime': '$totalEta min',
        'queueWaitTime': '$queueWait min',
        'kitchenCapacity': 2,
      };
    }
  }

  // ── Fetch Student's Own Past Orders (Day 4) ───────────────────────────
  Future<List<Order>> fetchMyOrders({String? email, String? token, String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (email != null && email.isNotEmpty) queryParams['email'] = email;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else if (email != null && email.isNotEmpty) {
        headers['x-user-email'] = email;
      }

      final uri = Uri.parse('$_baseUrl/api/orders/my').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch my orders: ${response.statusCode}');
    } catch (_) {
      return _fetchOrdersLocally(email: email, status: status);
    }
  }

  // ── Fetch Orders ──────────────────────────────────────────────────────
  Future<List<Order>> fetchOrders({String? email, String? status}) async {
    if (email != null && email.isNotEmpty) {
      return fetchMyOrders(email: email, status: status);
    }
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$_baseUrl/api/orders').replace(queryParameters: queryParams);
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch orders');
    } catch (_) {
      return _fetchOrdersLocally(email: email, status: status);
    }
  }

  // ── Fetch Single Order ────────────────────────────────────────────────
  Future<Order?> fetchOrder(String orderId) async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/api/orders/$orderId'));
      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      try {
        return _localOrders.firstWhere((o) => o.id == orderId);
      } catch (_) {
        return null;
      }
    }
  }

  // ── Update Order Status (Admin) ───────────────────────────────────────
  Future<Order> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _client.patch(
        Uri.parse('$_baseUrl/api/orders/$orderId/status'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception('Failed to update status');
    } catch (_) {
      return _updateStatusLocally(orderId, newStatus);
    }
  }

  // ── Dashboard Stats ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/api/orders/stats/summary'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch stats');
    } catch (_) {
      return _getLocalStats();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Local fallback helpers
  // ═══════════════════════════════════════════════════════════════════════

  Order _placeOrderLocally({
    required String studentName,
    required String studentEmail,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? userId,
    String orderType = 'dine-in',
    String specialInstructions = '',
  }) {
    final now = DateTime.now();
    final activeCount = _localOrders.where((o) => o.isActive).length;
    final queueWaitMinutes = activeCount == 0 ? 0 : ((activeCount + 1) ~/ 2) * 3;
    final queuePosition = activeCount + 1;
    final queueWaitTime = '$queueWaitMinutes min';

    final prepTimes = items.map((i) {
      final match = RegExp(r'\d+').firstMatch(i['prepTime']?.toString() ?? '');
      return match != null ? int.parse(match.group(0)!) : 8;
    }).toList();
    final maxPrepTime = prepTimes.isNotEmpty
        ? prepTimes.reduce((a, b) => a > b ? a : b)
        : 8;
    final totalEtaMinutes = maxPrepTime + queueWaitMinutes + 3;
    final estimatedPrepTime = '$totalEtaMinutes min';
    final expectedReadyAt = now.add(Duration(minutes: totalEtaMinutes));

    final order = Order(
      id: 'local-${_localIdCounter++}',
      userId: userId,
      studentName: studentName,
      studentEmail: studentEmail,
      items: items
          .map((i) => OrderItem(
                menuItemId: i['menuItemId']?.toString() ?? i['id']?.toString() ?? '',
                name: i['name'] as String? ?? '',
                price: (i['price'] as num?)?.toDouble() ?? 0.0,
                quantity: (i['quantity'] as num?)?.toInt() ?? 1,
                subtotal: ((i['price'] as num?)?.toDouble() ?? 0.0) *
                    ((i['quantity'] as num?)?.toInt() ?? 1),
                prepTime: i['prepTime']?.toString() ?? '$maxPrepTime min',
              ))
          .toList(),
      totalAmount: totalAmount,
      orderType: orderType,
      status: 'pending',
      expectedReadyAt: expectedReadyAt,
      specialInstructions: specialInstructions,
      estimatedPrepTime: estimatedPrepTime,
      queuePosition: queuePosition,
      ordersAhead: activeCount,
      queueWaitTime: queueWaitTime,
      createdAt: now,
      updatedAt: now,
    );
    _localOrders.insert(0, order);
    return order;
  }

  List<Order> _fetchOrdersLocally({String? email, String? status}) {
    var result = List<Order>.from(_localOrders);
    if (email != null) {
      result = result.where((o) => o.studentEmail == email.toLowerCase()).toList();
    }
    if (status != null) {
      result = result.where((o) => o.status == status).toList();
    }
    return result;
  }

  Order _updateStatusLocally(String orderId, String newStatus) {
    final index = _localOrders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');
    final updated = _localOrders[index].copyWith(status: newStatus);
    _localOrders[index] = updated;
    return updated;
  }

  Map<String, dynamic> _getLocalStats() {
    int pending = 0, preparing = 0, ready = 0, collected = 0, cancelled = 0;
    double revenue = 0;
    for (final o in _localOrders) {
      revenue += o.totalAmount;
      switch (o.status) {
        case 'pending':
          pending++;
          break;
        case 'preparing':
          preparing++;
          break;
        case 'ready':
          ready++;
          break;
        case 'collected':
          collected++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }
    return {
      'totalOrders': _localOrders.length,
      'totalRevenue': revenue,
      'pendingCount': pending,
      'preparingCount': preparing,
      'readyCount': ready,
      'collectedCount': collected,
      'cancelledCount': cancelled,
    };
  }
}
