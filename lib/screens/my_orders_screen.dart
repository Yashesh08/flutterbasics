import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

/// Screen for students to view their order history grouped by active/completed.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({
    super.key,
    required this.studentEmail,
  });

  final String studentEmail;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders(email: widget.studentEmail);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions, size: 18),
                  const SizedBox(width: 6),
                  Text('Active (${orderProvider.activeOrders.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 18),
                  const SizedBox(width: 6),
                  Text('Past (${orderProvider.completedOrders.length})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: () =>
                orderProvider.loadOrders(email: widget.studentEmail),
          ),
        ],
      ),
      body: orderProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _OrderList(
                  orders: orderProvider.activeOrders,
                  emptyMessage: 'No active orders',
                  emptyIcon: Icons.check_circle_outline,
                ),
                _OrderList(
                  orders: orderProvider.completedOrders,
                  emptyMessage: 'No past orders yet',
                  emptyIcon: Icons.receipt_long_outlined,
                ),
              ],
            ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  final List<Order> orders;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 72,
                color: Theme.of(context).colorScheme.outline.withAlpha(120)),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  IconData _statusIcon() {
    switch (order.status) {
      case 'pending':
        return Icons.schedule;
      case 'preparing':
        return Icons.soup_kitchen;
      case 'ready':
        return Icons.check_circle;
      case 'collected':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = order.statusColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(), size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        order.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Items preview
            ...order.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}× ${item.name}',
                          style: const TextStyle(fontSize: 13)),
                      Text('\$${item.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13, color: colorScheme.outline)),
                    ],
                  ),
                )),
            if (order.items.length > 3)
              Text(
                '+${order.items.length - 3} more item(s)',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),

            const Divider(height: 16),

            // Footer: Total + Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.createdAt != null)
                  Text(
                    _formatTime(order.createdAt!),
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
