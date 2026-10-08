import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

/// Screen for students to view their past and active orders from MongoDB (Day 4 - Person A).
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({
    super.key,
    required this.studentEmail,
    this.token,
  });

  final String studentEmail;
  final String? token;

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
      _fetchOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    await context.read<OrderProvider>().loadMyOrders(
          email: widget.studentEmail,
          token: widget.token,
        );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final activeOrders = orderProvider.activeOrders;
    final completedOrders = orderProvider.completedOrders;

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
                  Text('Active (${activeOrders.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 18),
                  const SizedBox(width: 6),
                  Text('Past (${completedOrders.length})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: orderProvider.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: orderProvider.loading && orderProvider.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrderList(
                    orders: activeOrders,
                    emptyMessage: 'No active orders right now',
                    emptyIcon: Icons.check_circle_outline,
                    onRefresh: _fetchOrders,
                  ),
                  _OrderList(
                    orders: completedOrders,
                    emptyMessage: 'No past orders yet',
                    emptyIcon: Icons.receipt_long_outlined,
                    onRefresh: _fetchOrders,
                  ),
                ],
              ),
            ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  final List<Order> orders;
  final String emptyMessage;
  final IconData emptyIcon;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  emptyIcon,
                  size: 72,
                  color: Theme.of(context).colorScheme.outline.withAlpha(120),
                ),
                const SizedBox(height: 12),
                Text(emptyMessage, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
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

  void _showOrderDetailSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: order.statusColor),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(color: order.statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'MongoDB ID: ${order.id}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'monospace'),
              ),
              const Divider(height: 24),

              // Token & Payment Badge Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: order.hasToken
                      ? Colors.green.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: order.hasToken
                        ? Colors.green.shade300
                        : Colors.amber.shade400,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      order.hasToken
                          ? Icons.confirmation_number
                          : Icons.point_of_sale,
                      color: order.hasToken
                          ? Colors.green.shade800
                          : Colors.amber.shade900,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.hasToken
                                ? 'Order Token: #${order.tokenNumber}'
                                : 'Token: Pending Cash Payment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: order.hasToken
                                  ? Colors.green.shade900
                                  : Colors.amber.shade900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            order.hasToken
                                ? 'Payment: ${order.isOnlinePayment ? 'Online (Paid)' : 'Cash at Counter (Paid)'}'
                                : 'Pay \$${order.totalAmount.toStringAsFixed(2)} cash at counter to collect token.',
                            style: TextStyle(
                              fontSize: 11,
                              color: order.hasToken
                                  ? Colors.green.shade900
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Dining & ETA Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(order.orderTypeIcon, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      order.formattedOrderType,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(Icons.timer_outlined, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Ready: ${order.formattedReadyTime}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Kitchen Queue Status Card (if active)
              if (order.isActive) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.soup_kitchen_outlined, color: Colors.amber.shade900),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kitchen Queue: Position #${order.queuePosition}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              order.ordersAhead == 0
                                  ? 'No orders ahead in kitchen (immediate prep).'
                                  : '${order.ordersAhead} order(s) ahead in queue • Queue wait: ~${order.queueWaitTime}',
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Items breakdown
              Text(
                'Items (${order.items.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (item.prepTime.isNotEmpty)
                                Text(
                                  'Prep: ${item.prepTime}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),

              if (order.specialInstructions.isNotEmpty) ...[
                const Divider(height: 24),
                Text('Special Instructions:', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                const SizedBox(height: 4),
                Text(order.specialInstructions, style: const TextStyle(fontStyle: FontStyle.italic)),
              ],

              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = order.statusColor;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showOrderDetailSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order ID + Dining Option + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(order.orderTypeIcon, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '#${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.formattedOrderType,
                          style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (order.hasToken) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Token #${order.tokenNumber}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (order.isAwaitingPayment) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Pay at Counter',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (order.isActive && order.queuePosition != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Queue #${order.queuePosition}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withAlpha(100)),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Banner for active orders: Awaiting payment vs In Kitchen Prep
              if (order.isAwaitingPayment) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.point_of_sale, size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pay \$${order.totalAmount.toStringAsFixed(2)} at counter to receive token & send to kitchen.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (order.isActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: Colors.blue.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Estimated Ready: ${order.estimatedPrepTime} (By ${order.formattedReadyTime})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Items preview
              ...order.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.quantity}× ${item.name}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          '\$${item.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13, color: colorScheme.outline),
                        ),
                      ],
                    ),
                  )),
              if (order.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+${order.items.length - 3} more item(s)...',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ),

              const Divider(height: 16),

              // Footer: Total + Relative Date
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
                  Row(
                    children: [
                      Text(
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: colorScheme.outline),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
