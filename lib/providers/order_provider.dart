import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

/// Manages order state for both student (my orders) and admin (all orders) views.
class OrderProvider extends ChangeNotifier {
  OrderProvider({OrderService? orderService})
      : _orderService = orderService ?? OrderService();

  final OrderService _orderService;

  List<Order> _orders = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _queueEstimate;
  bool _loading = false;
  String? _error;

  List<Order> get orders => List.unmodifiable(_orders);
  Map<String, dynamic> get stats => Map.unmodifiable(_stats);
  Map<String, dynamic>? get queueEstimate => _queueEstimate;
  bool get loading => _loading;
  String? get error => _error;

  List<Order> get activeOrders =>
      _orders.where((o) => o.isActive).toList();

  List<Order> get completedOrders =>
      _orders.where((o) => !o.isActive).toList();

  List<Order> get awaitingPaymentOrders =>
      _orders.where((o) => o.isAwaitingPayment).toList();

  // ── Kitchen Queue & ETA Estimation ───────────────────────────────────
  Future<Map<String, dynamic>> fetchQueueEstimate({int? itemPrepMinutes}) async {
    try {
      final estimate = await _orderService.fetchQueueEstimate(
        itemPrepMinutes: itemPrepMinutes,
      );
      _queueEstimate = estimate;
      notifyListeners();
      return estimate;
    } catch (_) {
      return _queueEstimate ?? {};
    }
  }

  // ── Place Order ───────────────────────────────────────────────────────
  Future<Order> placeOrder({
    required String studentName,
    required String studentEmail,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? userId,
    String orderType = 'dine-in',
    String paymentMethod = 'online',
    String specialInstructions = '',
  }) async {
    _setLoading(true);
    try {
      final order = await _orderService.placeOrder(
        userId: userId,
        studentName: studentName,
        studentEmail: studentEmail,
        items: items,
        totalAmount: totalAmount,
        orderType: orderType,
        paymentMethod: paymentMethod,
        specialInstructions: specialInstructions,
      );
      _orders.insert(0, order);
      _error = null;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Issue Token at Counter (Staff Action) ───────────────────────────
  Future<Order> issueOrderToken(String orderId) async {
    try {
      final updated = await _orderService.issueOrderToken(orderId);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updated;
      }
      _error = null;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Load Orders ───────────────────────────────────────────────────────
  Future<void> loadOrders({String? email, String? status}) async {
    _setLoading(true);
    try {
      _orders = await _orderService.fetchOrders(email: email, status: status);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Load Student's Own Orders (Day 4) ─────────────────────────────────
  Future<void> loadMyOrders({required String email, String? token, String? status}) async {
    _setLoading(true);
    try {
      _orders = await _orderService.fetchMyOrders(email: email, token: token, status: status);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Update Status (Admin) ─────────────────────────────────────────────
  Future<void> updateStatus(String orderId, String newStatus) async {
    try {
      final updated = await _orderService.updateOrderStatus(orderId, newStatus);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updated;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Load Stats (Admin Dashboard) ──────────────────────────────────────
  Future<void> loadStats() async {
    _setLoading(true);
    try {
      _stats = await _orderService.fetchStats();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Consolidated Dashboard Fetch ────────────────────────────────────
  Future<void> fetchDashboardData({String? status}) async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _orderService.fetchOrders(status: status),
        _orderService.fetchStats(),
      ]);
      _orders = results[0] as List<Order>;
      _stats = results[1] as Map<String, dynamic>;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
