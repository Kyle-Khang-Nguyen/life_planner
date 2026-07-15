import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_models.dart';

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
      scrollable: true, // NEU: Macht den gesamten Dialog (inkl. Titel) automatisch scrollbar, wenn die Tastatur hochfährt!
      title: const Text('Neue Aufgabe / Termin'),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Verhindert, dass die Spalte unnötig Platz einnimmt
        children: [
          DropdownButtonFormField<String>(
            initialValue: targetType,
            items: ['Taskbox', 'Tagesplan', 'Termin']
                .map((type) => DropdownMenuItem(
                    value: type, 
                    child: Text(type == 'Termin' ? 'Kalender (Termin)' : type)))
                .toList(),
            onChanged: (value) => setState(() {
              targetType = value!;
              timeController.clear(); 
            }),
            decoration: const InputDecoration(labelText: 'Zielort'),
          ),
          
          if (targetType == 'Taskbox') ...[
            DropdownButtonFormField<String>(
              initialValue: selectedPriority,
              items: ['Wichtigste', 'Wichtig', 'Später']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) => selectedPriority = value!,
              decoration: const InputDecoration(labelText: 'Priorität'),
            ),
          ],

          if (targetType == 'Taskbox' || targetType == 'Termin') ...[
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                  labelText: 'Datum', suffixIcon: Icon(Icons.calendar_today)),
              onTap: () async {
                FocusScope.of(context).unfocus(); // Schließt die Tastatur vor dem Datum-Popup
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
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
              decoration: const InputDecoration(
                  labelText: 'Uhrzeit', suffixIcon: Icon(Icons.access_time)),
              onTap: () async {
                FocusScope.of(context).unfocus(); // Schließt die Tastatur vor dem Uhrzeit-Popup
                TimeOfDay? picked = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now());
                if (picked != null) {
                  timeController.text =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                }
              },
            ),
          ],

          if (targetType == 'Tagesplan')
            TextField(
              controller: timeController,
              readOnly: true, 
              decoration: const InputDecoration(
                labelText: 'Uhrzeit wählen',
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: () async {
                FocusScope.of(context).unfocus(); // Schließt die Tastatur vor dem Uhrzeit-Popup
                TimeOfDay? picked = await showTimePicker(
                  context: context, 
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() {
                    timeController.text =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
          TextField(
            controller: titleController, 
            decoration: const InputDecoration(labelText: 'Titel')
          ),
          TextField(
            controller: descriptionController, 
            decoration: const InputDecoration(labelText: 'Beschreibung')
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Abbrechen')
        ),
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
                  isCalendarOnly: false,
                ));
                Navigator.pop(context);
              } 
              else if (targetType == 'Tagesplan') {
                widget.onDayPlanAdded(DayPlanItem(
                  time: timeController.text, 
                  title: titleController.text,
                  description: descriptionController.text,
                ));
                Navigator.pop(context);
              }
              else if (targetType == 'Termin' && selectedDate != null) {
                widget.onTaskAdded(Task(
                  title: titleController.text,
                  description: descriptionController.text,
                  priority: 'Wichtig',
                  date: selectedDate!,
                  time: timeController.text,
                  isCalendarOnly: true,
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