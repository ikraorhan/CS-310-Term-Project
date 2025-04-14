// lib/routes/dailyReview.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';

class DailyReviewPage extends StatefulWidget {
  const DailyReviewPage({super.key});

  @override
  State<DailyReviewPage> createState() => _DailyReviewPageState();
}

class _DailyReviewPageState extends State<DailyReviewPage> {
  // Daily progress for each day of the week.
  // Each map contains:
  // - "day": the day's name,
  // - "progress": a value from 0.0 to 1.0.
  List<Map<String, dynamic>> dailyProgress = [
    {'day': 'Monday', 'progress': 0.8},
    {'day': 'Tuesday', 'progress': 0.6},
    {'day': 'Wednesday', 'progress': 0.3},
    {'day': 'Thursday', 'progress': 0.5},
    {'day': 'Friday', 'progress': 0.0},
    {'day': 'Saturday', 'progress': 0.0},
    {'day': 'Sunday', 'progress': 0.0},
  ];

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
              // Header row: Back icon and "Daily Review" title.
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
                ],
              ),
              const SizedBox(height: 20),
              // List of days with progress.
              Column(
                children:
                    dailyProgress.map((dayData) {
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
                          child: Row(
                            children: [
                              // Display day name.
                              Text(
                                dayData['day'],
                                style: AppTextStyles.loginLabel.copyWith(
                                  fontFamily: 'LibreBaskerville',
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              // Progress bar aligned on the same row.
                              SizedBox(
                                width: 150,
                                child: LinearProgressIndicator(
                                  value: dayData['progress'],
                                  color: AppColors.mainColor,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Display progress percentage.
                              Text(
                                '${(dayData['progress'] * 100).toInt()}%',
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
            ],
          ),
        ),
      ),
    );
  }
}
