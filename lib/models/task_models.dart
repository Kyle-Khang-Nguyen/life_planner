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
  final bool isCalendarOnly; // 1. HIER DAS FELD DEFINIEREN

  Task({
    required this.title,
    required this.description,
    required this.priority,
    required this.date,
    required this.time,
    this.isDone = false,
    this.isCalendarOnly = false, // 2. HIER IM KONSTRUKTOR HINZUFÜGEN (mit Standardwert false)
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