// lib/routes/review.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  int _totalTasks = 0;
  int _completedTasks = 0;
  double _completionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async {
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
      // Get all tasks for this user
      final tasksSnapshot =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .get();

      int completed = 0;
      int total = tasksSnapshot.docs.length;

      // Count completed tasks
      for (var doc in tasksSnapshot.docs) {
        final task = doc.data();
        if (task['isCompleted'] == true) {
          completed++;
        }
      }

      setState(() {
        _totalTasks = total;
        _completedTasks = completed;
        _completionRate = total > 0 ? completed / total : 0.0;
        _isLoading = false;
      });

      print('Summary: $_completedTasks/$_totalTasks = $_completionRate');
    } catch (e) {
      print('Error loading summary data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
      // Page content.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: back icon and "Review" title.
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
                    'Review',
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
                    onPressed: _loadSummaryData,
                    tooltip: 'Refresh data',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Card
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child:
                      _isLoading
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : Column(
                            children: [
                              Text(
                                'Overall Progress',
                                style: AppTextStyles.loginLabel.copyWith(
                                  fontFamily: 'LibreBaskerville',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStat('Total', _totalTasks.toString()),
                                  _buildStat(
                                    'Completed',
                                    _completedTasks.toString(),
                                  ),
                                  _buildStat(
                                    'Rate',
                                    '${(_completionRate * 100).toInt()}%',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: _completionRate,
                                color: AppColors.mainColor,
                                backgroundColor: Colors.grey.shade300,
                                minHeight: 10,
                              ),
                            ],
                          ),
                ),
              ),

              const SizedBox(height: 30),
              // Daily Review Button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/dailyReview');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Daily Review',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'LibreBaskerville',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Weekly Review Button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/weeklyReview');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Weekly Review',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'LibreBaskerville',
                    ),
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

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.loginLabel.copyWith(
            fontFamily: 'LibreBaskerville',
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.loginLabel.copyWith(
            fontFamily: 'LibreBaskerville',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
