import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

enum TaskCategory {
  work,
  study,
  family,
  personal,
  health,
}

extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.work:
        return 'ការងារ (Work)';
      case TaskCategory.study:
        return 'ការសិក្សា (Study)';
      case TaskCategory.family:
        return 'គ្រួសារ (Family)';
      case TaskCategory.personal:
        return 'ផ្ទាល់ខ្លួន (Personal)';
      case TaskCategory.health:
        return 'សុខភាព (Health)';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.work:
        return Icons.business_center_rounded;
      case TaskCategory.study:
        return Icons.menu_book_rounded;
      case TaskCategory.family:
        return Icons.family_restroom_rounded;
      case TaskCategory.personal:
        return Icons.person_rounded;
      case TaskCategory.health:
        return Icons.favorite_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.work:
        return const Color(0xFF2563EB); // Royal Blue
      case TaskCategory.study:
        return const Color(0xFF7C3AED); // Purple
      case TaskCategory.family:
        return const Color(0xFF059669); // Emerald
      case TaskCategory.personal:
        return const Color(0xFFD97706); // Amber
      case TaskCategory.health:
        return const Color(0xFFE11D48); // Rose
    }
  }
}

class Task {
  final String id;
  String title;
  String description;
  TaskCategory category;
  TaskPriority priority;
  DateTime dueDate;
  bool isCompleted;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    required this.priority,
    required this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    return dueDate.isBefore(now);
  }

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      category: TaskCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TaskCategory.work,
      ),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: DateTime.parse(json['dueDate'] as String),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Task copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
