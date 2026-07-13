// ==========================================
// DATA MODELS
// ==========================================
class Task {
  String title;
  String description;
  String priority;
  DateTime date;
  String time;
  bool isDone;

  Task({
    required this.title,
    required this.description,
    required this.priority,
    required this.date,
    required this.time,
    this.isDone = false,
  });
}

class DayPlanItem {
  final String time;
  final String title;
  final String description; // Neu hinzugefügt

  DayPlanItem({
    required this.time, 
    required this.title, 
    this.description = '', // Standardmäßig leer
  });
}