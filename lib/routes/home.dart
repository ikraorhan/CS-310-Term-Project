// lib/routes/home.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example weekly data
    final List<Map<String, dynamic>> weeklyProgress = [
      {'week': 'Week 1', 'progress': 0.75}, // 75%
      {'week': 'Week 2', 'progress': 0.50}, // 50%
      {'week': 'Week 3', 'progress': 0.25}, // 25%
      {'week': 'Week 4', 'progress': 0.20}, // 20%
    ];

    // Example upcoming tasks
    final List<String> upcomingTasks = [
      'Buy groceries',
      'Finish the Flutter project',
      'Prepare meeting agenda',
    ];

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
                  // Profile picture (replace with your own image asset).
                  ClipOval(
                    child: Image.asset(
                      'lib/assets/user_profile.jpg', // Ensure this asset exists.
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
                      // TODO: Add navigation to settings page if desired.
                      // Example: Navigator.pushNamed(context, '/settings');
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
              // Upcoming Tasks Header.
              Text(
                'Upcoming Tasks',
                style: AppTextStyles.label.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              // Upcoming Tasks List.
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
                          title: Text(
                            task,
                            style: AppTextStyles.loginLabel.copyWith(
                              fontFamily: 'LibreBaskerville',
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_right,
                            color: AppColors.mainColor,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 30),
              // "Add New Task" Button placed after Upcoming Tasks.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to the addNewTask page.
                    Navigator.pushNamed(context, '/addNewTask');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor, // Main color.
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
              const SizedBox(height: 30), // Extra space at bottom.
            ],
          ),
        ),
      ),
    );
  }
}
