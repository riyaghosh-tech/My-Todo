import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/model.dart';
import '../widget/widget.dart';
import '../notify/notify.dart';
import '../screens/map_picker.dart';

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

  final taskController = TextEditingController();
  final searchController = TextEditingController();
  final List<Task> tasks = [];

  String selectedFilter = 'All';
  String searchQuery = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(tasksKey);

      if (saved != null) {
        final decoded = jsonDecode(saved) as List;

        tasks
          ..clear()
          ..addAll(
            decoded.map(
              (item) => Task.fromMap(
                Map<String, dynamic>.from(item),
              ),
            ),
          );
      }

      // Restore pending reminders after loading saved tasks.
      for (final task in tasks) {
        if (!task.isCompleted && task.dueDateTime != null) {
          if (task.dueDateTime!.isAfter(DateTime.now())) {
            await NotificationService.scheduleReminder(
              id: task.notificationId,
              title: 'Task Reminder',
              body: task.title,
              scheduledDate: task.dueDateTime!,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      tasksKey,
      jsonEncode(tasks.map((task) => task.toMap()).toList()),
    );
  }

  int get completedCount =>
      tasks.where((task) => task.isCompleted).length;

  int get pendingCount =>
      tasks.where((task) => !task.isCompleted).length;

  double get progress =>
      tasks.isEmpty ? 0 : completedCount / tasks.length;

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

  Future<String?> pickLocation() async {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(),
      ),
    );
  }

  Future<DateTime?> pickReminderDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        now.add(const Duration(hours: 1)),
      ),
    );

    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> addTask({
    required String? location,
    required DateTime? reminder,
  }) async {
    final text = taskController.text.trim();

    if (text.isEmpty) return;

    final now = DateTime.now();

    final id = now.microsecondsSinceEpoch.toString();
    final notificationId = now.millisecondsSinceEpoch ~/ 1000;

    final newTask = Task(
      id: id,
      title: text,
      createdAt: now,
      location: location,
      dueDateTime: reminder,
      notificationId: notificationId,
    );

    setState(() {
      tasks.insert(0, newTask);
    });

    taskController.clear();

    await saveTasks();

    try {
      await NotificationService.showNotification(
        title: 'New To-Do Task',
        body: text,
      );

      if (reminder != null && reminder.isAfter(DateTime.now())) {
        await NotificationService.scheduleReminder(
          id: notificationId,
          title: 'Task Reminder',
          body: text,
          scheduledDate: reminder,
        );
      }
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  Future<void> toggleTask(int index) async {
    if (index < 0 || index >= tasks.length) return;

    final task = tasks[index];

    setState(() {
      task.isCompleted = !task.isCompleted;
    });

    if (task.isCompleted) {
      await NotificationService.cancelReminder(task.notificationId);
    } else if (task.dueDateTime != null &&
        task.dueDateTime!.isAfter(DateTime.now())) {
      await NotificationService.scheduleReminder(
        id: task.notificationId,
        title: 'Task Reminder',
        body: task.title,
        scheduledDate: task.dueDateTime!,
      );
    }

    await saveTasks();
  }

  Future<void> deleteTask(int index) async {
    if (index < 0 || index >= tasks.length) return;

    final task = tasks[index];

    setState(() {
      tasks.removeAt(index);
    });

    await NotificationService.cancelReminder(task.notificationId);
    await saveTasks();
  }

  void showAddTaskDialog() {
    taskController.clear();

    String? selectedLocation;
    DateTime? selectedReminder;
    String reminderMode = 'none';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Add New Task',
                style: TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: taskController,
                      autofocus: true,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'What do you need to do?',
                        filled: true,
                        fillColor: lightGreen.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // LOCATION
                    const Text(
                      'Task Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await pickLocation();

                        if (result != null) {
                          dialogSetState(() {
                            selectedLocation = result;
                          });
                        }
                      },
                      icon: const Icon(Icons.location_on),
                      label: Text(
                        selectedLocation == null
                            ? 'Choose Location on Map'
                            : 'Change Location',
                      ),
                    ),

                    if (selectedLocation != null)
                      Text(
                        selectedLocation!,
                        style: const TextStyle(fontSize: 12),
                      ),

                    const SizedBox(height: 18),

                    // REMINDER OPTIONS
                    const Text(
                      'Task Reminder',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    RadioGroup<String>(
                      groupValue: reminderMode,
                      onChanged: (value) async {
                        if (value == null) return;
                        if (value == 'custom') {
                          final result = await pickReminderDateTime();
                          if (result != null) {
                            dialogSetState(() {
                              reminderMode = 'custom';
                              selectedReminder = result;
                            });
                          }
                        } else {
                          dialogSetState(() {
                            reminderMode = value;
                            if (value == 'none') {
                              selectedReminder = null;
                            } else if (value == 'oneHour') {
                              selectedReminder = DateTime.now().add(
                                const Duration(hours: 1),
                              );
                            }
                          });
                        }
                      },
                      child: const Column(
                        children: [
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('No Reminder'),
                            value: 'none',
                          ),
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('1 Hour After Creating Task'),
                            value: 'oneHour',
                          ),
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Choose Date & Time'),
                            value: 'custom',
                          ),
                        ],
                      ),
                    ),

                    if (selectedReminder != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Reminder: '
                          '${selectedReminder!.day}/'
                          '${selectedReminder!.month}/'
                          '${selectedReminder!.year} '
                          '${TimeOfDay.fromDateTime(selectedReminder!).format(context)}',
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (taskController.text.trim().isEmpty) {
                      return;
                    }

                    if (reminderMode == 'custom' &&
                        selectedReminder == null) {
                      return;
                    }

                    if (selectedReminder != null &&
                        !selectedReminder!.isAfter(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please choose a future reminder time.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    addTask(
                      location: selectedLocation,
                      reminder: selectedReminder,
                    );
                  },
                  child: const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget statCard(String title, int count, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: green),
          const SizedBox(height: 5),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget filterChip(String filter) {
    final selected = selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(filter),
        selected: selected,
        selectedColor: green,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : darkGreen,
        ),
        onSelected: (_) {
          setState(() => selectedFilter = filter);
        },
      ),
    );
  }

  void showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ToDo Settings'),
        content: const Text(
          'Tasks are stored locally on this device. '
          'Location and reminder details are saved with each task. '
          'Notifications depend on device permission and battery settings.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'ToDo',
          style: TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Your task reminders are managed locally.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
              color: green,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: green),
            )
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5ED),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 85,
                                width: 85,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      height: 80,
                                      width: 80,
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 8,
                                        backgroundColor:
                                            const Color(0xFFD0E8D8),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                          green,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).round()}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Task Progress',
                                      style: TextStyle(
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$completedCount of ${tasks.length} completed',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: darkGreen,
                                      ),
                                    ),
                                    Text('$pendingCount tasks remaining'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          Row(
                            children: [
                              statCard(
                                'Total',
                                tasks.length,
                                Icons.list_alt,
                              ),
                              statCard(
                                'Pending',
                                pendingCount,
                                Icons.access_time,
                              ),
                              statCard(
                                'Completed',
                                completedCount,
                                Icons.check_circle_outline,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SEARCH
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search your tasks...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => searchQuery = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // FILTERS
                  SizedBox(
                    height: 42,
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

                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Today's Tasks",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                    ),
                  ),

                  // TASK LIST
                  Expanded(
                    child: filteredTasks.isEmpty
                        ? const Center(
                            child: Text(
                              'No tasks found. Add a task!',
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, 100,
                            ),
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddTaskDialog,
        backgroundColor: green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: green,
        unselectedItemColor: Colors.blueGrey,
        onTap: (index) {
          if (index == 0) {
            setState(() => selectedFilter = 'All');
          } else if (index == 1) {
            setState(() => selectedFilter = 'Completed');
          } else {
            showSettings();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Completed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}