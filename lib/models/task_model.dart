import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  TaskPriority priority;

  @HiveField(7)
  String? category;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  DateTime lastModified;

  @HiveField(10)
  int estimatedMinutes;

  @HiveField(11)
  List<String> tags;

  @HiveField(12)
  bool isRecurring;

  @HiveField(13)
  RecurrencePattern? recurrencePattern;

  @HiveField(14)
  String? userId; // For sync with cloud

  @HiveField(15)
  bool needsSync; // Flag for offline changes

  Task({
    String? id,
    required this.title,
    this.description,
    DateTime? createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.category,
    this.completedAt,
    DateTime? lastModified,
    this.estimatedMinutes = 30,
    List<String>? tags,
    this.isRecurring = false,
    this.recurrencePattern,
    this.userId,
    this.needsSync = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now(),
        tags = tags ?? [];

  // Mark task as completed and update streak
  void complete() {
    isCompleted = true;
    completedAt = DateTime.now();
    lastModified = DateTime.now();
    needsSync = true;
    save(); // Hive auto-save
  }

  // Mark task as incomplete
  void markIncomplete() {
    isCompleted = false;
    completedAt = null;
    lastModified = DateTime.now();
    needsSync = true;
    save();
  }

  // Update task details
  void update({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? category,
    int? estimatedMinutes,
    List<String>? tags,
  }) {
    if (title != null) this.title = title;
    if (description != null) this.description = description;
    if (dueDate != null) this.dueDate = dueDate;
    if (priority != null) this.priority = priority;
    if (category != null) this.category = category;
    if (estimatedMinutes != null) this.estimatedMinutes = estimatedMinutes;
    if (tags != null) this.tags = tags;
    
    lastModified = DateTime.now();
    needsSync = true;
    save();
  }

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final due = dueDate!;
    return now.year == due.year && 
           now.month == due.month && 
           now.day == due.day;
  }

  // Convert to JSON for API sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'priority': priority.index,
      'category': category,
      'completedAt': completedAt?.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'estimatedMinutes': estimatedMinutes,
      'tags': tags,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern?.toJson(),
      'userId': userId,
    };
  }

  // Create from JSON (for API sync)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'],
      priority: TaskPriority.values[json['priority']],
      category: json['category'],
      lastModified: DateTime.parse(json['lastModified']),
      estimatedMinutes: json['estimatedMinutes'],
      tags: List<String>.from(json['tags'] ?? []),
      isRecurring: json['isRecurring'] ?? false,
      recurrencePattern: json['recurrencePattern'] != null 
          ? RecurrencePattern.fromJson(json['recurrencePattern']) 
          : null,
      userId: json['userId'],
      needsSync: false, // Synced from server
    )..completedAt = json['completedAt'] != null 
        ? DateTime.parse(json['completedAt']) 
        : null;
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, isCompleted: $isCompleted, priority: $priority)';
  }
}

@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}

@HiveType(typeId: 2)
class RecurrencePattern extends HiveObject {
  @HiveField(0)
  final RecurrenceType type;

  @HiveField(1)
  final int interval; // Every X days/weeks/months

  @HiveField(2)
  final List<int>? daysOfWeek; // For weekly: [1,2,3,4,5] = Mon-Fri

  @HiveField(3)
  final DateTime? endDate;

  @HiveField(4)
  final int? maxOccurrences;

  RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
    this.endDate,
    this.maxOccurrences,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
    };
  }

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      type: RecurrenceType.values[json['type']],
      interval: json['interval'],
      daysOfWeek: json['daysOfWeek'] != null 
          ? List<int>.from(json['daysOfWeek']) 
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
      maxOccurrences: json['maxOccurrences'],
    );
  }
}

@HiveType(typeId: 3)
enum RecurrenceType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
}