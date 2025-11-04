import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streaky_app/models/task_model.dart';
import 'package:streaky_app/providers/task_provider.dart';

/// Animated task card widget with swipe actions and priority indicators
class TaskCard extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showDueDate;
  final bool showCategory;
  final bool isCompact;

  const TaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showDueDate = true,
    this.showCategory = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _checkController;
  late AnimationController _bounceController;
  
  late Animation<double> _slideAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _bounceAnimation;

  bool _isExpanded = false;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Start entrance animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
    });

    // Initialize check animation state
    if (widget.task.isCompleted) {
      _checkController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _checkController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  IconData _getPriorityIcon() {
    switch (widget.task.priority) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.arrow_upward;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  String _getTimeRemaining() {
    if (widget.task.dueDate == null) return '';
    
    final now = DateTime.now();
    final due = widget.task.dueDate!;
    final difference = due.difference(now);

    if (difference.isNegative) {
      final overdue = now.difference(due);
      if (overdue.inDays > 0) {
        return '${overdue.inDays}d overdue';
      } else if (overdue.inHours > 0) {
        return '${overdue.inHours}h overdue';
      } else {
        return '${overdue.inMinutes}m overdue';
      }
    } else {
      if (difference.inDays > 0) {
        return '${difference.inDays}d left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h left';
      } else {
        return '${difference.inMinutes}m left';
      }
    }
  }

  Future<void> _toggleComplete() async {
    await _bounceController.forward();
    await _bounceController.reverse();

    if (widget.task.isCompleted) {
      await _checkController.reverse();
      await ref.read(taskProvider.notifier).markTaskIncomplete(widget.task.id);
    } else {
      await _checkController.forward();
      await ref.read(taskProvider.notifier).completeTask(widget.task.id);
    }
  }

  void _showActionsPanel() {
    setState(() {
      _showActions = true;
    });
  }

  void _hideActionsPanel() {
    setState(() {
      _showActions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(DateTime.now()) &&
        !widget.task.isCompleted;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (1 - _slideAnimation.value) * 300,
            0,
          ),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.isCompact ? 4 : 8,
          ),
          child: Dismissible(
            key: Key('task_${widget.task.id}'),
            direction: DismissDirection.horizontal,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
            ),
            secondaryBackground: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                await _toggleComplete();
                return false;
              } else if (direction == DismissDirection.endToStart) {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text('Are you sure you want to delete this task?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ?? false;
              }
              return false;
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                ref.read(taskProvider.notifier).deleteTask(widget.task.id);
                widget.onDelete?.call();
              }
            },
            child: GestureDetector(
              onTap: widget.onTap,
              onLongPress: _showActionsPanel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: widget.task.isCompleted 
                      ? theme.colorScheme.surfaceVariant.withOpacity(0.7)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOverdue 
                        ? Colors.red.withOpacity(0.5)
                        : theme.colorScheme.outline.withOpacity(0.2),
                    width: isOverdue ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Priority indicator
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Completion checkbox
                              GestureDetector(
                                onTap: _toggleComplete,
                                child: AnimatedBuilder(
                                  animation: _checkAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: widget.task.isCompleted
                                              ? _getPriorityColor()
                                              : theme.colorScheme.outline,
                                          width: 2,
                                        ),
                                        color: widget.task.isCompleted
                                            ? _getPriorityColor()
                                            : Colors.transparent,
                                      ),
                                      child: widget.task.isCompleted
                                          ? Transform.scale(
                                              scale: _checkAnimation.value,
                                              child: const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Task title and details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.task.title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        decoration: widget.task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: widget.task.isCompleted
                                            ? theme.colorScheme.onSurface.withOpacity(0.6)
                                            : null,
                                      ),
                                      maxLines: widget.isCompact ? 1 : 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    
                                    if (widget.task.description != null && !widget.isCompact)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          widget.task.description!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Priority and actions
                              Column(
                                children: [
                                  Icon(
                                    _getPriorityIcon(),
                                    color: _getPriorityColor(),
                                    size: 20,
                                  ),
                                  
                                  if (!widget.isCompact && widget.task.estimatedMinutes > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${widget.task.estimatedMinutes}m',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Additional info row
                          if (!widget.isCompact && (widget.showDueDate || widget.showCategory))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  // Category
                                  if (widget.showCategory && widget.task.category != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.task.category!,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  
                                  if (widget.showCategory && 
                                      widget.task.category != null && 
                                      widget.showDueDate && 
                                      widget.task.dueDate != null)
                                    const SizedBox(width: 8),
                                  
                                  // Due date
                                  if (widget.showDueDate && widget.task.dueDate != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOverdue 
                                            ? Colors.red.withOpacity(0.1)
                                            : theme.colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 12,
                                            color: isOverdue 
                                                ? Colors.red
                                                : theme.colorScheme.onSecondaryContainer,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getTimeRemaining(),
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: isOverdue 
                                                  ? Colors.red
                                                  : theme.colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  const Spacer(),
                                  
                                  // Recurring indicator
                                  if (widget.task.isRecurring)
                                    Icon(
                                      Icons.repeat,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          
                          // Tags
                          if (!widget.isCompact && widget.task.tags != null && widget.task.tags!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 4,
                                children: widget.task.tags!.map((tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                )).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Actions overlay
                    if (_showActions)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _hideActionsPanel,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _hideActionsPanel();
                                    widget.onEdit?.call();
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _toggleComplete,
                                  icon: Icon(
                                    widget.task.isCompleted ? Icons.undo : Icons.check,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _hideActionsPanel();
                                    widget.onDelete?.call();
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}