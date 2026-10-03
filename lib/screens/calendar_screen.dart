import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart';
import 'add_task_sheet.dart';

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onToggleTask;
  final Function(String) onDeleteTask;
  final Function(Task) onSaveTask;

  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onSaveTask,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  List<Task> get _tasksForSelectedDate {
    return widget.tasks.where((task) {
      return task.dueDate.year == _selectedDate.year &&
          task.dueDate.month == _selectedDate.month &&
          task.dueDate.day == _selectedDate.day;
    }).toList();
  }

  void _openAddTaskModal({Task? taskToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AddTaskSheet(
        taskToEdit: taskToEdit,
        onSave: widget.onSaveTask,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Generate 14 days around today
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.add(Duration(days: i - 3)));

    final dayHeader = DateFormat('MMMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('កាលវិភាគ ($dayHeader)',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal Day Selector
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = day.year == _selectedDate.year &&
                    day.month == _selectedDate.month &&
                    day.day == _selectedDate.day;
                final isToday = day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day),
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : (isDark ? Colors.grey.shade900 : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : (isToday
                                ? const Color(0xFF4F46E5).withValues(alpha: 0.5)
                                : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200)),
                        width: isToday && !isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(day).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white70
                                : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ការងារសម្រាប់ ${DateFormat('d MMM').format(_selectedDate)} (${_tasksForSelectedDate.length})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF4F46E5)),
                  onPressed: () => _openAddTaskModal(),
                ),
              ],
            ),
          ),

          Expanded(
            child: _tasksForSelectedDate.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'គ្មានកាលវិភាគសម្រាប់ថ្ងៃនេះទេ',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'អ្នកអាចសម្រាក ឬបន្ថែមការងារថ្មីបាន',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: _tasksForSelectedDate
                        .map(
                          (task) => TaskCard(
                            task: task,
                            onToggle: () => widget.onToggleTask(task),
                            onDelete: () => widget.onDeleteTask(task.id),
                            onEdit: () => _openAddTaskModal(taskToEdit: task),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
