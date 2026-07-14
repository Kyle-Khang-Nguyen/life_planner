import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/task_models.dart';
import 'widgets/priority_box.dart';
import 'widgets/add_task_dialog.dart';
import 'widgets/day_plan_detail_dialog.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/calender_screen.dart'; // Importiert die Kalender-Seite

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_KEY'] ?? '',
  );
  runApp(const LifePlannerApp());
}

final supabase = Supabase.instance.client;

class LifePlannerApp extends StatelessWidget {
  const LifePlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Planner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<DayPlanItem> _tagesplan = [];
  List<Task> _taskbox = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataFromCloud();
  }

  Future<void> _loadDataFromCloud() async {
    try {
      final taskResponse = await supabase.from('tasks').select();
      final List<Task> loadedTasks = (taskResponse as List).map((data) {
        return Task(
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          priority: data['priority'] ?? 'Wichtig',
          date: data['date'] != null
              ? DateTime.parse(data['date'])
              : DateTime.now(),
          time: data['time'] ?? '',
          isDone: data['isDone'] ?? false,
          isCalendarOnly:
              data['is_calendar_only'] ??
              false, // NEU: Wert aus der Cloud laden
        );
      }).toList();

      final dayPlanResponse = await supabase.from('day_plan').select();
      final List<DayPlanItem> loadedDayPlan = (dayPlanResponse as List).map((
        data,
      ) {
        return DayPlanItem(
          time: data['time'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
        );
      }).toList();

      setState(() {
        _taskbox = loadedTasks;
        _tagesplan = loadedDayPlan;
        _sortTasks();
        _sortDayPlan();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _sortTasks() {
    _taskbox.sort((a, b) {
      int dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.time.compareTo(b.time);
    });
  }

  void _sortDayPlan() {
    _tagesplan.sort((a, b) => a.time.compareTo(b.time));
  }

  Future<void> _deleteTaskFromCloud(Task taskToDelete) async {
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('tasks')
          .delete()
          .eq('title', taskToDelete.title)
          .eq('time', taskToDelete.time);

      setState(() {
        _taskbox.removeWhere(
          (task) =>
              task.title == taskToDelete.title &&
              task.time == taskToDelete.time,
        );
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aufgabe erfolgreich gelöscht.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $e')));
      }
    }
  }

  // ==========================================
  // NEU: TAGESPLAN-ELEMENT AUS SUPABASE LÖSCHEN
  // ==========================================
  Future<void> _deleteDayPlanItemFromCloud(DayPlanItem itemToDelete) async {
    setState(() => _isLoading = true);
    try {
      // Löscht das Item aus der Tabelle 'day_plan' anhand von Uhrzeit und Titel
      await supabase
          .from('day_plan')
          .delete()
          .eq('time', itemToDelete.time)
          .eq('title', itemToDelete.title);

      setState(() {
        // Lokal aus der Liste entfernen
        _tagesplan.removeWhere(
          (item) =>
              item.time == itemToDelete.time &&
              item.title == itemToDelete.title,
        );
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin erfolgreich gelöscht.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $e')));
      }
    }
  }

  void _openAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskAdded: (newTask) async {
          setState(() => _isLoading = true);
          try {
            await supabase.from('tasks').insert({
              'title': newTask.title,
              'description': newTask.description,
              'priority': newTask.priority,
              'date': newTask.date.toIso8601String().split('T')[0],
              'time': newTask.time,
              'isDone': newTask.isDone,
              'is_calendar_only':
                  newTask.isCalendarOnly, // NEU: Wird in die Cloud geschrieben
            });
            await _loadDataFromCloud();
          } catch (e) {
            setState(() => _isLoading = false);
          }
        },
        onDayPlanAdded: (newItem) async {
          setState(() => _isLoading = true);
          try {
            await supabase.from('day_plan').insert({
              'time': newItem.time,
              'title': newItem.title,
              'description': newItem.description,
            });
            await _loadDataFromCloud();
          } catch (e) {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  void _editDayPlanItem(
    int index,
    String newTime,
    String newTitle,
    String newDescription,
  ) {
    setState(() {
      _tagesplan[index] = DayPlanItem(
        time: newTime,
        title: newTitle,
        description: newDescription,
      );
      _sortDayPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lifeplanner')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Life Planner Menü',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // 1. Der bestehende Eintrag für das Dashboard
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard / Übersicht'),
              onTap: () {
                Navigator.pop(context); // Schließt die Seitenleiste
              },
            ),
            // 2. HIER ZWISCHENGEFÜGT: Der neue Kalender-Eintrag
            // Kalender-Eintrag im Drawer (main.dart)
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Kalender'),
              onTap: () async {
                Navigator.pop(context); // Schließt die Seitenleiste

                // Wir warten (await), bis der Nutzer den Kalender wieder verlässt
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarScreen(
                      tasks: _taskbox,
                      onRefreshData: _loadDataFromCloud,
                    ),
                  ),
                );

                // Wenn der Nutzer vom Kalender zurückkommt, laden wir die Daten auf dem Dashboard neu!
                _loadDataFromCloud();
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Taskbox',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Ersetze die Stelle im build() der main.dart, wo die PriorityBoxen stehen:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PriorityBox(
                        color: Colors.green[800]!,
                        priorityName: 'Wichtigste',
                        // NEU: Nur Tasks übergeben, die KEINE reinen Kalendertermine sind
                        tasks: _taskbox
                            .where((t) => !t.isCalendarOnly)
                            .toList(),
                        onStateChanged: () => setState(() => _sortTasks()),
                        onTaskDeleted: _deleteTaskFromCloud,
                      ),
                      PriorityBox(
                        color: Colors.yellow[700]!,
                        priorityName: 'Wichtig',
                        // NEU: Nur Tasks übergeben, die KEINE reinen Kalendertermine sind
                        tasks: _taskbox
                            .where((t) => !t.isCalendarOnly)
                            .toList(),
                        onStateChanged: () => setState(() => _sortTasks()),
                        onTaskDeleted: _deleteTaskFromCloud,
                      ),
                      PriorityBox(
                        color: Colors.red[600]!,
                        priorityName: 'Später',
                        // NEU: Nur Tasks übergeben, die KEINE reinen Kalendertermine sind
                        tasks: _taskbox
                            .where((t) => !t.isCalendarOnly)
                            .toList(),
                        onStateChanged: () => setState(() => _sortTasks()),
                        onTaskDeleted: _deleteTaskFromCloud,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Tagesplan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tagesplan.length,
                      itemBuilder: (context, index) {
                        final item = _tagesplan[index];
                        return Card(
                          child: ListTile(
                            leading: Text(
                              item.time,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            title: Text(item.title),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => DayPlanDetailDialog(
                                  item: item,
                                  onSave: (time, title, desc) {
                                    _editDayPlanItem(index, time, title, desc);
                                  },
                                  onDelete: () => _deleteDayPlanItemFromCloud(
                                    item,
                                  ), // NEU: Löschfunktion übergeben
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTaskDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
