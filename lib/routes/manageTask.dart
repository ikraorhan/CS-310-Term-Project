// lib/routes/manageTask.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';

class ManageTaskPage extends StatefulWidget {
  const ManageTaskPage({super.key});

  @override
  State<ManageTaskPage> createState() => _ManageTaskPageState();
}

class _ManageTaskPageState extends State<ManageTaskPage> {
  // Example task list, with each task represented as a map.
  // "done" indicates if the task is completed.
  List<Map<String, dynamic>> tasks = [
    {'title': 'Buy groceries', 'done': false},
    {'title': 'Finish the Flutter project', 'done': false},
    {'title': 'Prepare meeting agenda', 'done': false},
    {'title': 'Call the supplier', 'done': false},
    {'title': 'Plan the weekly meeting', 'done': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      // TickTask AppBar at the top.
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
      // Main content.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: back icon and "Manage Tasks" title.
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
              // Task List, similar to upcoming tasks.
              Column(
                children:
                    tasks.map((task) {
                      return Card(
                        elevation: 1.0,
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          // Leading icon to mark the task as done.
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
                                tasks.remove(task);
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 30),
              // Row with "Add New Task" and "Clear All Tasks" buttons.
              Row(
                children: [
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
                      onPressed: () {
                        setState(() {
                          tasks.clear();
                        });
                      },
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
              const SizedBox(height: 30), // Extra space at the bottom.
            ],
          ),
        ),
      ),
    );
  }
}
