import 'package:flutter/material.dart';

/// Visual tracker for order lifecycle:
/// ✓ Placed → ● Preparing → ○ Ready → ○ Collected
class OrderStatusTracker extends StatelessWidget {
  const OrderStatusTracker({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  static const List<Map<String, dynamic>> stages = [
    {
      'key': 'placed',
      'label': 'Placed',
      'compactLabel': 'Placed',
      'icon': Icons.receipt_long,
      'description': 'Order received by canteen',
    },
    {
      'key': 'preparing',
      'label': 'Preparing',
      'compactLabel': 'In Prep',
      'icon': Icons.soup_kitchen,
      'description': 'Kitchen is cooking your food',
    },
    {
      'key': 'ready',
      'label': 'Ready',
      'compactLabel': 'Ready',
      'icon': Icons.notifications_active,
      'description': 'Ready for pickup at counter',
    },
    {
      'key': 'collected',
      'label': 'Collected',
      'compactLabel': 'Done',
      'icon': Icons.done_all,
      'description': 'Enjoy your meal!',
    },
  ];

  int get currentStageIndex {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return -1;
      case 'awaiting_payment':
      case 'pending':
        return 0; // Placed
      case 'preparing':
        return 1; // Preparing
      case 'ready':
        return 2; // Ready
      case 'collected':
        return 3; // Collected
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status.toLowerCase() == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(
              'Order Cancelled',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = currentStageIndex;

    if (compact) {
      return _buildCompactTracker(context, currentIndex);
    }

    return _buildFullTracker(context, currentIndex);
  }

  Widget _buildCompactTracker(BuildContext context, int activeIndex) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Row(
      children: List.generate(stages.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Line between nodes
          final stageBefore = index ~/ 2;
          final isCompletedLine = stageBefore < activeIndex;
          return Expanded(
            child: Container(
              height: 2.5,
              color: isCompletedLine
                  ? primaryColor
                  : theme.colorScheme.outlineVariant.withAlpha(120),
            ),
          );
        }

        final stageIndex = index ~/ 2;
        final isCompleted = stageIndex < activeIndex;
        final isCurrent = stageIndex == activeIndex;
        final stage = stages[stageIndex];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? primaryColor
                    : (isCurrent ? primaryColor.withAlpha(30) : Colors.transparent),
                border: Border.all(
                  color: (isCompleted || isCurrent)
                      ? primaryColor
                      : theme.colorScheme.outlineVariant,
                  width: isCurrent ? 2.5 : 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : isCurrent
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                            ),
                          )
                        : Text(
                            '○',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.outlineVariant,
                              height: 1,
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (stage['compactLabel'] ?? stage['label']) as String,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent
                    ? primaryColor
                    : (isCompleted
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFullTracker(BuildContext context, int activeIndex) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Progress',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stages[activeIndex.clamp(0, stages.length - 1)]['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stepper row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(stages.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stageBefore = index ~/ 2;
                final isCompletedLine = stageBefore < activeIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: isCompletedLine
                            ? primaryColor
                            : theme.colorScheme.outlineVariant.withAlpha(120),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }

              final stageIndex = index ~/ 2;
              final isCompleted = stageIndex < activeIndex;
              final isCurrent = stageIndex == activeIndex;
              final stage = stages[stageIndex];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? primaryColor
                          : (isCurrent
                              ? primaryColor.withAlpha(35)
                              : theme.colorScheme.surface),
                      border: Border.all(
                        color: (isCompleted || isCurrent)
                            ? primaryColor
                            : theme.colorScheme.outlineVariant,
                        width: isCurrent ? 2.5 : 1.5,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: primaryColor.withAlpha(60),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : isCurrent
                              ? Icon(
                                  stage['icon'] as IconData,
                                  size: 15,
                                  color: primaryColor,
                                )
                              : Text(
                                  '○',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.outlineVariant,
                                    height: 1,
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stage['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? primaryColor
                          : (isCompleted
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              stages[activeIndex.clamp(0, stages.length - 1)]['description'] as String,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
