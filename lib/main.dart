import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEUER IMPORT
import 'models/task_models.dart';
import 'widgets/priority_box.dart';
import 'widgets/add_task_dialog.dart';
import 'widgets/day_plan_detail_dialog.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // NEUER IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lädt die .env Datei aus den Assets
  await dotenv.load(fileName: ".env");

  // Initialisiert Supabase mit den versteckten Schlüsseln
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '', 
    publishableKey: dotenv.env['SUPABASE_KEY'] ?? '',
  );

  runApp(const LifePlannerApp());
}

// Eine Abkürzung für den späteren Zugriff auf die Datenbank:
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

// ==========================================
// MAIN SCREEN
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Die Listen starten jetzt erstmal LEER, da wir sie gleich aus der Cloud befüllen!
  List<DayPlanItem> _tagesplan = [];
  List<Task> _taskbox = [];
  bool _isLoading = true; // Zeigt einen Ladekreis an, während die Daten aus dem Internet laden

  @override
  void initState() {
    super.initState();
    _loadDataFromCloud(); // Daten beim App-Start aus der Cloud laden
  }

  // ==========================================
  // NEU: DATEN AUS DER CLOUD LADEN
  // ==========================================
  Future<void> _loadDataFromCloud() async {
    try {
      // 1. Tasks laden
      final taskResponse = await supabase.from('tasks').select();
      
      final List<Task> loadedTasks = (taskResponse as List).map((data) {
        return Task(
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          priority: data['priority'] ?? 'Wichtig',
          date: data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
          time: data['time'] ?? '',
          isDone: data['isDone'] ?? false,
        );
      }).toList();

      // 2. Tagesplan laden
      final dayPlanResponse = await supabase.from('day_plan').select();
      
      final List<DayPlanItem> loadedDayPlan = (dayPlanResponse as List).map((data) {
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
      // Das druckt den Fehler und genau die Zeile aus, wo es knallt:
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

  // ==========================================
  // NEU: EVENT HOCHLADEN
  // ==========================================
  void _openAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskAdded: (newTask) async {
          setState(() => _isLoading = true);
          try {
            // Task in die Cloud-Tabelle schießen:
            await supabase.from('tasks').insert({
              'title': newTask.title,
              'description': newTask.description,
              'priority': newTask.priority,
              'date': newTask.date.toIso8601String().split('T')[0], // Nur YYYY-MM-DD
              'time': newTask.time,
              'isDone': newTask.isDone,
            });
            await _loadDataFromCloud(); // Warten, bis Daten geladen sind
          } catch (e) {
            setState(() => _isLoading = false); // Ladekreis bei Fehler abschalten!
          }
        },
        onDayPlanAdded: (newItem) async {
          setState(() => _isLoading = true);
          try {
            // Tagesplan-Item in die Cloud-Tabelle schießen:
            await supabase.from('day_plan').insert({
              'time': newItem.time,
              'title': newItem.title,
              'description': newItem.description,
            });
            await _loadDataFromCloud(); // Warten, bis Daten geladen sind
          } catch (e) {
            setState(() => _isLoading = false); // Ladekreis bei Fehler abschalten!
          }
        },
      ),
    );
  }

  void _editDayPlanItem(int index, String newTime, String newTitle, String newDescription) {
    // Das Updaten in der Cloud machen wir im nächsten Schritt, 
    // um dich jetzt nicht mit zu viel Code auf einmal zu überwältigen!
    setState(() {
      _tagesplan[index] = DayPlanItem(time: newTime, title: newTitle, description: newDescription);
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
              child: Text('Life Planner Menü', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard / Übersicht'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      // Wenn die App lädt, zeigen wir einen Ladekreis an:
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Taskbox', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PriorityBox(
                        color: Colors.green[800]!,
                        priorityName: 'Wichtigste',
                        tasks: _taskbox,
                        onStateChanged: () => setState(() => _sortTasks()),
                      ),
                      PriorityBox(
                        color: Colors.yellow[700]!,
                        priorityName: 'Wichtig',
                        tasks: _taskbox,
                        onStateChanged: () => setState(() => _sortTasks()),
                      ),
                      PriorityBox(
                        color: Colors.red[600]!,
                        priorityName: 'Später',
                        tasks: _taskbox,
                        onStateChanged: () => setState(() => _sortTasks()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text('Tagesplan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tagesplan.length,
                      itemBuilder: (context, index) {
                        final item = _tagesplan[index];
                        return Card(
                          child: ListTile(
                            leading: Text(item.time, style: const TextStyle(fontWeight: FontWeight.bold)),
                            title: Text(item.title),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => DayPlanDetailDialog(
                                  item: item,
                                  onSave: (time, title, desc) {
                                    _editDayPlanItem(index, time, title, desc);
                                  },
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