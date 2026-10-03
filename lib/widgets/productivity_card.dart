import 'package:flutter/material.dart';

class ProductivityCard extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;

  const ProductivityCard({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
  });

  @override
  Widget build(BuildContext context) {
    final double completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    final int percentage = (completionRate * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'វឌ្ឍនភាពថ្ងៃនេះ (Daily Progress)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    percentage >= 100
                        ? 'អស្ចារ្យណាស់! រួចរាល់អស់ហើយ 🎉'
                        : '$percentage% បានបញ្ចប់',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Circular Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: CircularProgressIndicator(
                      value: completionRate,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF34D399), // Mint green
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Task Statistics Counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('សរុប', '$totalTasks', Icons.format_list_bulleted),
              _buildStatItem('រួចរាល់', '$completedTasks', Icons.check_circle_outline),
              _buildStatItem(
                  'នៅសល់', '${totalTasks - completedTasks}', Icons.hourglass_empty),
              if (overdueTasks > 0)
                _buildStatItem(
                    'ហួសកំណត់', '$overdueTasks', Icons.warning_amber_rounded,
                    isWarning: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, IconData icon,
      {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.red.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isWarning ? Colors.redAccent : Colors.white),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
