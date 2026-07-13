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
      title: const Text('Neue Aufgabe'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: targetType,
              items: ['Taskbox', 'Tagesplan'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() {
                targetType = value!;
                timeController.clear(); // Leert die Uhrzeit beim Wechseln des Typs
              }),
              decoration: const InputDecoration(labelText: 'Zielort'),
            ),
            if (targetType == 'Taskbox') ...[
              DropdownButtonFormField<String>(
                initialValue: selectedPriority,
                items: ['Wichtigste', 'Wichtig', 'Später'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (value) => selectedPriority = value!,
                decoration: const InputDecoration(labelText: 'Priorität'),
              ),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Frist: Datum', suffixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
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
                decoration: const InputDecoration(labelText: 'Frist: Uhrzeit', suffixIcon: Icon(Icons.access_time)),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (picked != null) {
                    timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
            ],
            if (targetType == 'Tagesplan')
              TextField(
                controller: timeController,
                readOnly: true, // Verhindert freies Tippen
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
              if (targetType == 'Taskbox' && selectedDate != null) {
                widget.onTaskAdded(Task(
                  title: titleController.text,
                  description: descriptionController.text,
                  priority: selectedPriority,
                  date: selectedDate!,
                  time: timeController.text,
                ));
                Navigator.pop(context);
              } else if (targetType == 'Tagesplan') {
                widget.onDayPlanAdded(DayPlanItem(
                  time: timeController.text, 
                  title: titleController.text,
                  description: descriptionController.text,
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