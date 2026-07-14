import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_models.dart';

class TaskDetailDialog extends StatefulWidget {
  final Task task;
  final Function(Task) onSave;
  final VoidCallback onDelete;

  const TaskDetailDialog({
    super.key,
    required this.task,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _timeController;
  late DateTime _selectedDate;
  late String _selectedPriority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _timeController = TextEditingController(text: widget.task.time);
    _selectedDate = widget.task.date;
    _selectedPriority = widget.task.priority;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_isEditing ? 'Bearbeiten' : 'Details'),
          if (!_isEditing)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _confirmDelete(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => setState(() => _isEditing = true),
                ),
              ],
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: _isEditing ? _buildEditForm() : _buildViewDetails(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_isEditing ? 'Abbrechen' : 'Schließen'),
        ),
        if (_isEditing)
          ElevatedButton(
            onPressed: () {
              final updatedTask = Task(
                title: _titleController.text,
                description: _descController.text,
                priority: _selectedPriority,
                date: _selectedDate,
                time: _timeController.text,
                isDone: widget.task.isDone,
                isCalendarOnly: widget.task.isCalendarOnly,
              );
              widget.onSave(updatedTask);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
      ],
    );
  }

  Widget _buildViewDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Titel: ${widget.task.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('Datum: ${DateFormat('dd.MM.yyyy').format(widget.task.date)}'),
        Text('Uhrzeit: ${widget.task.time}'),
        Text('Priorität: ${widget.task.priority}'),
        const SizedBox(height: 10),
        const Text('Beschreibung:', style: TextStyle(color: Colors.grey)),
        Text(widget.task.description.isEmpty ? 'Keine Beschreibung.' : widget.task.description),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titel')),
        TextField(
          readOnly: true,
          decoration: const InputDecoration(labelText: 'Datum', suffixIcon: Icon(Icons.calendar_today)),
          controller: TextEditingController(text: DateFormat('dd.MM.yyyy').format(_selectedDate)),
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
        TextField(
          controller: _timeController,
          readOnly: true,
          decoration: const InputDecoration(labelText: 'Uhrzeit', suffixIcon: Icon(Icons.access_time)),
          onTap: () async {
            TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (picked != null) {
              setState(() => _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
            }
          },
        ),
        if (!widget.task.isCalendarOnly)
          DropdownButtonFormField<String>(
            value: _selectedPriority,
            items: ['Wichtigste', 'Wichtig', 'Später'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) => setState(() => _selectedPriority = val!),
            decoration: const InputDecoration(labelText: 'Priorität'),
          ),
        TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Beschreibung')),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Löschen?'),
        content: const Text('Möchtest du diesen Eintrag wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Dialog schließen
              Navigator.pop(context); // Detailfenster schließen
              widget.onDelete();
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}