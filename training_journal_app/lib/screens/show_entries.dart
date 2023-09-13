import 'package:flutter/material.dart';
import 'package:training_journal_app/models/entry.dart';
import 'package:training_journal_app/services/database.dart';
import 'package:intl/intl.dart';

class ShowEntries extends StatefulWidget {
  const ShowEntries({Key? key}) : super(key: key);

  @override
  _ShowEntriesState createState() => _ShowEntriesState();
}

class _ShowEntriesState extends State<ShowEntries> {
  List<Entry> entries = [];
  List<String> exerciseNames = [];
  String selectedExerciseName = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadExerciseNames();
  }

  Future<void> _loadEntries() async {
    final database = TrainingDatabase.instance;
    final loadedEntries = await database.readAllEntries();
    setState(() {
      entries = loadedEntries.reversed.toList();
    });
  }

  Future<void> _loadExerciseNames() async {
    final database = TrainingDatabase.instance;
    final exerciseList = await database.readAllExercises();
    setState(() {
      exerciseNames = exerciseList.map((exercise) => exercise.exName).toList();
    });
  }

  List<Entry> _filterEntriesByExerciseName(String exerciseName) {
    if (exerciseName.isEmpty) {
      return entries;
    } else {
      return entries.where((entry) => entry.exName == exerciseName).toList();
    }
  }

  void _deleteEntry(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry?'),
          content: const Text(
              'This action will delete this entry. Are you sure you want to'
              ' proceed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final database = TrainingDatabase.instance;
                final entryToDelete = entries[index];
                await database.deleteEntry(entryToDelete.id!);
                setState(() {
                  entries.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete Entry'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _filterEntriesByExerciseName(selectedExerciseName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('No entries available. Add some entries.'),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedExerciseName,
                    onChanged: (value) {
                      setState(() {
                        selectedExerciseName = value ?? '';
                      });
                    },
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All Exercises'),
                      ),
                      ...exerciseNames.map((exerciseName) {
                        return DropdownMenuItem<String>(
                          value: exerciseName,
                          child: Text(exerciseName),
                        );
                      }),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Select Exercise Name',
                    ),
                  ),
                  if (entries.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.exName,
                                    style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                      'Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.exDate)}'),
                                  Text('Sets: ${entry.sets}'),
                                  Text(
                                      'Weight: ${entry.weight.toStringAsFixed(2)} kg'),
                                  Text(
                                      'One Rep Max: ${entry.oneRM.toStringAsFixed(2)} kg'),
                                  ElevatedButton(
                                    onPressed: () {
                                      _deleteEntry(context, index);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete Entry'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
