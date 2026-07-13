import 'package:flutter/material.dart';
import '../models/task_models.dart';

class DayPlanDetailDialog extends StatefulWidget {
  final DayPlanItem item;
  final Function(String time, String title, String desc) onSave;

  const DayPlanDetailDialog({super.key, required this.item, required this.onSave});

  @override
  State<DayPlanDetailDialog> createState() => _DayPlanDetailDialogState();
}

class _DayPlanDetailDialogState extends State<DayPlanDetailDialog> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descController = TextEditingController(text: widget.item.description);
    _timeController = TextEditingController(text: widget.item.time);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_isEditing ? 'Element bearbeiten' : 'Details'),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: _isEditing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _timeController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Uhrzeit', suffixIcon: Icon(Icons.access_time)),
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(widget.item.time.split(':')[0]),
                          minute: int.parse(widget.item.time.split(':')[1]),
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                  TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titel')),
                  TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Beschreibung')),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Uhrzeit: ${widget.item.time}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Titel: ${widget.item.title}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  const Text('Beschreibung:', style: TextStyle(color: Colors.grey)),
                  Text(widget.item.description.isEmpty ? 'Keine Beschreibung vorhanden.' : widget.item.description),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_isEditing ? 'Abbrechen' : 'Schließen'),
        ),
        if (_isEditing)
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty && _timeController.text.isNotEmpty) {
                widget.onSave(_timeController.text, _titleController.text, _descController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Speichern'),
          ),
      ],
    );
  }
}