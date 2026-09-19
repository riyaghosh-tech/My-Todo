
import 'package:flutter/material.dart';
import '../model/model.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF218C55);
    const darkGreen = Color(0xFF174D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.isCompleted
              ? const Color(0xFFD4EBDD)
              : const Color(0xFFEDF3EF),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Completion checkbox
          Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onChanged(),
            activeColor: green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          const SizedBox(width: 5),

          // Task title and creation date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: task.isCompleted
                        ? Colors.grey
                        : darkGreen,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Created: ${_formatDate(task.createdAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Task status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? const Color(0xFFE2F3E8)
                  : const Color(0xFFF0F4F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.isCompleted ? 'Done' : 'Pending',
              style: TextStyle(
                color: task.isCompleted ? green : Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Delete button
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFE57373),
              size: 21,
            ),
            tooltip: 'Delete task',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} • $hour:$minute $period';
  }
}