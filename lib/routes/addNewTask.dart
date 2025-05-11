// lib/routes/addNewTask.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tick_task/services/notification_service.dart';

class AddNewTaskPage extends StatefulWidget {
  const AddNewTaskPage({super.key});

  @override
  State<AddNewTaskPage> createState() => _AddNewTaskPageState();
}

class _AddNewTaskPageState extends State<AddNewTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _notificationService = NotificationService();

  bool _alarmEnabled = false;
  bool _isLoading = false;
  TimeOfDay _alarmTime = const TimeOfDay(
    hour: 9,
    minute: 0,
  ); // Default to 9:00 AM
  DateTime? _selectedDate;

  /// Displays the native time picker to select an alarm time.
  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
    );
    if (picked != null && picked != _alarmTime) {
      setState(() {
        _alarmTime = picked;
      });
    }
  }

  /// Formats TimeOfDay to HH:mm format.
  String _formatTime(TimeOfDay time) {
    final DateTime now = DateTime.now();
    final DateTime dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Displays the native date picker to select a task date.
  Future<void> _pickDate(BuildContext context) async {
    final DateTime initialDate = _selectedDate ?? DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2100);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Formats the selected date in yyyy-MM-dd format.
  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select Date';
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Schedule a notification for the task
  Future<void> _scheduleNotification(String taskId, DateTime alarmTime) async {
    try {
      // Generate a unique notification ID using the task ID
      final notificationId = taskId.hashCode;

      await _notificationService.scheduleTaskNotification(
        id: notificationId,
        title: _titleController.text.trim(),
        body: _descriptionController.text.trim(),
        scheduledDate: alarmTime,
        payload: taskId, // Use task ID as payload for handling taps
      );

      print('Notification scheduled for task $taskId at $alarmTime');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> _createTask() async {
    // Check if date is selected
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date for the task'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      print('Creating task for user: ${currentUser.uid}'); // Debug print

      // Create alarm DateTime if alarm is enabled
      DateTime? alarmDateTime;
      if (_alarmEnabled && _selectedDate != null) {
        alarmDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _alarmTime.hour,
          _alarmTime.minute,
        );
      }

      // Create task document in Firestore
      final taskData = {
        'userId': currentUser.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate!),
        'createdAt':
            FieldValue.serverTimestamp(), // Changed to server timestamp
        'isCompleted': false,
        'alarm': {
          'enabled': _alarmEnabled,
          'time':
              alarmDateTime != null ? Timestamp.fromDate(alarmDateTime) : null,
        },
      };

      print('Task data to be saved: $taskData'); // Debug print

      final docRef = await _firestore.collection('tasks').add(taskData);
      final taskId = docRef.id;
      print('Task created with ID: $taskId'); // Debug print

      // Schedule notification if alarm is enabled
      if (_alarmEnabled && alarmDateTime != null) {
        await _scheduleNotification(taskId, alarmDateTime);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _alarmEnabled
                  ? 'Task created with reminder set for ${DateFormat('MMM dd, HH:mm').format(alarmDateTime!)}'
                  : 'Task created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error creating task: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      // AppBar with TickTask branding and divider.
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with back arrow and centered "Add a Task" text.
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.mainColor,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Add a Task',
                          style: AppTextStyles.welcomeTitle.copyWith(
                            fontSize: 26,
                            fontFamily: 'LibreBaskerville',
                            color: AppColors.mainColor,
                          ),
                        ),
                      ),
                    ),
                    // Invisible placeholder to balance the row.
                    const Opacity(
                      opacity: 0.0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, size: 30),
                        onPressed: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Title Field
                Text(
                  'Title:',
                  style: AppTextStyles.loginLabel.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: AppTextStyles.loginLabel.copyWith(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'LibreBaskerville',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add your title here!',
                    hintStyle: AppTextStyles.loginLabel.copyWith(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Description Field
                Text(
                  'Description:',
                  style: AppTextStyles.loginLabel.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: AppTextStyles.loginLabel.copyWith(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'LibreBaskerville',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add description for your task.',
                    hintStyle: AppTextStyles.loginLabel.copyWith(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Date Field for Task
                Text(
                  'Date:',
                  style: AppTextStyles.loginLabel.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDate(_selectedDate),
                      style: AppTextStyles.loginLabel.copyWith(
                        fontSize: 16,
                        color:
                            _selectedDate == null ? Colors.grey : Colors.black,
                        fontFamily: 'LibreBaskerville',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Alarm Toggle
                Row(
                  children: [
                    Text(
                      'Alarm:',
                      style: AppTextStyles.loginLabel.copyWith(fontSize: 16),
                    ),
                    const SizedBox(width: 20),
                    Switch(
                      value: _alarmEnabled,
                      activeColor: AppColors.mainColor,
                      onChanged: (bool value) {
                        setState(() {
                          _alarmEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Alarm Time Picker
                Row(
                  children: [
                    Text(
                      'Alarm Time:',
                      style: AppTextStyles.loginLabel.copyWith(fontSize: 16),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: _alarmEnabled ? () => _pickTime(context) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _alarmEnabled
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatTime(_alarmTime),
                          style: AppTextStyles.loginLabel.copyWith(
                            fontSize: 16,
                            color: _alarmEnabled ? Colors.black : Colors.grey,
                            fontFamily: 'LibreBaskerville',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // "Create Task" Button with Form Validation
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'Create Task',
                              style: AppTextStyles.loginLabel.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
