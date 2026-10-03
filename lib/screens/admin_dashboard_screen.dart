import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

/// Admin dashboard showing order statistics and a list of all orders
/// with the ability to update order statuses.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();
      provider.loadOrders();
      provider.loadStats();
    });
  }

  void _refreshData() {
    final provider = context.read<OrderProvider>();
    provider.loadOrders();
    provider.loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Filter orders based on selected status
    final filteredOrders = _statusFilter == 'all'
        ? orderProvider.orders
        : orderProvider.orders.where((o) => o.status == _statusFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: orderProvider.loading && orderProvider.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats Cards ──────────────────────────────────
                    _StatsGrid(stats: orderProvider.stats),
                    const SizedBox(height: 20),

                    // ── Filter Chips ─────────────────────────────────
                    Text('Filter Orders',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All', 'all', colorScheme),
                          _filterChip('Pending', 'pending', colorScheme),
                          _filterChip('Preparing', 'preparing', colorScheme),
                          _filterChip('Ready', 'ready', colorScheme),
                          _filterChip('Collected', 'collected', colorScheme),
                          _filterChip('Cancelled', 'cancelled', colorScheme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Orders List ──────────────────────────────────
                    Text(
                      'Orders (${filteredOrders.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    if (filteredOrders.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 64,
                                  color: colorScheme.outline.withAlpha(120)),
                              const SizedBox(height: 12),
                              const Text('No orders found'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredOrders.map((order) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AdminOrderCard(
                              order: order,
                              onStatusUpdate: (newStatus) {
                                orderProvider.updateStatus(order.id, newStatus);
                              },
                            ),
                          )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _filterChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _statusFilter = value),
        selectedColor: colorScheme.primaryContainer,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Stats Grid
// ═══════════════════════════════════════════════════════════════════════════

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          title: 'Total Orders',
          value: '${stats['totalOrders'] ?? 0}',
          icon: Icons.receipt_long,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Revenue',
          value: '\$${(stats['totalRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Pending',
          value: '${stats['pendingCount'] ?? 0}',
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Preparing',
          value: '${stats['preparingCount'] ?? 0}',
          icon: Icons.soup_kitchen,
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Admin Order Card with Status Update
// ═══════════════════════════════════════════════════════════════════════════

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({
    required this.order,
    required this.onStatusUpdate,
  });

  final Order order;
  final ValueChanged<String> onStatusUpdate;

  Color _statusColor() {
    switch (order.status) {
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

  /// Returns the next logical status transition(s) for the admin.
  List<_StatusAction> _getActions() {
    switch (order.status) {
      case 'pending':
        return const [
          _StatusAction('Start Preparing', 'preparing', Colors.blue, Icons.soup_kitchen),
          _StatusAction('Cancel', 'cancelled', Colors.red, Icons.cancel),
        ];
      case 'preparing':
        return const [
          _StatusAction('Mark Ready', 'ready', Colors.green, Icons.check_circle),
          _StatusAction('Cancel', 'cancelled', Colors.red, Icons.cancel),
        ];
      case 'ready':
        return const [
          _StatusAction('Mark Collected', 'collected', Colors.grey, Icons.done_all),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor();
    final actions = _getActions();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.studentName,
                        style: TextStyle(fontSize: 13, color: colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Items
            ...order.items.map((item) => Padding(
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

            if (order.specialInstructions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.specialInstructions,
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 16),

            // Footer: Total + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
                if (order.createdAt != null)
                  Text(
                    _formatTime(order.createdAt!),
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
              ],
            ),

            // Action buttons
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: actions
                    .map((action) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: action.status == 'cancelled'
                                ? OutlinedButton.icon(
                                    onPressed: () => _confirmAction(
                                        context, action.label, action.status),
                                    icon: Icon(action.icon, size: 16),
                                    label: Text(action.label,
                                        style: const TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: action.color,
                                      side: BorderSide(color: action.color),
                                    ),
                                  )
                                : FilledButton.icon(
                                    onPressed: () =>
                                        onStatusUpdate(action.status),
                                    icon: Icon(action.icon, size: 16),
                                    label: Text(action.label,
                                        style: const TextStyle(fontSize: 12)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: action.color,
                                    ),
                                  ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmAction(BuildContext context, String label, String status) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label Order?'),
        content: Text('Are you sure you want to ${label.toLowerCase()} this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onStatusUpdate(status);
            },
            child: Text(label, style: const TextStyle(color: Colors.red)),
          ),
        ],
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

class _StatusAction {
  const _StatusAction(this.label, this.status, this.color, this.icon);
  final String label;
  final String status;
  final Color color;
  final IconData icon;
}
