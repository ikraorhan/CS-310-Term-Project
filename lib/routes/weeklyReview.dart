// lib/routes/weeklyReview.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WeeklyReviewPage extends StatefulWidget {
  const WeeklyReviewPage({super.key});

  @override
  State<WeeklyReviewPage> createState() => _WeeklyReviewPageState();
}

class _WeeklyReviewPageState extends State<WeeklyReviewPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> weeklyProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateWeeklyProgress();
  }

  // Helper method to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Determine if a task date is within a week range with precise day boundary checking
  bool isTaskInWeekRange(
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

  Future<void> _calculateWeeklyProgress() async {
    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Get tasks only from 'tasks' collection
      final tasksSnapshot =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .get();

      print('Tasks found for user: ${tasksSnapshot.docs.length}');

      // Get user creation date
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      DateTime accountCreationDate;

      if (userDoc.exists && userDoc.data()?['createdAt'] != null) {
        accountCreationDate =
            (userDoc.data()?['createdAt'] as Timestamp).toDate();
      } else {
        // If no creation date found, use registration time from Firebase Auth
        accountCreationDate =
            user.metadata.creationTime ??
            DateTime.now().subtract(const Duration(days: 90));
      }

      print('Account creation date: $accountCreationDate');

      // Calculate date ranges for the last 12 weeks, but don't go earlier than account creation
      final now = DateTime.now();
      final DateFormat dateFormat = DateFormat('d MMM');
      List<Map<String, dynamic>> weekRanges = [];

      // Get the most recent Monday that has passed
      DateTime mostRecentMonday = DateTime(now.year, now.month, now.day);
      while (mostRecentMonday.weekday != DateTime.monday) {
        mostRecentMonday = mostRecentMonday.subtract(const Duration(days: 1));
      }

      print('Most recent Monday: $mostRecentMonday');

      // Generate the last 12 Monday-Sunday weeks
      for (int i = 0; i < 12; i++) {
        final weekStart = mostRecentMonday.subtract(Duration(days: 7 * i));
        final weekEnd = weekStart.add(const Duration(days: 6)); // Sunday

        print('Week ${i + 1}: $weekStart to $weekEnd');

        // Skip weeks that end before the account was created
        if (weekEnd.isBefore(accountCreationDate)) {
          continue;
        }

        weekRanges.add({
          'start': weekStart,
          'end': weekEnd,
          'week': 'Week ${weekRanges.length + 1}',
          'dateRange':
              '${dateFormat.format(weekStart)}-${dateFormat.format(weekEnd)}',
          'total': 0,
          'completed': 0,
          'progress': 0.0,
        });
      }

      if (tasksSnapshot.docs.isEmpty) {
        print('No tasks found for user ${user.uid}');
        setState(() {
          weeklyProgress = weekRanges;
          _isLoading = false;
        });
        return;
      }

      // Group tasks by their date for debugging
      Map<String, List<Map<String, dynamic>>> tasksByDate = {};

      // Process tasks and assign them to appropriate date ranges
      for (var doc in tasksSnapshot.docs) {
        final task = doc.data();
        if (task['date'] == null && task['createdAt'] == null) {
          print('Task ${doc.id} has no date or createdAt field');
          continue;
        }

        // Use either date field or createdAt, whichever is available
        DateTime taskDate;
        if (task['date'] != null) {
          // Prefer the scheduled date of the task
          taskDate = (task['date'] as Timestamp).toDate();
        } else {
          taskDate = (task['createdAt'] as Timestamp).toDate();
        }

        // Group by date for debugging
        String dateKey = '${taskDate.year}-${taskDate.month}-${taskDate.day}';
        tasksByDate[dateKey] = tasksByDate[dateKey] ?? [];
        tasksByDate[dateKey]!.add({
          'id': doc.id,
          'title': task['title'] ?? 'Untitled Task',
          'date': taskDate,
          'isCompleted': task['isCompleted'] ?? false,
        });

        // Debug print task details
        print('Processing task: ${doc.id}');
        print('  Title: ${task['title'] ?? "Untitled Task"}');
        print('  isCompleted: ${task['isCompleted'] ?? false}');
        print('  Date: $taskDate');

        // Find which week range this task belongs to
        bool assignedToWeek = false;
        for (var i = 0; i < weekRanges.length; i++) {
          var weekData = weekRanges[i];

          // Debug each range check
          print(
            '  Checking week ${i + 1}: ${weekData['start']} to ${weekData['end']}',
          );
          bool isInRange = isTaskInWeekRange(
            taskDate,
            weekData['start'],
            weekData['end'],
          );
          print('  In range? $isInRange');

          if (isInRange) {
            weekData['total'] = (weekData['total'] ?? 0) + 1;
            print('  Added to week ${i + 1}: ${weekData['dateRange']}');
            print('  Week total is now: ${weekData['total']}');

            if (task['isCompleted'] == true) {
              weekData['completed'] = (weekData['completed'] ?? 0) + 1;
              print(
                '  Task is completed. Week completed count: ${weekData['completed']}',
              );
            }
            assignedToWeek = true;
            break;
          }
        }

        if (!assignedToWeek) {
          print('  Task not assigned to any week range');
        }
      }

      // Print all tasks grouped by date for debugging
      print('===== Tasks By Date =====');
      tasksByDate.forEach((date, tasks) {
        print('Date: $date');
        for (var task in tasks) {
          print(
            '  ${task['title']} (${task['isCompleted'] ? 'Completed' : 'Not Completed'})',
          );
        }
      });

      // Print all week ranges for debugging
      print('===== Week Ranges =====');
      for (int i = 0; i < weekRanges.length; i++) {
        print(
          'Week ${i + 1}: ${weekRanges[i]['start']} to ${weekRanges[i]['end']}',
        );
        print('  Tasks: ${weekRanges[i]['total']}');
        print('  Completed: ${weekRanges[i]['completed']}');
      }

      // Add the 1/2 ratio only to weeks with actual tasks

      // First, identify which weeks have real tasks in them
      Map<int, int> realTasksByWeek = {};

      // Count how many real tasks are in each week
      tasksByDate.forEach((dateKey, tasks) {
        for (var task in tasks) {
          DateTime taskDate = task['date'] as DateTime;

          // Find which week this task belongs to
          for (int i = 0; i < weekRanges.length; i++) {
            if (isTaskInWeekRange(
              taskDate,
              weekRanges[i]['start'],
              weekRanges[i]['end'],
            )) {
              realTasksByWeek[i] = (realTasksByWeek[i] ?? 0) + 1;
              print(
                'Task "${task['title']}" from $dateKey counted in week ${i + 1}, now has ${realTasksByWeek[i]} tasks',
              );
              break;
            }
          }
        }
      });

      print(
        'Weeks with real tasks: ${realTasksByWeek.keys.map((i) => 'Week ${i + 1}').join(', ')}',
      );

      // Do NOT modify the real task counts - keep them as they are
      // This is important to maintain consistency with home.dart

      // Calculate progress percentages
      for (var i = 0; i < weekRanges.length; i++) {
        var weekData = weekRanges[i];
        final total = weekData['total'];
        final completed = weekData['completed'];
        weekData['progress'] = total > 0 ? completed / total : 0.0;
        print(
          'Week ${i + 1} (${weekData['dateRange']}): $completed/$total = ${weekData['progress'] * 100}%',
        );
      }

      setState(() {
        weeklyProgress = weekRanges;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error calculating weekly progress: $e');
      print('Stack trace: $stackTrace');

      // Create empty date ranges in case of error
      final now = DateTime.now();
      final DateFormat dateFormat = DateFormat('d MMM');
      List<Map<String, dynamic>> emptyRanges = [];

      for (int i = 0; i < 12; i++) {
        final weekEnd = now.subtract(Duration(days: i * 7));
        final weekStart = weekEnd.subtract(const Duration(days: 6));

        emptyRanges.add({
          'week': 'Week ${i + 1}',
          'dateRange':
              '${dateFormat.format(weekStart)}-${dateFormat.format(weekEnd)}',
          'total': 0,
          'completed': 0,
          'progress': 0.0,
        });
      }

      setState(() {
        weeklyProgress = emptyRanges;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      // Common TickTask AppBar.
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // We'll add a custom back icon below.
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              'TickTask',
              style: AppTextStyles.welcomeTitle.copyWith(
                fontSize: 30,
                fontFamily: 'LibreBaskerville',
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: AppColors.mainColor, height: 2.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: back icon, "Weekly Review" title, and refresh button
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.mainColor,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/review');
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Weekly Review',
                    style: AppTextStyles.welcomeTitle.copyWith(
                      fontSize: 26,
                      fontFamily: 'LibreBaskerville',
                      color: AppColors.mainColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: AppColors.mainColor,
                      size: 24,
                    ),
                    onPressed: _calculateWeeklyProgress,
                    tooltip: 'Refresh data',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Loading indicator or list of weekly progress cards
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children:
                        weeklyProgress.map((weekData) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Left: Week label and date range in a vertical column.
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            weekData['week'],
                                            style: AppTextStyles.loginLabel
                                                .copyWith(
                                                  fontFamily:
                                                      'LibreBaskerville',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            weekData['dateRange'],
                                            style: AppTextStyles.loginLabel
                                                .copyWith(
                                                  fontFamily:
                                                      'LibreBaskerville',
                                                  fontSize: 14,
                                                  color: Colors.grey.shade800,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      // Right: Task count.
                                      Text(
                                        '${weekData['completed']}/${weekData['total']}',
                                        style: AppTextStyles.loginLabel
                                            .copyWith(
                                              fontFamily: 'LibreBaskerville',
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Progress bar and percentage
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: weekData['progress'],
                                          color: AppColors.mainColor,
                                          backgroundColor: Colors.grey.shade300,
                                          minHeight: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${(weekData['progress'] * 100).toInt()}%',
                                        style: AppTextStyles.loginLabel
                                            .copyWith(
                                              fontFamily: 'LibreBaskerville',
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
