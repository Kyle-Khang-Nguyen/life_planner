import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task_models.dart';
import '../widgets/add_task_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/task_detail_dialog.dart';

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final Future<List<Task>> Function() onRefreshData;

  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.onRefreshData,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _isLocalLoading = false;
  bool _isDateSelected = false; 

  late List<Task> _localTasks;

  @override
  void initState() {
    super.initState();
    _localTasks = widget.tasks;
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      setState(() {
        _localTasks = widget.tasks;
      });
    }
  }

  Future<void> _refreshLocalTasks() async {
    final freshTasks = await widget.onRefreshData();
    setState(() {
      _localTasks = freshTasks;
    });
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _localTasks.where((task) {
      return isSameDay(task.date, day) && task.isCalendarOnly;
    }).toList();
  }

  Widget _buildCalendar(double rowHeight) {
    return TableCalendar(
      // locale: 'de_DE', 
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      eventLoader: _getTasksForDay, 
      rowHeight: rowHeight, 
      sixWeekMonthsEnforced: true, // <--- NEU: Verhindert Höhen-Sprünge zwischen den Monaten!
      daysOfWeekHeight: _isDateSelected ? 20.0 : 30.0, 
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerDecoration: const BoxDecoration(
          color: Colors.deepPurple,
          shape: BoxShape.circle,
        ),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDate = selectedDay;
          _focusedDay = focusedDay;
          _isDateSelected = true; 
        });
      },
    );
  }

  void _openAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskAdded: (newTask) async {
          setState(() => _isLocalLoading = true);
          try {
            await Supabase.instance.client.from('tasks').insert({
              'title': newTask.title,
              'description': newTask.description,
              'priority': newTask.priority,
              'date': isSameDay(newTask.date, DateTime.now())
                  ? _selectedDate.toIso8601String().split('T')[0]
                  : newTask.date.toIso8601String().split('T')[0],
              'time': newTask.time,
              'isDone': newTask.isDone,
              'is_calendar_only': true, // Standardmäßig true für reine Kalendertasks
            });

            await _refreshLocalTasks();
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
            await _refreshLocalTasks();
          } catch (_) {}
          if (mounted) setState(() => _isLocalLoading = false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksForSelectedDate = _getTasksForDay(_selectedDate);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Kalender')),
      body: _isLocalLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. DYNAMISCHER KALENDER-BEREICH
                if (!_isDateSelected)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // NEU: Wir ziehen 110 statt 80 Pixel ab. 
                        // Das lässt genug Platz für Header, Wochentage und Paddings.
                        final availableHeight = constraints.maxHeight - 110.0;
                        final dynamicRowHeight = (availableHeight / 6).clamp(52.0, 120.0);

                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          alignment: Alignment.center,
                          child: _buildCalendar(dynamicRowHeight),
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildCalendar(52.0), 
                  ),

                // 2. DETAILS-BEREICH
                if (_isDateSelected) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Termine am ${DateFormat('dd.MM.yyyy').format(_selectedDate)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _isDateSelected = false; 
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: tasksForSelectedDate.isEmpty
                        ? const Center(
                            child: Text(
                              'Keine Aufgaben für diesen Tag.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
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
                                subtitle: Text(
                                  task.time.isNotEmpty
                                      ? 'Uhrzeit: ${task.time}'
                                      : 'Keine Uhrzeit',
                                ),
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
                                          await _refreshLocalTasks();
                                        } catch (e) {
                                          print("Fehler beim Löschen: $e");
                                        }
                                        if (mounted) {
                                          setState(() => _isLocalLoading = false);
                                        }
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
                                                'date': updatedTask.date
                                                    .toIso8601String()
                                                    .split('T')[0],
                                                'time': updatedTask.time,
                                              })
                                              .eq('title', task.title)
                                              .eq('time', task.time);
                                          await _refreshLocalTasks();
                                        } catch (e) {
                                          print("Fehler beim Update: $e");
                                        }
                                        if (mounted) {
                                          setState(() => _isLocalLoading = false);
                                        }
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
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