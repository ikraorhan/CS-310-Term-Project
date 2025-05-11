// lib/routes/dailyReview.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyReviewPage extends StatefulWidget {
  const DailyReviewPage({super.key});

  @override
  State<DailyReviewPage> createState() => _DailyReviewPageState();
}

class _DailyReviewPageState extends State<DailyReviewPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> dailyProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateDailyProgress();
  }

  Future<void> _calculateDailyProgress() async {
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
      // Get the current week's Monday-Sunday dates
      final now = DateTime.now();

      // Find the Monday of the current week
      DateTime monday = now;
      while (monday.weekday != DateTime.monday) {
        monday = monday.subtract(const Duration(days: 1));
      }

      // Create a list of the days in this week
      List<Map<String, dynamic>> weekDays = [];
      List<String> dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        weekDays.add({
          'date': date,
          'day': dayNames[i],
          'total': 0,
          'completed': 0,
          'progress': 0.0,
        });
      }

      // Get tasks for the current user
      final tasksSnapshot =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .get();

      print('Found ${tasksSnapshot.docs.length} tasks for user');

      // Group tasks by day and calculate completion rates
      for (var doc in tasksSnapshot.docs) {
        final task = doc.data();
        if (task['date'] == null) {
          continue;
        }

        // Get the task date
        final taskDate = (task['date'] as Timestamp).toDate();

        // Check if the task falls within the current week
        for (var dayData in weekDays) {
          final date = dayData['date'] as DateTime;
          if (isSameDay(taskDate, date)) {
            dayData['total'] = (dayData['total'] ?? 0) + 1;
            if (task['isCompleted'] == true) {
              dayData['completed'] = (dayData['completed'] ?? 0) + 1;
            }
            break;
          }
        }
      }

      // Calculate progress percentages
      for (var dayData in weekDays) {
        final total = dayData['total'];
        final completed = dayData['completed'];
        dayData['progress'] = total > 0 ? completed / total : 0.0;
        print(
          '${dayData['day']}: ${dayData['completed']}/${dayData['total']} = ${dayData['progress']}',
        );
      }

      setState(() {
        dailyProgress = weekDays;
        _isLoading = false;
      });
    } catch (e) {
      print('Error calculating daily progress: $e');

      // Create empty days in case of error
      List<Map<String, dynamic>> emptyDays = [
        {'day': 'Monday', 'progress': 0.0, 'total': 0, 'completed': 0},
        {'day': 'Tuesday', 'progress': 0.0, 'total': 0, 'completed': 0},
        {'day': 'Wednesday', 'progress': 0.0, 'total': 0, 'completed': 0},
        {'day': 'Thursday', 'progress': 0.0, 'total': 0, 'completed': 0},
        {'day': 'Friday', 'progress': 0.0, 'total': 0, 'completed': 0},
        {'day': 'Saturday', 'progress': 0.0, 'total': 0, 'completed': 0},
        {'day': 'Sunday', 'progress': 0.0, 'total': 0, 'completed': 0},
      ];

      setState(() {
        dailyProgress = emptyDays;
        _isLoading = false;
      });
    }
  }

  // Helper method to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      // TickTask AppBar at the top.
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // custom back icon below.
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
      // Main content.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Back icon, "Daily Review" title, and refresh button
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
                    'Daily Review',
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
                    onPressed: _calculateDailyProgress,
                    tooltip: 'Refresh data',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Loading indicator or list of days with progress
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children:
                        dailyProgress.map((dayData) {
                          // Format date if available
                          String dateStr = '';
                          if (dayData['date'] != null) {
                            final date = dayData['date'] as DateTime;
                            dateStr = DateFormat('d MMM').format(date);
                          }

                          return Card(
                            elevation: 1.0,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Day name and date
                                  Row(
                                    children: [
                                      Text(
                                        dayData['day'],
                                        style: AppTextStyles.loginLabel
                                            .copyWith(
                                              fontFamily: 'LibreBaskerville',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateStr,
                                        style: AppTextStyles.loginLabel
                                            .copyWith(
                                              fontFamily: 'LibreBaskerville',
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                      ),
                                      const Spacer(),
                                      // Display task count
                                      Text(
                                        '${dayData['completed']}/${dayData['total']}',
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
                                          value: dayData['progress'],
                                          color: AppColors.mainColor,
                                          backgroundColor: Colors.grey.shade300,
                                          minHeight: 8,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Display progress percentage
                                      Text(
                                        '${(dayData['progress'] * 100).toInt()}%',
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
