// lib/routes/weeklyReview.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';

class WeeklyReviewPage extends StatelessWidget {
  const WeeklyReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example weekly progress data with date ranges.
    final List<Map<String, dynamic>> weeklyProgress = [
      {'week': 'Week 1', 'progress': 0.75, 'dateRange': 'Jan 1 - Jan 7'},
      {'week': 'Week 2', 'progress': 0.50, 'dateRange': 'Jan 8 - Jan 14'},
      {'week': 'Week 3', 'progress': 0.25, 'dateRange': 'Jan 15 - Jan 21'},
      {'week': 'Week 4', 'progress': 0.20, 'dateRange': 'Jan 22 - Jan 28'},
    ];

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
              // Header row: back icon and "Weekly Review" title.
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
                ],
              ),
              const SizedBox(height: 20),
              // List of weekly progress cards.
              Column(
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
                          child: Row(
                            children: [
                              // Left: Week label and date range in a vertical column.
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weekData['week'],
                                    style: AppTextStyles.loginLabel.copyWith(
                                      fontFamily: 'LibreBaskerville',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    weekData['dateRange'],
                                    style: AppTextStyles.loginLabel.copyWith(
                                      fontFamily: 'LibreBaskerville',
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Right: Progress bar and percentage label.
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 130,
                                    child: LinearProgressIndicator(
                                      value: weekData['progress'],
                                      color: AppColors.mainColor,
                                      backgroundColor: Colors.grey.shade300,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
