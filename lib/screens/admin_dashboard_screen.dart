import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

/// Staff/Admin Dashboard (Day 5-7 – Person B).
///
/// Features:
///  • Isolated [OrderProvider] (either injected by caller or self-created).
///  • Auto-refresh every 15 seconds.
///  • Full 6-stat grid (Total, Revenue, Pending, Preparing, Ready, Collected).
///  • Status filter chips.
///  • Action buttons with status-flow logic.
///  • Cancel-confirmation dialog.
///  • Order detail bottom-sheet.
///  • Logout button back to Login.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.staffUser});

  /// The authenticated staff / admin user. Null when launched standalone.
  final AuthUser? staffUser;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _statusFilter = 'all';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
    // Auto-refresh every 15 seconds so staff see live order updates.
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchAll(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _fetchAll() {
    if (!mounted) return;
    final provider = context.read<OrderProvider>();
    provider.loadOrders();
    provider.loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final filteredOrders = _statusFilter == 'all'
        ? orderProvider.orders
        : orderProvider.orders
            .where((o) => o.status == _statusFilter)
            .toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staff Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (widget.staffUser != null)
              Text(
                'Welcome, ${widget.staffUser!.name}',
                style:
                    TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
          ],
        ),
        actions: [
          // Manual refresh button
          IconButton(
            icon: orderProvider.loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSurface,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchAll,
          ),
          // Logout → back to Login screen
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async => _fetchAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats Grid ──────────────────────────────────────
              if (orderProvider.stats.isNotEmpty)
                _StatsGrid(stats: orderProvider.stats),
              if (orderProvider.stats.isEmpty && !orderProvider.loading)
                const _StatsGrid(stats: {}),
              const SizedBox(height: 20),

              // ── Error banner ─────────────────────────────────────
              if (orderProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Could not reach server – showing local data.\n${orderProvider.error}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Filter Chips ──────────────────────────────────────
              Text(
                'Filter Orders',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', 'all', null, colorScheme),
                    _filterChip('Pending', 'pending', Colors.orange, colorScheme),
                    _filterChip('Preparing', 'preparing', Colors.blue, colorScheme),
                    _filterChip('Ready', 'ready', Colors.green, colorScheme),
                    _filterChip('Collected', 'collected', Colors.grey, colorScheme),
                    _filterChip('Cancelled', 'cancelled', Colors.red, colorScheme),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Order Count ──────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Orders (${filteredOrders.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (orderProvider.loading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colorScheme.primary),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Empty State ──────────────────────────────────────
              if (filteredOrders.isEmpty && !orderProvider.loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64,
                            color: colorScheme.outline.withAlpha(120)),
                        const SizedBox(height: 12),
                        const Text('No orders found for this filter'),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _statusFilter = 'all'),
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Show all orders'),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Order Cards ──────────────────────────────────────
              ...filteredOrders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AdminOrderCard(
                    order: order,
                    onStatusUpdate: (newStatus) =>
                        context.read<OrderProvider>().updateStatus(
                              order.id,
                              newStatus,
                            ),
                    onTap: () => _showOrderDetail(context, order),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(
      String label, String value, Color? color, ColorScheme colorScheme) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withAlpha(160),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _statusFilter = value),
        selectedColor: color?.withAlpha(40) ?? colorScheme.primaryContainer,
        checkmarkColor: color ?? colorScheme.primary,
      ),
    );
  }

  void _showOrderDetail(BuildContext context, Order order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Stats Grid – 6 stat cards
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
          color: Colors.indigo,
        ),
        _StatCard(
          title: 'Revenue',
          value:
              '\$${(stats['totalRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
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
        _StatCard(
          title: 'Ready',
          value: '${stats['readyCount'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.teal,
        ),
        _StatCard(
          title: 'Collected',
          value: '${stats['collectedCount'] ?? 0}',
          icon: Icons.done_all,
          color: Colors.grey,
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
// Admin Order Card
// ═══════════════════════════════════════════════════════════════════════════

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({
    required this.order,
    required this.onStatusUpdate,
    required this.onTap,
  });

  final Order order;
  final ValueChanged<String> onStatusUpdate;
  final VoidCallback onTap;

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

  List<_StatusAction> _getActions() {
    switch (order.status) {
      case 'pending':
        return const [
          _StatusAction(
              'Start Preparing', 'preparing', Colors.blue, Icons.soup_kitchen),
          _StatusAction('Cancel', 'cancelled', Colors.red, Icons.cancel),
        ];
      case 'preparing':
        return const [
          _StatusAction(
              'Mark Ready', 'ready', Colors.green, Icons.check_circle),
          _StatusAction('Cancel', 'cancelled', Colors.red, Icons.cancel),
        ];
      case 'ready':
        return const [
          _StatusAction(
              'Collected', 'collected', Colors.grey, Icons.done_all),
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
    final shortId =
        order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$shortId',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.studentName,
                          style:
                              TextStyle(fontSize: 13, color: colorScheme.outline),
                        ),
                        Text(
                          order.studentEmail,
                          style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.outline.withAlpha(180)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                      const SizedBox(height: 4),
                      Text(
                        'Tap for details',
                        style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.outline.withAlpha(140)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Items ─────────────────────────────────────────
              ...order.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.quantity}× ${item.name}',
                            style: const TextStyle(fontSize: 13)),
                        Text('\$${item.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 13, color: colorScheme.outline)),
                      ],
                    ),
                  )),
              if (order.items.length > 3)
                Text(
                  '+${order.items.length - 3} more item(s)',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),

              // ── Special Instructions ──────────────────────────
              if (order.specialInstructions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes, size: 16, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.specialInstructions,
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 16),

              // ── Footer: Total + Time ──────────────────────────
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
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.outline),
                    ),
                ],
              ),

              // ── Action Buttons ────────────────────────────────
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: actions
                      .map((action) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: action.status == 'cancelled'
                                  ? OutlinedButton.icon(
                                      onPressed: () => _confirmCancel(
                                          context, action.label, action.status),
                                      icon: Icon(action.icon, size: 16),
                                      label: Text(action.label,
                                          style:
                                              const TextStyle(fontSize: 12)),
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
                                          style:
                                              const TextStyle(fontSize: 12)),
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
      ),
    );
  }

  void _confirmCancel(BuildContext context, String label, String status) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
            'Are you sure you want to cancel this order? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No, keep it'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onStatusUpdate(status);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, cancel'),
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

// ═══════════════════════════════════════════════════════════════════════════
// Order Detail Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.order});
  final Order order;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor();
    final shortId =
        order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: scrollController,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #$shortId',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Student info
            _Section(
              title: 'Student',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row('Name', order.studentName),
                  const SizedBox(height: 4),
                  _Row('Email', order.studentEmail),
                  if (order.createdAt != null) ...[
                    const SizedBox(height: 4),
                    _Row('Placed at',
                        '${order.createdAt!.hour.toString().padLeft(2, '0')}:${order.createdAt!.minute.toString().padLeft(2, '0')} · ${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Items
            _Section(
              title: 'Items (${order.items.length})',
              child: Column(
                children: order.items
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}× ${item.name}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Special instructions
            if (order.specialInstructions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(
                title: 'Special Instructions',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(order.specialInstructions,
                      style: TextStyle(color: Colors.amber.shade900)),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Total
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Prep time
            if (order.estimatedPrepTime.isNotEmpty)
              Center(
                child: Text(
                  'Estimated prep: ${order.estimatedPrepTime}',
                  style: TextStyle(color: colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.outline)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatusAction {
  const _StatusAction(this.label, this.status, this.color, this.icon);
  final String label;
  final String status;
  final Color color;
  final IconData icon;
}
