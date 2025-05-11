// lib/routes/howTo.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';

class HowToPage extends StatelessWidget {
  const HowToPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      // TickTask AppBar at the top.
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // No default back arrow.
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with a back icon and "How To Use" title.
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.mainColor,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/home');
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'How To Use',
                    style: AppTextStyles.welcomeTitle.copyWith(
                      fontSize: 26,
                      fontFamily: 'LibreBaskerville',
                      color: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Instructional Text Container.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Welcome to TickTask - Your Daily and Weekly Helper\n\n'
                  '✔ Step 1: Create an Account or Log In\n'
                  '   • Tap on "Sign Up" to register or "Login" to enter your account.\n\n'
                  '✔ Step 2: Add New Tasks\n'
                  '   • Navigate to "Add Task" and enter:\n'
                  '     - Task Title\n'
                  '     - Optional: Due Date\n\n'
                  '✔ Step 3: View Your Tasks\n'
                  '   • All tasks will appear on the Home Page\n'
                  '   • Tasks are separated into Daily and Weekly\n\n'
                  '✔ Step 4: Mark Tasks as Done\n'
                  '   • Use the checkbox to mark completed tasks\n'
                  '   • You can also delete a task anytime\n\n'
                  '✔ Step 5: Weekly Review\n'
                  '   • View your progress each week with our progress bar\n\n'
                  '✔ Step 6: Explore More\n'
                  '   • Manage all tasks from the "Manage Tasks" section\n'
                  '   • Use the timer to stay focused while working\n\n'
                  '🎯 Tip: Stay consistent and check in daily to build strong habits!',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'LibreBaskerville',
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
