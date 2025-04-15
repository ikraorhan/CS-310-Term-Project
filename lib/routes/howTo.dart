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
                  'Welcome to Tick Task - Your Daily and Weekly Helper\n\n'
                  '1) Create an Account or Log In\n\n'
                  '2) Set Up Your Plans\n'
                  '   • You can set Daily / Weekly plans\n\n'
                  '3) Add Tasks Easily\n'
                  '   • Task Title\n'
                  '   • Due Date\n\n'
                  '4) Mark Tasks as Complete\n\n'
                  '5) Set Your Timer and Start Working',
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
