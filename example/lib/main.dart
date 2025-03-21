import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Async Processing Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  String _statusMessage = "Welcome!";

  Future<void> _startAsyncTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _processProfileLogic(),
        _processThemeLogic(),
        _processLanguageLogic(),
      ]);

      setState(() {
        _statusMessage = "All tasks completed!";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processProfileLogic() async {
    await Future.delayed(Duration(seconds: 3));
    debugPrint("Profile Logic Completed");
  }

  Future<void> _processThemeLogic() async {
    await Future.delayed(Duration(seconds: 2));
    debugPrint("Theme Logic Completed");
  }

  Future<void> _processLanguageLogic() async {
    await Future.delayed(Duration(seconds: 1));
    debugPrint("Language Logic Completed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Async Processing Demo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _startAsyncTasks,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Start All Tasks'),
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Text(
                _statusMessage,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
