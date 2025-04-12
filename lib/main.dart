import 'package:flutter/material.dart';
import 'package:tick_task/util/colors.dart';

import 'package:tick_task/routes/welcome.dart';
import 'package:tick_task/routes/login.dart';
import 'package:tick_task/routes/signup.dart';
import 'package:tick_task/routes/home.dart';
import 'package:tick_task/routes/addNewTask.dart';

void main() {
  runApp(
    MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => Welcome(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/addNewTask': (context) => const AddNewTaskPage(),
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0.0,
          centerTitle: true,
          // dont want auto back button
        ),
      ),
    ),
  );
}
