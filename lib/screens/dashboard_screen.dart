import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../widgets/productivity_card.dart';
import '../widgets/task_card.dart';
import 'add_task_sheet.dart';

enum TaskFilter { all, today, urgent, overdue, completed }

class DashboardScreen extends StatefulWidget {
  final List<Task> tasks;
  final AppUser user;
  final Function(Task) onToggleTask;
  final Function(String) onDeleteTask;
  final Function(Task) onSaveTask;

  const DashboardScreen({
    super.key,
    required this.tasks,
    required this.user,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onSaveTask,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TaskFilter _selectedFilter = TaskFilter.all;
  TaskCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<Task> get _filteredTasks {
    return widget.tasks.where((task) {
      // Search Query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDesc = task.description.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc) return false;
      }

      // Category filter
      if (_selectedCategory != null && task.category != _selectedCategory) {
        return false;
      }

      // Status filter
      switch (_selectedFilter) {
        case TaskFilter.all:
          return true;
        case TaskFilter.today:
          return task.isDueToday;
        case TaskFilter.urgent:
          return task.priority == TaskPriority.high && !task.isCompleted;
        case TaskFilter.overdue:
          return task.isOverdue;
        case TaskFilter.completed:
          return task.isCompleted;
      }
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

    final totalTasks = widget.tasks.length;
    final completedTasks = widget.tasks.where((t) => t.isCompleted).length;
    final overdueTasks = widget.tasks.where((t) => t.isOverdue).length;

    final todayFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'សួស្តី, ${widget.user.name} 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        todayFormatted,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Search Bar (expandable)
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'ស្វែងរកការងារ (Search tasks)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  ),
                ),
              ),

            // Main Scrollable Area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  // Smart Productivity Dashboard Card
                  ProductivityCard(
                    totalTasks: totalTasks,
                    completedTasks: completedTasks,
                    overdueTasks: overdueTasks,
                  ),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        _buildFilterPill(TaskFilter.all, 'ទាំងអស់ (All)'),
                        _buildFilterPill(TaskFilter.today, 'ថ្ងៃនេះ (Today)'),
                        _buildFilterPill(TaskFilter.urgent, 'បន្ទាន់ (Urgent)'),
                        _buildFilterPill(TaskFilter.overdue, 'ហួសកំណត់ (Overdue)'),
                        _buildFilterPill(TaskFilter.completed, 'រួចរាល់ (Done)'),
                      ],
                    ),
                  ),

                  // Category Filters Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedCategory = null),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _selectedCategory == null
                                  ? const Color(0xFF4F46E5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedCategory == null
                                    ? const Color(0xFF4F46E5)
                                    : Colors.grey.shade400,
                              ),
                            ),
                            child: Text(
                              'គ្រប់ផ្នែក',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedCategory == null
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        ...TaskCategory.values.map((cat) {
                          final isSel = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = isSel ? null : cat;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSel ? cat.color : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel ? cat.color : Colors.grey.shade400,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(cat.icon,
                                      size: 13,
                                      color: isSel ? Colors.white : cat.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    cat.displayName.split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSel ? Colors.white : null,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Task List Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'បញ្ជីការងារ (${_filteredTasks.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openAddTaskModal(),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('បង្កើតការងារ'),
                        ),
                      ],
                    ),
                  ),

                  // Task Cards List or Empty State
                  if (_filteredTasks.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredTasks.map(
                      (task) => TaskCard(
                        task: task,
                        onToggle: () => widget.onToggleTask(task),
                        onDelete: () => widget.onDeleteTask(task.id),
                        onEdit: () => _openAddTaskModal(taskToEdit: task),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTaskModal(),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('ការងារថ្មី (Add Task)'),
      ),
    );
  }

  Widget _buildFilterPill(TaskFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF4F46E5),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = filter);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'មិនមានការងារនៅក្នុងបញ្ជីនេះទេ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'ចុចប៊ូតុង "ការងារថ្មី" ខាងក្រោមដើម្បីបន្ថែម',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
