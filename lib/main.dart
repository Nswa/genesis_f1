import 'package:flutter/material.dart';
import 'screens/journal_screen.dart';

void main() => runApp(const JournalApp());

class JournalApp extends StatelessWidget {
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journal Dark',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Georgia',
      ),
      home: const JournalScreen(),
    );
  }
}
