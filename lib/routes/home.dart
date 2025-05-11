// lib/routes/home.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _username = '';
  String? _profilePictureUrl;
  List<Map<String, dynamic>> weeklyProgress = [];

  @override
  void initState() {
    super.initState();
    print('HomePage initState called');
    weeklyProgress = []; // Ensure it's initialized as empty
    _loadUsername();
    _calculateWeeklyProgress();
    _debugCheckTaskItems(); // Add debug check for taskItems
    _createTestTaskIfEmpty(); // Create a test task if needed
  }

  Future<void> _loadUsername() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        print('Loading user data for user ID: ${user.uid}');
        final userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          print('User data exists in Firestore');

          // Debug user data
          final data = userData.data()!;
          print('User data fields: ${data.keys.toList()}');

          // Debug profile image fields
          if (data.containsKey('profilePicture')) {
            print('profilePicture field exists: ${data['profilePicture']}');
          } else {
            print('profilePicture field does not exist');
          }

          if (data.containsKey('profilePictureBase64')) {
            final base64Length =
                (data['profilePictureBase64'] as String?)?.length ?? 0;
            print(
              'profilePictureBase64 field exists with length: $base64Length',
            );
          } else {
            print('profilePictureBase64 field does not exist');
          }

          setState(() {
            _username = data['username'] ?? 'User';

            // Clear existing value first
            _profilePictureUrl = null;

            // Try to get profile picture URL - prioritize base64 if available
            if (data['profilePictureBase64'] != null &&
                (data['profilePictureBase64'] as String).isNotEmpty) {
              final base64String = data['profilePictureBase64'] as String;

              // Validate base64 string
              try {
                // Try to decode a small part of the base64 string to validate it
                base64Decode(
                  base64String.substring(0, min(100, base64String.length)),
                );

                // If successful, create a data URL format that Image.network can display
                _profilePictureUrl = 'data:image/jpeg;base64,$base64String';
                print(
                  'Setting profile picture from valid base64 data (length: ${base64String.length})',
                );
                print(
                  'Profile URL set to: ${_profilePictureUrl?.substring(0, 50)}...',
                );
              } catch (e) {
                print('Invalid base64 data detected: $e');
                _profilePictureUrl = null; // Don't use invalid base64 data
              }
            } else if (data['profilePicture'] != null &&
                (data['profilePicture'] as String).isNotEmpty) {
              _profilePictureUrl = data['profilePicture'];
              print('Setting profile picture from URL: $_profilePictureUrl');
            } else {
              print('No valid profile picture data found');
            }
          });
        } else {
          print('User document does not exist in Firestore');
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    } else {
      print('No authenticated user found');
    }
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
    final user = _auth.currentUser;
    if (user == null) {
      print('No user logged in');
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
            DateTime.now().subtract(const Duration(days: 30));
      }

      print('Account creation date: $accountCreationDate');

      // Calculate date ranges for the last 4 weeks, but don't go earlier than account creation
      final now = DateTime.now();
      final DateFormat dateFormat = DateFormat('d MMM');
      List<Map<String, dynamic>> weekRanges = [];

      // Get the most recent Monday that has passed
      DateTime mostRecentMonday = DateTime(now.year, now.month, now.day);
      while (mostRecentMonday.weekday != DateTime.monday) {
        mostRecentMonday = mostRecentMonday.subtract(const Duration(days: 1));
      }

      print('Most recent Monday: $mostRecentMonday');

      // Generate the last 4 Monday-Sunday weeks
      for (int i = 0; i < 4; i++) {
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
          'label':
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
          'title': task['title'],
          'date': taskDate,
          'isCompleted': task['isCompleted'],
        });

        // Debug print task details
        print('Processing task: ${doc.id}');
        print('  Title: ${task['title']}');
        print('  isCompleted: ${task['isCompleted']}');
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
            print('  Added to week ${i + 1}: ${weekData['label']}');
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

      // Calculate progress percentages
      for (var i = 0; i < weekRanges.length; i++) {
        var weekData = weekRanges[i];
        final total = weekData['total'];
        final completed = weekData['completed'];
        weekData['progress'] = total > 0 ? completed / total : 0.0;
        print(
          'Week ${i + 1} (${weekData['label']}): $completed/$total = ${weekData['progress'] * 100}%',
        );
      }

      setState(() {
        weeklyProgress = weekRanges;
      });
    } catch (e, stackTrace) {
      print('Error calculating weekly progress: $e');
      print('Stack trace: $stackTrace');

      // Create empty date ranges in case of error
      final now = DateTime.now();
      final DateFormat dateFormat = DateFormat('d MMM');
      List<Map<String, dynamic>> emptyRanges = [];

      for (int i = 0; i < 4; i++) {
        final weekEnd = now.subtract(Duration(days: i * 7));
        final weekStart = weekEnd.subtract(const Duration(days: 6));

        emptyRanges.add({
          'label':
              '${dateFormat.format(weekStart)}-${dateFormat.format(weekEnd)}',
          'total': 0,
          'completed': 0,
          'progress': 0.0,
        });
      }

      setState(() {
        weeklyProgress = emptyRanges;
      });
    }
  }

  Stream<QuerySnapshot> _getUpcomingTasks() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    print('Getting upcoming tasks for user: ${user.uid}'); // Debug print

    try {
      // Query for uncompleted tasks only
      return _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .where('isCompleted', isEqualTo: false)
          .orderBy('date', descending: false)
          .limit(3)
          .snapshots();
    } catch (e) {
      print('Error in upcoming tasks query: $e');
      return const Stream.empty();
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No date';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Invalid date';
    }

    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  Future<void> _toggleTaskCompletion(String taskId, bool currentStatus) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': !currentStatus,
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      // Handle error silently
    }
  }

  // Debug function to check all tasks
  Future<void> _debugCheckTaskItems() async {
    try {
      // First check if any tasks exist
      final allTasksSnapshot = await _firestore.collection('tasks').get();
      print('Total tasks documents: ${allTasksSnapshot.docs.length}');

      // Print the first few documents for inspection
      if (allTasksSnapshot.docs.isNotEmpty) {
        print('Sample tasks documents:');
        for (var i = 0; i < min(3, allTasksSnapshot.docs.length); i++) {
          final doc = allTasksSnapshot.docs[i];
          print('Document ID: ${doc.id}');
          print('Document data: ${doc.data()}');
        }
      }

      // Check tasks with the current user ID
      final user = _auth.currentUser;
      if (user != null) {
        final userTasksSnapshot =
            await _firestore
                .collection('tasks')
                .where('userId', isEqualTo: user.uid)
                .get();
        print('Tasks for current user: ${userTasksSnapshot.docs.length}');
      }
    } catch (e) {
      print('Error checking tasks: $e');
    }
  }

  // Create a test task if none exist
  Future<void> _createTestTaskIfEmpty() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Check if user has any tasks
      final taskItemsSnapshot =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .get();

      if (taskItemsSnapshot.docs.isEmpty) {
        print('Creating test task for user');

        // Create a sample task
        await _firestore.collection('tasks').add({
          'userId': user.uid,
          'title': 'Test Task',
          'description': 'This is a test task',
          'isCompleted': false,
          'date': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 1)),
          ),
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'priority': 'Medium',
        });

        print('Test task created');
      }
    } catch (e) {
      print('Error creating test task: $e');
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
      // Custom AppBar with a spacer on top of the "TickTask" text.
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // No back arrow.
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10), // Spacer on top of TickTask.
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
      // Wrap the content in SafeArea for proper placement.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10), // Extra space on top.
              // Row for profile info with settings icon.
              Row(
                children: [
                  // Profile picture from user data or default
                  ClipOval(
                    child:
                        _profilePictureUrl != null
                            ? _profilePictureUrl!.startsWith('data:')
                                // For base64 data URLs, use MemoryImage instead of NetworkImage
                                ? Image.memory(
                                  base64Decode(
                                    _profilePictureUrl!.split(',')[1],
                                  ),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading base64 image: $error');
                                    print('Stack trace: $stackTrace');

                                    // On error, show default icon
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          setState(() {
                                            _profilePictureUrl = null;
                                          });
                                        });

                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey.shade600,
                                      ),
                                    );
                                  },
                                )
                                // For regular URLs, use NetworkImage as before
                                : Image.network(
                                  _profilePictureUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                      'Error loading profile image: $error',
                                    );
                                    print('Stack trace: $stackTrace');

                                    // On error, clear the URL and show default icon
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          setState(() {
                                            _profilePictureUrl = null;
                                          });
                                        });

                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey.shade600,
                                      ),
                                    );
                                  },
                                )
                            : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey.shade600,
                              ),
                            ),
                  ),
                  const SizedBox(width: 16),
                  // Greeting text occupies available space.
                  Expanded(
                    child: Text(
                      'Hi, $_username',
                      style: AppTextStyles.mainTitle.copyWith(
                        fontFamily: 'LibreBaskerville',
                        fontSize: 28,
                      ),
                    ),
                  ),
                  // Settings icon on right side.
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: AppColors.mainColor,
                      size: 28,
                    ),
                    onPressed: () async {
                      // Navigate to settings page
                      await Navigator.pushNamed(context, '/settings');

                      // Reload user data when returning
                      print('Returned from settings page, reloading user data');
                      await _loadUsername(); // Wait for the data to load

                      // No need for an additional setState since _loadUsername already calls it
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Weekly Review Header with Refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Review',
                    style: AppTextStyles.label.copyWith(
                      fontFamily: 'LibreBaskerville',
                      fontSize: 22,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: AppColors.mainColor,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        weeklyProgress = []; // Clear to show loading indicator
                      });
                      _calculateWeeklyProgress(); // Recalculate progress
                    },
                    tooltip: 'Refresh weekly stats',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Redesigned Weekly Review Section.
              Column(
                children:
                    weeklyProgress.isEmpty
                        ? [const Center(child: CircularProgressIndicator())]
                        : weeklyProgress.map((weekData) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                children: [
                                  // Week label
                                  Text(
                                    weekData['label'],
                                    style: AppTextStyles.loginLabel.copyWith(
                                      fontFamily: 'LibreBaskerville',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Task count
                                  Text(
                                    '${weekData['completed']}/${weekData['total']}',
                                    style: AppTextStyles.loginLabel.copyWith(
                                      fontFamily: 'LibreBaskerville',
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Progress bar
                                  SizedBox(
                                    width: 130,
                                    child: LinearProgressIndicator(
                                      value: weekData['progress'],
                                      color: AppColors.mainColor,
                                      backgroundColor: Colors.grey.shade300,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Percentage Label
                                  Text(
                                    '${(weekData['progress'] * 100).toInt()}%',
                                    style: AppTextStyles.loginLabel.copyWith(
                                      fontFamily: 'LibreBaskerville',
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
              ),
              const SizedBox(height: 30),
              // "Review All Tasks" Button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/review');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Review Your Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'LibreBaskerville',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Upcoming Tasks Header.
              Text(
                'Upcoming Tasks',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              // Upcoming Tasks List with "mark as done" feature.
              StreamBuilder<QuerySnapshot>(
                stream: _getUpcomingTasks(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data?.docs ?? [];

                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No upcoming tasks',
                        style: AppTextStyles.loginLabel.copyWith(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children:
                        tasks.map((doc) {
                          final task = doc.data() as Map<String, dynamic>;
                          return Card(
                            elevation: 1.0,
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: IconButton(
                                icon: Icon(
                                  task['isCompleted'] == true
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: AppColors.mainColor,
                                ),
                                onPressed:
                                    () => _toggleTaskCompletion(
                                      doc.id,
                                      task['isCompleted'] ?? false,
                                    ),
                              ),
                              title: Text(
                                task['title'] ?? 'Untitled Task',
                                style: AppTextStyles.loginLabel.copyWith(
                                  fontFamily: 'LibreBaskerville',
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w400,
                                  decoration:
                                      task['isCompleted'] == true
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['description'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatDate(task['date']),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.mainColor,
                                ),
                                onPressed: () => _deleteTask(doc.id),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
              const SizedBox(height: 30),
              // "Manage Tasks" Button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/manageTask');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  icon: const Icon(Icons.manage_accounts, color: Colors.white),
                  label: const Text(
                    'Manage Tasks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'LibreBaskerville',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Horizontal line similar to AppBar's bottom.
              Container(
                width: double.infinity,
                height: 2.0,
                color: AppColors.mainColor,
              ),
              const SizedBox(height: 20),
              // "How to Use" Button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/howTo');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'How to Use',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'LibreBaskerville',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30), // Extra space at the bottom.
            ],
          ),
        ),
      ),
    );
  }
}
