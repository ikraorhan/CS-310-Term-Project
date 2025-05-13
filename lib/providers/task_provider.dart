import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tick_task/models/task.dart';
import 'dart:async';

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _tasksSubscription;

  // Getters
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filter tasks by completion status
  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();
  List<Task> get incompleteTasks =>
      _tasks.where((task) => !task.isCompleted).toList();

  TaskProvider() {
    _initializeTaskListener();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  // Real-time listener implementation for tasks
  void _initializeTaskListener() {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "No user logged in";
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Cancel any existing subscriptions
    _tasksSubscription?.cancel();

    // Set up real-time listener for tasks collection
    _tasksSubscription = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: false)
        .snapshots() // This creates a real-time stream of document snapshots
        .listen(
          // This callback runs whenever the data in Firestore changes
          (snapshot) {
            _tasks =
                snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners(); // Update the UI with the new data
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = "Failed to load tasks: $error";
            notifyListeners();
          },
        );
  }

  // Refresh tasks when user changes
  void refreshTasks() {
    _tasksSubscription?.cancel();
    _initializeTaskListener();
  }

  // Add a new task
  Future<bool> addTask({
    required String title,
    required String description,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "No user logged in";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('tasks').add({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'isCompleted': false,
        'userId': user.uid,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Failed to add task: $e";
      notifyListeners();
      return false;
    }
  }

  // Toggle task completion status
  Future<bool> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return false;

    final currentStatus = _tasks[taskIndex].isCompleted;

    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': !currentStatus,
      });
      return true;
    } catch (e) {
      _errorMessage = "Failed to update task: $e";
      notifyListeners();
      return false;
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      return true;
    } catch (e) {
      _errorMessage = "Failed to delete task: $e";
      notifyListeners();
      return false;
    }
  }

  // Clear all tasks for the current user
  Future<bool> clearAllTasks() async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "No user logged in";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final tasks =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .get();

      final batch = _firestore.batch();
      for (var doc in tasks.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Failed to clear tasks: $e";
      notifyListeners();
      return false;
    }
  }

  // Calculate weekly progress
  List<Map<String, dynamic>> calculateWeeklyProgress(
    DateTime accountCreationDate,
  ) {
    // Get the most recent Monday that has passed
    final now = DateTime.now();
    DateTime mostRecentMonday = DateTime(now.year, now.month, now.day);
    while (mostRecentMonday.weekday != DateTime.monday) {
      mostRecentMonday = mostRecentMonday.subtract(const Duration(days: 1));
    }

    // Generate the last 4 Monday-Sunday weeks
    List<Map<String, dynamic>> weekRanges = [];
    for (int i = 0; i < 4; i++) {
      final weekStart = mostRecentMonday.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 6)); // Sunday

      // Skip weeks that end before the account was created
      if (weekEnd.isBefore(accountCreationDate)) {
        continue;
      }

      int totalTasksInWeek = 0;
      int completedTasksInWeek = 0;

      for (var task in _tasks) {
        if (_isTaskInWeekRange(task.date, weekStart, weekEnd)) {
          totalTasksInWeek++;
          if (task.isCompleted) {
            completedTasksInWeek++;
          }
        }
      }

      double progressPercentage =
          totalTasksInWeek > 0
              ? (completedTasksInWeek / totalTasksInWeek) * 100
              : 0.0;

      weekRanges.add({
        'start': weekStart,
        'end': weekEnd,
        'label': '${_formatDate(weekStart)}-${_formatDate(weekEnd)}',
        'total': totalTasksInWeek,
        'completed': completedTasksInWeek,
        'progress': progressPercentage,
      });
    }

    return weekRanges;
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final String month = _getMonthAbbreviation(date.month);
    return '$month ${date.day}';
  }

  // Helper method to get month abbreviation
  String _getMonthAbbreviation(int month) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  // Helper method to check if a task is in a week range
  bool _isTaskInWeekRange(
    DateTime taskDate,
    DateTime weekStart,
    DateTime weekEnd,
  ) {
    // Normalize all dates to start of day for comparison
    final taskStartOfDay = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
    );
    final weekStartDay = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final weekEndDay = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

    // A task is in the week if it falls on or after the week start day
    // and on or before the week end day
    return (taskStartOfDay.isAtSameMomentAs(weekStartDay) ||
            taskStartOfDay.isAfter(weekStartDay)) &&
        (taskStartOfDay.isAtSameMomentAs(weekEndDay) ||
            taskStartOfDay.isBefore(weekEndDay));
  }
}
