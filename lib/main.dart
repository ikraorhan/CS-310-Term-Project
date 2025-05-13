import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'package:tick_task/util/colors.dart';
import 'package:tick_task/routes/welcome.dart';
import 'package:tick_task/routes/login.dart';
import 'package:tick_task/routes/signup.dart';
import 'package:tick_task/routes/home.dart';
import 'package:tick_task/routes/addNewTask.dart';
import 'package:tick_task/routes/howTo.dart';
import 'package:tick_task/routes/manageTask.dart';
import 'package:tick_task/routes/settings.dart';
import 'package:tick_task/routes/review.dart';
import 'package:tick_task/routes/dailyReview.dart';
import 'package:tick_task/routes/weeklyReview.dart';
import 'package:tick_task/services/notification_service.dart';
import 'package:tick_task/providers/user_provider.dart';
import 'package:tick_task/providers/task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Storage
  FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 3));
  FirebaseStorage.instance.setMaxOperationRetryTime(const Duration(seconds: 3));

  // Initialize notifications
  await NotificationService().init();

  // Initialize background color from preferences
  await AppColors.initializeBackgroundColor();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => Welcome(),
          '/login': (context) => LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/home': (context) => const HomePage(),
          '/addNewTask': (context) => const AddNewTaskPage(),
          '/howTo': (context) => const HowToPage(),
          '/manageTask': (context) => const ManageTaskPage(),
          '/settings': (context) => const SettingsPage(),
          '/review': (context) => const ReviewPage(),
          '/dailyReview': (context) => const DailyReviewPage(),
          '/weeklyReview': (context) => const WeeklyReviewPage(),
        },
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light().copyWith(
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.backgroundColor,
            elevation: 0.0,
            centerTitle: true,
          ),
        ),
      ),
    );
  }
}
