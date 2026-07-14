import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_models.dart'; // Importiert deine Modelle

// ==========================================
// DIALOG WIDGETS
// ==========================================

class AddTaskDialog extends StatefulWidget {
  final Function(Task) onTaskAdded;
  final Function(DayPlanItem) onDayPlanAdded;

  const AddTaskDialog({super.key, required this.onTaskAdded, required this.onDayPlanAdded});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final timeController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  String targetType = 'Taskbox';
  String selectedPriority = 'Wichtig';
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Aufgabe / Termin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: targetType,
              // NEU: 'Termin' zur Liste der Auswahlmöglichkeiten hinzugefügt
              items: ['Taskbox', 'Tagesplan', 'Termin']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type == 'Termin' ? 'Kalender (Termin)' : type)))
                  .toList(),
              onChanged: (value) => setState(() {
                targetType = value!;
                timeController.clear(); // Leert die Uhrzeit beim Wechseln des Typs
              }),
              decoration: const InputDecoration(labelText: 'Zielort'),
            ),
            
            // Wenn Taskbox ausgewählt ist, zeigen wir die Priorität
            if (targetType == 'Taskbox') ...[
              DropdownButtonFormField<String>(
                initialValue: selectedPriority,
                items: ['Wichtigste', 'Wichtig', 'Später'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (value) => selectedPriority = value!,
                decoration: const InputDecoration(labelText: 'Priorität'),
              ),
            ],

            // NEU: Wenn 'Taskbox' ODER 'Termin' gewählt ist, brauchen wir Datum und Uhrzeit
            if (targetType == 'Taskbox' || targetType == 'Termin') ...[
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Datum', suffixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020), // Erlaubt auch vergangene/aktuelle Termine im Kalender
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                    dateController.text = DateFormat('dd.MM.yyyy').format(picked);
                  }
                },
              ),
              TextField(
                controller: timeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Uhrzeit', suffixIcon: Icon(Icons.access_time)),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (picked != null) {
                    timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
            ],

            // Wenn Tagesplan ausgewählt ist, zeigen wir nur das einfache Uhrzeit-Feld
            if (targetType == 'Tagesplan')
              TextField(
                controller: timeController,
                readOnly: true, 
                decoration: const InputDecoration(
                  labelText: 'Uhrzeit wählen',
                  suffixIcon: Icon(Icons.access_time),
                ),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context, 
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titel')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Beschreibung')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.isNotEmpty && timeController.text.isNotEmpty) {
              // 1. Speichern in der Taskbox
              if (targetType == 'Taskbox' && selectedDate != null) {
                widget.onTaskAdded(Task(
                  title: titleController.text,
                  description: descriptionController.text,
                  priority: selectedPriority,
                  date: selectedDate!,
                  time: timeController.text,
                  isCalendarOnly: false, // KEIN reiner Kalendertermin
                ));
                Navigator.pop(context);
              } 
              // 2. Speichern im Tagesplan
              else if (targetType == 'Tagesplan') {
                widget.onDayPlanAdded(DayPlanItem(
                  time: timeController.text, 
                  title: titleController.text,
                  description: descriptionController.text,
                ));
                Navigator.pop(context);
              }
              // 3. NEU: Speichern als Kalender-Termin
              // Da Termine dieselbe Struktur wie Tasks nutzen und in dieselbe Tabelle ('tasks') wandern,
              // können wir hier direkt 'widget.onTaskAdded' mit einer Standard-Priorität aufrufen!
              else if (targetType == 'Termin' && selectedDate != null) {
                widget.onTaskAdded(Task(
                  title: titleController.text,
                  description: descriptionController.text,
                  priority: 'Wichtig', // Standard-Priorität für reine Kalender-Termine
                  date: selectedDate!,
                  time: timeController.text,
                  isCalendarOnly: true, // JA, das ist ein reiner Kalendertermin!
                ));
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}