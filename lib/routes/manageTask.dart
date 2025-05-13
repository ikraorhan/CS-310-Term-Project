// lib/routes/manageTask.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:provider/provider.dart';
import 'package:tick_task/providers/task_provider.dart';
import 'package:tick_task/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageTaskPage extends StatefulWidget {
  const ManageTaskPage({super.key});

  @override
  State<ManageTaskPage> createState() => _ManageTaskPageState();
}

class _ManageTaskPageState extends State<ManageTaskPage> {
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
    // Get providers
    final userProvider = Provider.of<UserProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    if (!userProvider.isLoggedIn) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with back button and title
              Row(
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
              const SizedBox(height: 20),

              // Show loading indicator if loading
              if (taskProvider.isLoading)
                const Center(child: CircularProgressIndicator()),

              // Show error message if there is one
              if (taskProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    taskProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Task list
              if (!taskProvider.isLoading)
                taskProvider.tasks.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No tasks found. Add some tasks to get started!',
                        style: AppTextStyles.loginLabel.copyWith(
                          fontFamily: 'LibreBaskerville',
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : Column(
                      children:
                          taskProvider.tasks.map((task) {
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
                                  onPressed: () async {
                                    await taskProvider.toggleTaskCompletion(
                                      task.id,
                                    );
                                  },
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
                                            : TextDecoration.none,
                                  ),
                                ),
                                subtitle:
                                    task.description.isNotEmpty
                                        ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.description,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _formatDate(task.date),
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        )
                                        : Text(
                                          _formatDate(task.date),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                          ),
                                        ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: AppColors.mainColor,
                                  ),
                                  onPressed: () async {
                                    // Store the context before the async gap
                                    final scaffoldMessenger =
                                        ScaffoldMessenger.of(context);

                                    await taskProvider.deleteTask(task.id);

                                    if (!mounted) return;
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Task deleted successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                    ),

              const SizedBox(height: 30),

              // Buttons row - Add New Task and Clear All
              if (!taskProvider.isLoading)
                Row(
                  children: [
                    // Add New Task button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/addNewTask');
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Add New Task',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'LibreBaskerville',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Clear All Tasks button (only if tasks exist)
                    if (taskProvider.tasks.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Store the context before any async operation
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );

                            // Confirm before clearing all tasks
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder:
                                  (dialogContext) => AlertDialog(
                                    title: const Text('Clear all tasks?'),
                                    content: const Text(
                                      'This will remove all your tasks and cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                        child: const Text('CLEAR ALL'),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirmed == true && mounted) {
                              final success =
                                  await taskProvider.clearAllTasks();

                              if (!mounted) return;
                              if (success) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'All tasks cleared successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'LibreBaskerville',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
