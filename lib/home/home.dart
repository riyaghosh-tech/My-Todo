
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/model.dart';
import '../widget/widget.dart';
import '../notify/notify.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color green = Color(0xFF218C55);
  static const Color darkGreen = Color(0xFF174D32);
  static const Color lightGreen = Color(0xFFE7F4EA);
  static const Color background = Color(0xFFF5FAF6);

  static const String tasksKey = 'tasks';

  final TextEditingController taskController =
      TextEditingController();

  final TextEditingController searchController =
      TextEditingController();

  final List<Task> tasks = [];

  String selectedFilter = 'All';
  String searchQuery = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // LOAD TASKS FROM LOCAL STORAGE
  Future<void> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedTasks = prefs.getString(tasksKey);

      if (savedTasks != null) {
        final List<dynamic> decodedTasks = jsonDecode(savedTasks);

        final loadedTasks = decodedTasks.map((item) {
          return Task.fromMap(
            Map<String, dynamic>.from(item),
          );
        }).toList();

        if (!mounted) return;

        setState(() {
          tasks
            ..clear()
            ..addAll(loadedTasks);
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // SAVE TASKS TO LOCAL STORAGE
  Future<void> saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final encodedTasks = jsonEncode(
        tasks.map((task) => task.toMap()).toList(),
      );

      await prefs.setString(tasksKey, encodedTasks);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  // TASK COUNTS
  int get completedCount =>
      tasks.where((task) => task.isCompleted).length;

  int get pendingCount =>
      tasks.where((task) => !task.isCompleted).length;

  // REAL PROGRESS
  double get progress =>
      tasks.isEmpty ? 0 : completedCount / tasks.length;

  // FILTER AND SEARCH TASKS
  List<Task> get filteredTasks {
    return tasks.where((task) {
      final matchesFilter = selectedFilter == 'All' ||
          (selectedFilter == 'Pending' && !task.isCompleted) ||
          (selectedFilter == 'Completed' && task.isCompleted);

      final matchesSearch = task.title
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  // ADD TASK
  Future<void> addTask() async {
    final String text = taskController.text.trim();

    if (text.isEmpty) return;

    final newTask = Task(
      title: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      tasks.insert(0, newTask);
    });

    taskController.clear();
    FocusScope.of(context).unfocus();

    await saveTasks();

    // Notification failure won't prevent task saving
    try {
      await NotificationService.showNotification(
        title: 'New To-Do Task',
        body: text,
      );
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  // COMPLETE / UNCOMPLETE TASK
  Future<void> toggleTask(int index) async {
    if (index < 0 || index >= tasks.length) return;

    setState(() {
      tasks[index].isCompleted = !tasks[index].isCompleted;
    });

    await saveTasks();
  }

  // DELETE TASK
  Future<void> deleteTask(int index) async {
    if (index < 0 || index >= tasks.length) return;

    final deletedTask = tasks[index].title;

    setState(() {
      tasks.removeAt(index);
    });

    await saveTasks();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$deletedTask" deleted'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkGreen,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ADD TASK DIALOG
  void showAddTaskDialog() {
    taskController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Add New Task',
            style: TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: taskController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (taskController.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext);
                addTask();
              }
            },
            decoration: InputDecoration(
              hintText: 'What do you need to do?',
              filled: true,
              fillColor: lightGreen.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskController.text.trim().isEmpty) return;

                Navigator.pop(dialogContext);
                addTask();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  // STATISTICS CARD
  Widget statCard(String title, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: green, size: 24),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FILTER CHIP
  Widget filterChip(String filter) {
    final bool selected = selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(filter),
        selected: selected,
        onSelected: (_) {
          setState(() => selectedFilter = filter);
        },
        selectedColor: green,
        backgroundColor: Colors.white,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : darkGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // SETTINGS DIALOG
  void showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ToDo Settings'),
        content: const Text(
          'Your tasks are saved locally on this device. '
          'Notifications are used to alert you when a new task is added.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    taskController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // MAIN UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // APP BAR WITH CUSTOM TODO LOGO
      appBar: AppBar(
        backgroundColor: background,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ToDo',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Notifications are enabled for new tasks.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: green,
              ),
            ),
          ),
        ],
      ),

      // BODY
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: green),
            )
          : SafeArea(
              child: Column(
                children: [
                  // WELCOME HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, Riya!',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Keep going, you're doing great!",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 62,
                          width: 62,
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            size: 38,
                            color: green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PROGRESS DASHBOARD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5ED),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 100,
                                width: 100,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      height: 95,
                                      width: 95,
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 10,
                                        backgroundColor:
                                            const Color(0xFFD0E8D8),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                          green,
                                        ),
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).round()}%',
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 18),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Task Progress',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Text(
                                      '$completedCount of ${tasks.length} completed',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      tasks.isEmpty
                                          ? 'No tasks yet'
                                          : '$pendingCount tasks remaining',
                                      style: const TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          const Divider(color: Color(0xFFD5E9DB)),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              statCard(
                                'Total',
                                tasks.length,
                                Icons.format_list_bulleted_rounded,
                              ),
                              Container(
                                height: 55,
                                width: 1,
                                color: const Color(0xFFD5E9DB),
                              ),
                              statCard(
                                'Pending',
                                pendingCount,
                                Icons.access_time_rounded,
                              ),
                              Container(
                                height: 55,
                                width: 1,
                                color: const Color(0xFFD5E9DB),
                              ),
                              statCard(
                                'Completed',
                                completedCount,
                                Icons.check_circle_outline_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SEARCH BAR
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search your tasks...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.blueGrey,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : const Icon(
                                Icons.tune_rounded,
                                color: green,
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 17),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // FILTERS
                  SizedBox(
                    height: 43,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        filterChip('All'),
                        filterChip('Pending'),
                        filterChip('Completed'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // TASK SECTION HEADING
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          "Today's Tasks",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${filteredTasks.length}',
                            style: const TextStyle(
                              color: green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 13),

                  // TASK LIST
                  Expanded(
                    child: filteredTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  size: 58,
                                  color: green.withOpacity(0.4),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No tasks found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Add a task or try another filter.',
                                  style: TextStyle(
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, 100,
                            ),
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];

                              // Get the task's real index in the
                              // original list, even when filtered.
                              final originalIndex = tasks.indexOf(task);

                              return TaskTile(
                                task: task,
                                onChanged: () =>
                                    toggleTask(originalIndex),
                                onDelete: () =>
                                    deleteTask(originalIndex),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

      // ADD TASK BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddTaskDialog,
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: green,
          unselectedItemColor: Colors.blueGrey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 0) {
              setState(() => selectedFilter = 'All');
            } else if (index == 1) {
              setState(() => selectedFilter = 'Completed');
            } else if (index == 2) {
              showSettings();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline_rounded),
              label: 'Completed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}