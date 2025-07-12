import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const PandaToDoApp());

class PandaToDoApp extends StatelessWidget {
  const PandaToDoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'To‑Do',
        home: const WelcomeScreen(),
      );
}

/* ─────────────  WELCOME SCREEN  ───────────── */
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ColorfulBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🐼 Welcome to To‑Do',
                    style: TextStyle(fontSize: 30, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '“Discipline is just choosing between what you want now and what you want most.”',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    ),
                    child: const Text(
                      'Let’s Start',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/* ─────────────  HOME SCREEN  ───────────── */
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final taskCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  DateTime? selectedDate;
  List<Map<String, dynamic>> tasks = [];
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _saveTasks() async {
    final p = await SharedPreferences.getInstance();
    p.setString('tasks', jsonEncode(tasks));
  }

  Future<void> _loadTasks() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('tasks');
    if (s != null) {
      setState(() => tasks = List<Map<String, dynamic>>.from(jsonDecode(s)));
    }
  }

  void _addTask() {
    if (taskCtrl.text.trim().isEmpty) return;
    setState(() {
      tasks.add({
        'title': taskCtrl.text.trim(),
        'done': false,
        'date': selectedDate?.toIso8601String() ?? ''
      });
      taskCtrl.clear();
      selectedDate = null;
      _saveTasks();
    });
  }

  void _toggleTask(int i) {
    setState(() {
      tasks[i]['done'] = !(tasks[i]['done'] ?? false);
      _saveTasks();
    });
  }

  void _clearCompleted() {
    setState(() {
      tasks.removeWhere((t) => t['done'] == true);
      _saveTasks();
    });
  }

  void _setFilter(String f) => setState(() => filter = f);

  List<Map<String, dynamic>> get _filtered {
    var list = tasks;
    if (filter == 'active') list = tasks.where((t) => !(t['done'] ?? false)).toList();
    if (filter == 'completed') list = tasks.where((t) => t['done'] == true).toList();
    if (searchCtrl.text.isNotEmpty) {
      list = list
          .where((t) =>
              (t['title'] ?? '').toLowerCase().contains(searchCtrl.text.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ColorfulBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        ),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Text('📘 To‑Do List',
                          style: TextStyle(fontSize: 28, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _inputRow(),
                  const SizedBox(height: 10),
                  _datePicker(),
                  const SizedBox(height: 10),
                  _searchBox(),
                  const SizedBox(height: 10),
                  _filterRow(),
                  const SizedBox(height: 10),
                  Expanded(child: _taskList()),
                  _footerButtons(),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _inputRow() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: taskCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Add a new task…'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _addTask, child: const Text('Add')),
        ],
      );

  Widget _datePicker() => Row(
        children: [
          const Text('Due Date:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => selectedDate = d);
            },
            child: Text(selectedDate == null
                ? 'Select Date'
                : '${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}'),
          ),
        ],
      );

  Widget _searchBox() => TextField(
        controller: searchCtrl,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.white),
        decoration: _dec('Search…'),
      );

  Widget _filterRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterBtn('All'),
          _filterBtn('Active'),
          _filterBtn('Completed'),
        ],
      );

  Widget _taskList() => ListView.builder(
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final t = _filtered[i];
          final due = (t['date'] != null && t['date'] != '')
              ? '📅 ${DateTime.parse(t['date']).day}-${DateTime.parse(t['date']).month}-${DateTime.parse(t['date']).year}'
              : '';
          return ListTile(
            title: Text(
              (t['title'] ?? 'Untitled Task'),
              style: TextStyle(
                decoration: (t['done'] ?? false) ? TextDecoration.lineThrough : null,
                color: Colors.white,
              ),
            ),
            subtitle: due.isNotEmpty
                ? Text(due, style: const TextStyle(color: Colors.white60))
                : null,
            trailing: Checkbox(
              value: t['done'] ?? false,
              onChanged: (_) => _toggleTask(tasks.indexOf(t)),
            ),
          );
        },
      );

  Widget _footerButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: _clearCompleted, child: const Text('🧹 Clear Completed')),
        ],
      );

  InputDecoration _dec(String h) => InputDecoration(
        hintText: h,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _filterBtn(String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: OutlinedButton(
          onPressed: () => _setFilter(label.toLowerCase()),
          style: OutlinedButton.styleFrom(
              backgroundColor:
                  filter == label.toLowerCase() ? Colors.white12 : Colors.transparent,
              side: BorderSide(
                  color:
                      filter == label.toLowerCase() ? Colors.white : Colors.white38)),
          child: Text(label,
              style: TextStyle(
                  color:
                      filter == label.toLowerCase() ? Colors.white : Colors.white70)),
        ),
      );
}

/* ─────────────  BACKGROUND  ───────────── */
class ColorfulBackground extends StatefulWidget {
  final Widget child;
  const ColorfulBackground({super.key, required this.child});

  @override
  State<ColorfulBackground> createState() => _ColorfulBackgroundState();
}

class _ColorfulBackgroundState extends State<ColorfulBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _anim;
  final colors = const [
    Color(0xFFff9a9e),
    Color(0xFFfad0c4),
    Color(0xFFa18cd1),
    Color(0xFFfbc2eb),
    Color(0xFFf6d365),
    Color(0xFF96e6a1),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))
      ..repeat();
    _anim = _ctrl.drive(
      TweenSequence<Color?>(List.generate(colors.length, (i) {
        final next = colors[(i + 1) % colors.length];
        return TweenSequenceItem(
          tween: ColorTween(begin: colors[i], end: next),
          weight: 1,
        );
      })),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_anim.value ?? Colors.black, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.child,
        ),
      );
}
