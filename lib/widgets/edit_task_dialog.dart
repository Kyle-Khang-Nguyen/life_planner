import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_models.dart'; // Importiert deine Modelle

class EditTaskDialog extends StatefulWidget {
  final Task task;
  final VoidCallback onTaskUpdated;

  const EditTaskDialog({super.key, required this.task, required this.onTaskUpdated});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late TextEditingController timeController;
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;
  late String selectedPriority;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    timeController = TextEditingController(text: widget.task.time);
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(text: widget.task.description);
    dateController = TextEditingController(text: DateFormat('dd.MM.yyyy').format(widget.task.date));
    selectedPriority = widget.task.priority;
    selectedDate = widget.task.date;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aufgabe bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedPriority,
              items: ['Wichtigste', 'Wichtig', 'Später'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (value) => setState(() => selectedPriority = value!),
              decoration: const InputDecoration(labelText: 'Priorität'),
            ),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Datum', suffixIcon: Icon(Icons.calendar_today)),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    dateController.text = DateFormat('dd.MM.yyyy').format(picked);
                  });
                }
              },
            ),
            TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Uhrzeit')),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titel')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Beschreibung')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        ElevatedButton(
          onPressed: () {
            widget.task.title = titleController.text;
            widget.task.description = descriptionController.text;
            widget.task.priority = selectedPriority;
            widget.task.date = selectedDate;
            widget.task.time = timeController.text;
            widget.onTaskUpdated();
            Navigator.pop(context);
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}