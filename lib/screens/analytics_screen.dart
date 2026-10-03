import 'package:flutter/material.dart';
import '../models/task_model.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<Task> tasks;

  const AnalyticsScreen({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;
    final overdueTasks = tasks.where((t) => t.isOverdue).length;

    final double completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    final int score = (completionRate * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('របាយការណ៍ផលិតភាព (Analytics)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Productivity Score Hero Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'ពិន្ទុផលិតភាពរបស់អ្នក (Productivity Score)',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  '$score / 100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  score >= 80
                      ? '🌟 កម្រិតខ្ពស់! អ្នកកំពុងបំពេញការងារបានយ៉ាងល្អ'
                      : (score >= 50
                          ? '👍 ល្អបង្គួរ! នៅសល់ការងារមួយចំនួនទៀតត្រូវបញ្ចប់'
                          : '⚡ ព្យាយាមបន្ថែមទៀត! ចាប់ផ្ដើមពីការងារអាទិភាពខ្ពស់'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Overview KPI Grid
          const Text(
            'សូចនាករសំខាន់ៗ (Overview KPIs)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'ការងារសរុប',
                  '$totalTasks',
                  Icons.assignment_outlined,
                  Colors.blue,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'បានបញ្ចប់',
                  '$completedTasks',
                  Icons.task_alt_rounded,
                  Colors.green,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'កំពុងដំណើរការ',
                  '$pendingTasks',
                  Icons.pending_actions_rounded,
                  Colors.orange,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'ហួសកំណត់',
                  '$overdueTasks',
                  Icons.warning_amber_rounded,
                  Colors.red,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Weekly Progress Visual Bar Chart
          const Text(
            'វឌ្ឍនភាពប្រចាំសប្តាហ៍ (Weekly Activity)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildWeeklyBar('ចន្ទ', 0.6, isDark),
                    _buildWeeklyBar('អង្គារ', 0.8, isDark),
                    _buildWeeklyBar('ពុធ', 0.4, isDark),
                    _buildWeeklyBar('ព្រហ', 0.9, isDark),
                    _buildWeeklyBar('សុក្រ', completionRate, isDark, isToday: true),
                    _buildWeeklyBar('សៅរ៍', 0.3, isDark),
                    _buildWeeklyBar('អាទិត្យ', 0.2, isDark),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'សកម្មភាពបញ្ចប់ការងារធៀបនឹងថ្ងៃនីមួយៗ',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category Breakdown
          const Text(
            'បែងចែកតាមប្រភេទ (Category Breakdown)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...TaskCategory.values.map((cat) {
            final catTasks = tasks.where((t) => t.category == cat).length;
            final catCompleted =
                tasks.where((t) => t.category == cat && t.isCompleted).length;
            final double percent =
                catTasks > 0 ? (catCompleted / catTasks) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(cat.icon, size: 16, color: cat.color),
                        const SizedBox(width: 8),
                        Text(
                          cat.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '$catCompleted / $catTasks ការងារ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: cat.color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBar(String day, double heightRatio, bool isDark,
      {bool isToday = false}) {
    final double barHeight = (heightRatio.clamp(0.1, 1.0) * 80);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 18,
          height: barHeight,
          decoration: BoxDecoration(
            color: isToday
                ? const Color(0xFF4F46E5)
                : (isDark ? Colors.grey.shade700 : const Color(0xFFC7D2FE)),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday
                ? const Color(0xFF4F46E5)
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
