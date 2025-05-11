// lib/routes/manageTask.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageTaskPage extends StatefulWidget {
  const ManageTaskPage({super.key});

  @override
  State<ManageTaskPage> createState() => _ManageTaskPageState();
}

class _ManageTaskPageState extends State<ManageTaskPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _getTasks() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    print('Current user ID: ${user.uid}'); // Debug print

    try {
      // Query all tasks for the current user, sorted by date
      return _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: false)
          .snapshots();
    } catch (e) {
      print('Error in query: $e');
      return const Stream.empty();
    }
  }

  Future<void> _toggleTaskCompletion(String taskId, bool currentStatus) async {
    if (!mounted) return;

    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': !currentStatus,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus
                ? 'Task marked as incomplete'
                : 'Task marked as complete',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update task status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTask(String taskId) async {
    if (!mounted) return;

    try {
      await _firestore.collection('tasks').doc(taskId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllTasks() async {
    if (!mounted) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final tasks =
          await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .get();

      final batch = _firestore.batch();
      for (var doc in tasks.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tasks cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear tasks'),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view tasks')),
      );
    }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with back button and title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.mainColor,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/home'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Manage Tasks',
                      style: AppTextStyles.welcomeTitle.copyWith(
                        fontSize: 26,
                        fontFamily: 'LibreBaskerville',
                        color: AppColors.mainColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Task list with StreamBuilder
              SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    300, // Adjust height as needed
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getTasks(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No tasks found',
                          style: AppTextStyles.loginLabel.copyWith(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return Card(
                          elevation: 1.0,
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                data['isCompleted'] == true
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: AppColors.mainColor,
                              ),
                              onPressed:
                                  () => _toggleTaskCompletion(
                                    doc.id,
                                    data['isCompleted'] ?? false,
                                  ),
                            ),
                            title: Text(
                              data['title'] ?? 'Untitled Task',
                              style: AppTextStyles.loginLabel.copyWith(
                                fontFamily: 'LibreBaskerville',
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w400,
                                decoration:
                                    data['isCompleted'] == true
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['description'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatDate(data['date']),
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
                      },
                    );
                  },
                ),
              ),

              // Buttons at the bottom
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => Navigator.pushNamed(context, '/addNewTask'),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Add New Task',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'LibreBaskerville',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _clearAllTasks,
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text(
                          'Clear All Tasks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'LibreBaskerville',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
