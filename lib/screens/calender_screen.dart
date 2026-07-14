import 'package:flutter/material.dart';
import '../models/task_models.dart';
import '../widgets/add_task_dialog.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/task_detail_dialog.dart'; // Import für das Detailfenster

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final Future<void> Function() onRefreshData; 

  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.onRefreshData, 
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLocalLoading = false; 

  void _openAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskAdded: (newTask) async {
          setState(() => _isLocalLoading = true);
          try {
            // Speichert den Termin sauber in Supabase ab
            await Supabase.instance.client.from('tasks').insert({
              'title': newTask.title,
              'description': newTask.description,
              'priority': newTask.priority,
              'date': (newTask.date.year == DateTime.now().year &&
                      newTask.date.month == DateTime.now().month &&
                      newTask.date.day == DateTime.now().day)
                  ? _selectedDate.toIso8601String().split('T')[0]
                  : newTask.date.toIso8601String().split('T')[0],
              'time': newTask.time,
              'isDone': newTask.isDone,
              'is_calendar_only': newTask.isCalendarOnly, 
            });

            await widget.onRefreshData();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fehler beim Speichern: $e')),
              );
            }
          }
          if (mounted) setState(() => _isLocalLoading = false);
        },
        onDayPlanAdded: (newItem) async {
          setState(() => _isLocalLoading = true);
          try {
            await Supabase.instance.client.from('day_plan').insert({
              'time': newItem.time,
              'title': newItem.title,
              'description': newItem.description,
            });
            await widget.onRefreshData();
          } catch (_) {}
          if (mounted) setState(() => _isLocalLoading = false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksForSelectedDate = widget.tasks.where((task) {
      return task.date.year == _selectedDate.year &&
          task.date.month == _selectedDate.month &&
          task.date.day == _selectedDate.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: _isLocalLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (DateTime date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aufgaben am ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}:',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                // ==========================================
                // HIER IST DER LISTVIEW.BUILDER (AKTUALISIERT)
                // ==========================================
                Expanded(
                  child: tasksForSelectedDate.isEmpty
                      ? const Center(child: Text('Keine Aufgaben für diesen Tag.'))
                      : ListView.builder(
                          itemCount: tasksForSelectedDate.length,
                          itemBuilder: (context, index) {
                            final task = tasksForSelectedDate[index];
                            return ListTile(
                              leading: Icon(
                                Icons.circle,
                                color: task.priority == 'Wichtigste'
                                    ? Colors.green[800]
                                    : task.priority == 'Wichtig'
                                        ? Colors.yellow[700]
                                        : Colors.red[600],
                              ),
                              title: Text(task.title),
                              subtitle: Text(task.time.isNotEmpty ? 'Uhrzeit: ${task.time}' : 'Keine Uhrzeit'),
                              
                              // Öffnet beim Tippen das Detail- und Bearbeitungsfenster
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => TaskDetailDialog(
                                    task: task,
                                    onDelete: () async {
                                      setState(() => _isLocalLoading = true);
                                      try {
                                        await Supabase.instance.client
                                            .from('tasks')
                                            .delete()
                                            .eq('title', task.title)
                                            .eq('time', task.time);
                                        await widget.onRefreshData();
                                      } catch (e) {
                                        print("Fehler beim Löschen: $e");
                                      }
                                      if (mounted) setState(() => _isLocalLoading = false);
                                    },
                                    onSave: (updatedTask) async {
                                      setState(() => _isLocalLoading = true);
                                      try {
                                        await Supabase.instance.client
                                            .from('tasks')
                                            .update({
                                              'title': updatedTask.title,
                                              'description': updatedTask.description,
                                              'priority': updatedTask.priority,
                                              'date': updatedTask.date.toIso8601String().split('T')[0],
                                              'time': updatedTask.time,
                                            })
                                            .eq('title', task.title)
                                            .eq('time', task.time);
                                        await widget.onRefreshData();
                                      } catch (e) {
                                        print("Fehler beim Update: $e");
                                      }
                                      if (mounted) setState(() => _isLocalLoading = false);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTaskDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}