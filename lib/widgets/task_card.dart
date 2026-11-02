import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/priority_calculator.dart';
import '../models/task_model.dart';

class TaskCardWidget extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final Future<bool> Function() onComplete;
  final Future<bool> Function() onDelete;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final urgency = PriorityCalculator.getUrgencyLevel(
      deadline: task.deadline,
      priorityScore: task.priorityScore,
    );
    final urgencyColor = PriorityCalculator.getUrgencyColor(urgency);
    final urgencyLabel = PriorityCalculator.getUrgencyLabel(urgency);
    final timeRemaining = PriorityCalculator.formatTimeRemaining(task.deadline);

    return Dismissible(
      key: Key(task.id),
      direction: task.isCompleted ? DismissDirection.endToStart : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right: Mark completed
          return await onComplete();
        } else {
          // Swipe Left: Delete with confirmation
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppConstants.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppConstants.borderSubtleColor),
                  ),
                  title: const Text('Hapus Tugas?', style: TextStyle(color: AppConstants.textPrimaryColor)),
                  content: Text(
                    'Yakin ingin menghapus "${task.title}"? Tugas ini tidak dapat dikembalikan.',
                    style: const TextStyle(color: AppConstants.textSecondaryColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal', style: TextStyle(color: AppConstants.textSecondaryColor)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppConstants.successColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.black87, size: 28),
            SizedBox(width: 8),
            Text(
              'Selesai! 🎉',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppConstants.errorColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text(
              'Hapus',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
      child: Card(
        color: AppConstants.cardColor,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: task.isCompleted
                ? AppConstants.borderSubtleColor
                : urgencyColor.withValues(alpha: 0.5),
            width: task.isCompleted ? 1 : 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Course Name + Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        task.courseName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: task.isCompleted ? AppConstants.textSecondaryColor : AppConstants.primaryColor,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.isGroupTask) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.groups_rounded, size: 12, color: AppConstants.primaryColor),
                            SizedBox(width: 3),
                            Text(
                              'Kelompok',
                              style: TextStyle(fontSize: 10, color: AppConstants.textPrimaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? AppConstants.surfaceColor
                            : urgencyColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: task.isCompleted ? AppConstants.borderSubtleColor : urgencyColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        task.isCompleted ? 'Selesai' : urgencyLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: task.isCompleted ? AppConstants.textSecondaryColor : urgencyColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? AppConstants.textSecondaryColor : AppConstants.textPrimaryColor,
                  ),
                ),

                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
                  ),
                ],

                const SizedBox(height: 12),

                // Bottom row: Deadline + Weight + Subtasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: task.isCompleted ? AppConstants.textSecondaryColor : urgencyColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.isCompleted
                              ? DateFormat('d MMM yyyy').format(task.deadline)
                              : timeRemaining,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted ? AppConstants.textSecondaryColor : urgencyColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.inputColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppConstants.borderSubtleColor),
                          ),
                          child: Text(
                            'Bobot ${task.weightPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Subtask Progress bar if subtasks exist
                if (task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.progressPercentage,
                      minHeight: 5,
                      backgroundColor: AppConstants.inputColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.progressPercentage == 1.0
                            ? AppConstants.successColor
                            : AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtask: ${task.completedSubtasks}/${task.totalSubtasks}',
                        style: const TextStyle(fontSize: 10, color: AppConstants.textSecondaryColor),
                      ),
                      Text(
                        '${(task.progressPercentage * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
