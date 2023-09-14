import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:training_journal_app/screens/add_entry.dart';
import 'package:training_journal_app/screens/show_entries.dart';
import 'package:training_journal_app/screens/show_exercises.dart';
import 'package:training_journal_app/services/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const MaterialColor customBlack = MaterialColor(0xFF000000, {
    50: Color(0xFFE0E0E0),
    100: Color(0xFFB3B3B3),
    200: Color(0xFF808080),
    300: Color(0xFF555555),
    400: Color(0xFF333333),
    500: Color(0xFF000000),
    600: Color(0xFF000000),
    700: Color(0xFF000000),
    800: Color(0xFF000000),
    900: Color(0xFF000000),
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: customBlack,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Data?'),
          content: const Text(
              'This action will delete all entries and exercises. Are you sure'
              ' you want to proceed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteAllData(context);
                Navigator.of(context).pop();
              },
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAllData(BuildContext context) async {
    final database = TrainingDatabase.instance;
    await database.deleteDB();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('All data has been deleted.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Journal'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddEntryScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200.0, 80.0),
                padding: const EdgeInsets.all(16.0),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Add Entry',
                style: TextStyle(fontSize: 25),
              ),
            ),
            const SizedBox(height: 50.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShowEntries()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200.0, 80.0),
                padding: const EdgeInsets.all(16.0),
              ),
              child: const Text(
                'History',
                style: TextStyle(fontSize: 25),
              ),
            ),
            const SizedBox(height: 50.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ShowExercises()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200.0, 80.0),
                padding: const EdgeInsets.all(16.0),
              ),
              child: const Text(
                'Exercises',
                style: TextStyle(fontSize: 25),
              ),
            ),
            const SizedBox(height: 50.0),
            ElevatedButton(
              onPressed: () {
                _showDeleteConfirmationDialog(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200.0, 80.0),
                padding: const EdgeInsets.all(16.0),
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete All',
                style: TextStyle(fontSize: 25),
              ),
            ),
            const SizedBox(height: 50.0),
            const Text('by Szymon Kopańko', style: TextStyle(color: Colors.black54),)
          ],
        ),
      ),
    );
  }
}
