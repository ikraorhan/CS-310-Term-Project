// lib/routes/home.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:provider/provider.dart';
import 'package:tick_task/providers/user_provider.dart';
import 'package:tick_task/providers/task_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> weeklyProgress = [];
  StreamSubscription<QuerySnapshot>? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    print('HomePage initState called');
    weeklyProgress = []; // Ensure it's initialized as empty
    _setupRealTimeUpdates();
    _debugCheckTaskItems(); // Add debug check for taskItems
    _createTestTaskIfEmpty(); // Create a test task if needed

    // Add debug logging for user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.debugUserData(); // Call the debug method

      // Forcing a reload of the user data to ensure it's up to date
      print('Forcing user data reload in home.dart');
      userProvider.reloadUserData();
    });
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _tasksSubscription?.cancel();
    super.dispose();
  }

  // Set up real-time updates for tasks
  void _setupRealTimeUpdates() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (userProvider.isLoggedIn) {
        final user = _auth.currentUser;
        if (user != null) {
          // Set up a real-time listener for tasks collection
          _tasksSubscription = _firestore
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .snapshots()
              .listen((_) {
                // Whenever tasks change, reload the data
                _loadData();
              });
        }
      }
    });

    // Initial data load
    _loadData();
  }

  Future<void> _loadData() async {
    // This will run after the build method
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      if (userProvider.isLoggedIn) {
        final accountCreationDate = await userProvider.getAccountCreationDate();
        final progress = taskProvider.calculateWeeklyProgress(
          accountCreationDate,
        );

        if (mounted) {
          setState(() {
            weeklyProgress = progress;
          });
        }
      }
    });
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
    final userProvider = Provider.of<UserProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    // If not logged in, redirect to welcome page
    if (!userProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final username = userProvider.user?.username ?? 'User';
    final profilePictureUrl = userProvider.profileImageUrl;

    // Debug profile picture URL
    print('Profile Picture URL: $profilePictureUrl');

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
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
              const SizedBox(height: 10),
              // Profile section
              Row(
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Color.fromARGB(
                      AppColors.mainColor.a.toInt(),
                      AppColors.mainColor.r.toInt(),
                      AppColors.mainColor.g.toInt(),
                      AppColors.mainColor.b.toInt() ~/
                          5, // Equivalent of withOpacity(0.2)
                    ),
                    backgroundImage:
                        profilePictureUrl != null
                            ? profilePictureUrl.startsWith('data:')
                                ? MemoryImage(
                                  base64Decode(profilePictureUrl.split(',')[1]),
                                )
                                : NetworkImage(profilePictureUrl)
                                    as ImageProvider
                            : null,
                    child:
                        profilePictureUrl == null
                            ? Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.mainColor,
                            )
                            : profilePictureUrl.startsWith('data:')
                            ? ClipOval(
                              child: Image.memory(
                                base64Decode(profilePictureUrl.split(',')[1]),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading profile image: $error');
                                  return Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.mainColor,
                                  );
                                },
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  // User greeting
                  Expanded(
                    child: Text(
                      'Hi, $username',
                      style: AppTextStyles.mainTitle.copyWith(
                        fontFamily: 'LibreBaskerville',
                        fontSize: 28,
                      ),
                    ),
                  ),
                  // Settings button
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: AppColors.mainColor,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Weekly progress section
              Text(
                'Weekly Review',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),

              // Progress cards
              if (taskProvider.isLoading || weeklyProgress.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children:
                      weeklyProgress.map((weekData) {
                        final progress = weekData['progress'] as double;
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
                                  width: 100,
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                    backgroundColor: Colors.grey.shade300,
                                    color: AppColors.mainColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Percentage
                                Text(
                                  '${progress.toStringAsFixed(0)}%',
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

              // Review progress button
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

              // Upcoming tasks section
              Text(
                'Upcoming Tasks',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),

              // Task list
              if (taskProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (taskProvider.incompleteTasks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No upcoming tasks',
                      style: AppTextStyles.loginLabel.copyWith(
                        fontFamily: 'LibreBaskerville',
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      taskProvider.incompleteTasks.length > 3
                          ? 3
                          : taskProvider.incompleteTasks.length,
                  itemBuilder: (context, index) {
                    final task = taskProvider.incompleteTasks[index];
                    return Card(
                      elevation: 1.0,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            task.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: AppColors.mainColor,
                          ),
                          onPressed:
                              () => taskProvider.toggleTaskCompletion(task.id),
                        ),
                        title: Text(
                          task.title,
                          style: AppTextStyles.loginLabel.copyWith(
                            fontFamily: 'LibreBaskerville',
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w400,
                            decoration:
                                task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(task.date),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red.shade300),
                          onPressed: () => taskProvider.deleteTask(task.id),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 30),

              // Manage tasks button
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
                  icon: const Icon(Icons.task_alt, color: Colors.white),
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

              const SizedBox(height: 20),

              // Add new task button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/addNewTask');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add New Task',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'LibreBaskerville',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // How to use button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/howTo');
                  },
                  icon: Icon(Icons.help_outline, color: AppColors.mainColor),
                  label: Text(
                    'How to Use',
                    style: TextStyle(color: AppColors.mainColor, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
