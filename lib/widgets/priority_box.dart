import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_models.dart'; // Importiert deine Modelle
import 'edit_task_dialog.dart';       // Importiert den Edit-Dialog

// ==========================================
// EXTRACTED COMPONENT WIDGETS
// ==========================================

class PriorityBox extends StatelessWidget {
  final Color color;
  final String priorityName;
  final List<Task> tasks;
  final VoidCallback onStateChanged;
  final Function(Task) onTaskDeleted; // NEU: Funktion zum Löschen der Task

  const PriorityBox({
    super.key,
    required this.color,
    required this.priorityName,
    required this.tasks,
    required this.onStateChanged,
    required this.onTaskDeleted, // NEU
  });

  @override
  Widget build(BuildContext context) {
    final filteredTasks = tasks.where((task) => task.priority == priorityName).toList();

    return Container(
      width: 112,
      height: 160,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Text(priorityName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const Divider(color: Colors.white54, height: 6),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final String formattedDate = DateFormat('dd.MM.').format(task.date);

                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(task.title),
                        content: Text(task.description.isEmpty ? 'Keine Beschreibung vorhanden.' : task.description),
                        actions: [
                          // 1. EDIT BUTTON
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => EditTaskDialog(task: task, onTaskUpdated: onStateChanged),
                              );
                            },
                          ),
                          // 2. NEU: DELETE BUTTON MIT BESTÄTIGUNG
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Sicherheits-Dialog öffnen
                              showDialog(
                                context: context,
                                builder: (BuildContext confirmContext) {
                                  return AlertDialog(
                                    title: const Text('Task löschen?'),
                                    content: const Text('Bist du dir sicher, dass du diese Aufgabe unwiderruflich löschen möchtest?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(confirmContext), // Schließt nur die Sicherheitsabfrage
                                        child: const Text('Abbrechen'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(confirmContext); // Schließt Sicherheitsabfrage
                                          Navigator.pop(context);        // Schließt die Detailansicht
                                          onTaskDeleted(task);           // Führt das Löschen aus!
                                        },
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Löschen'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          const Spacer(), // Schiebt das 'OK' ganz nach rechts
                          TextButton(
                            onPressed: () => Navigator.pop(context), 
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: Checkbox(
                                  activeColor: Colors.white,
                                  checkColor: color,
                                  value: task.isDone,
                                  onChanged: (bool? newValue) {
                                    task.isDone = newValue!;
                                    onStateChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 22.0),
                            child: Text(
                              'Bis: $formattedDate ${task.time}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}