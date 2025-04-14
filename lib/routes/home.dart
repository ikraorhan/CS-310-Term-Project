// lib/routes/home.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Example weekly progress data.
  final List<Map<String, dynamic>> weeklyProgress = [
    {'week': 'Week 1', 'progress': 0.75}, // 75%
    {'week': 'Week 2', 'progress': 0.50}, // 50%
    {'week': 'Week 3', 'progress': 0.25}, // 25%
    {'week': 'Week 4', 'progress': 0.20}, // 20%
  ];

  // Updated upcoming tasks list with a "done" flag.
  List<Map<String, dynamic>> upcomingTasks = [
    {'title': 'Buy groceries', 'done': false},
    {'title': 'Finish the Flutter project', 'done': false},
    {'title': 'Prepare meeting agenda', 'done': false},
  ];

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
                  // Profile picture from network.
                  ClipOval(
                    child: Image.network(
                      'https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Greeting text occupies available space.
                  Expanded(
                    child: Text(
                      'Hi, Ramazan',
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
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Weekly Review Header.
              Text(
                'Weekly Review',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              // Redesigned Weekly Review Section.
              Column(
                children:
                    weeklyProgress.map((weekData) {
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
                              // Week label.
                              Text(
                                weekData['week'],
                                style: AppTextStyles.loginLabel.copyWith(
                                  fontFamily: 'LibreBaskerville',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              // Progress bar.
                              SizedBox(
                                width: 130,
                                child: LinearProgressIndicator(
                                  value: weekData['progress'],
                                  color: AppColors.mainColor,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Percentage Label.
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
              Column(
                children:
                    upcomingTasks.map((task) {
                      return Card(
                        elevation: 1.0,
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          // Leading icon to mark task as done.
                          leading: IconButton(
                            icon: Icon(
                              task['done']
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: AppColors.mainColor,
                            ),
                            onPressed: () {
                              setState(() {
                                task['done'] = !task['done'];
                              });
                            },
                          ),
                          title: Text(
                            task['title'],
                            style: AppTextStyles.loginLabel.copyWith(
                              fontFamily: 'LibreBaskerville',
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w400,
                              decoration:
                                  task['done']
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                            ),
                          ),
                          // X button to delete the task.
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: AppColors.mainColor),
                            onPressed: () {
                              setState(() {
                                upcomingTasks.remove(task);
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
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
