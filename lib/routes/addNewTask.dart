// lib/routes/addNewTask.dart

import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';
import 'package:tick_task/util/styles.dart';
import 'package:intl/intl.dart';

class AddNewTaskPage extends StatefulWidget {
  const AddNewTaskPage({super.key});

  @override
  State<AddNewTaskPage> createState() => _AddNewTaskPageState();
}

class _AddNewTaskPageState extends State<AddNewTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _alarmEnabled = false;
  TimeOfDay _alarmTime = const TimeOfDay(hour: 0, minute: 0);
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
                'Tittle:',
                style: AppTextStyles.loginLabel.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: AppTextStyles.loginLabel.copyWith(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'LibreBaskerville',
                ),
                decoration: InputDecoration(
                  hintText: 'Add your tittle here!',
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
              ),
              const SizedBox(height: 20),
              // Description Field
              Text(
                'Description:',
                style: AppTextStyles.loginLabel.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
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
                      color: _selectedDate == null ? Colors.grey : Colors.black,
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
                  onPressed: () {
                    // Validate required fields: Title, Description, and Date.
                    if (_titleController.text.trim().isEmpty ||
                        _descriptionController.text.trim().isEmpty ||
                        _selectedDate == null) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Missing Fields"),
                            content: const Text(
                              "Please fill in all required fields.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("OK"),
                              ),
                            ],
                          );
                        },
                      );
                      return;
                    }
                    // All required fields are filled: proceed to create the task.
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
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
    );
  }
}
