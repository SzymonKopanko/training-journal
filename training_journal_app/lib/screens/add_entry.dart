import 'package:flutter/material.dart';
import 'package:training_journal_app/models/entry.dart';
import 'package:training_journal_app/services/database.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({Key? key}) : super(key: key);

  @override
  _AddEntryScreenState createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final TextEditingController _exerciseNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final List<TextEditingController> _setsControllers = [
    TextEditingController()
  ];

  List<String> exerciseNames = [];
  String? selectedExerciseName;
  double? _lastWeight;
  List<int>? _lastSetRepetitions;

  @override
  void initState() {
    super.initState();
    _loadExerciseNames();
    _initializeWeightController();
  }

  Future<void> _loadExerciseNames() async {
    final database = TrainingDatabase.instance;
    final exerciseList = await database.readAllExercises();
    setState(() {
      exerciseNames = exerciseList.map((exercise) => exercise.exName).toList();
    });
  }

  void _initializeWeightController() async {
    if (selectedExerciseName != null) {
      final lastEntry = await TrainingDatabase.instance
          .readLastEntryByName(selectedExerciseName!);
      if (lastEntry != null) {
        setState(() {
          _lastWeight = lastEntry.weight;
          _weightController.text = '';
          _lastSetRepetitions = lastEntry.sets;
        });
      }
    }
  }

  void _initializeSetsControllers() async {
    _setsControllers.clear();
    _setsControllers.add(TextEditingController());
    if (selectedExerciseName != null) {
      final lastEntry = await TrainingDatabase.instance
          .readLastEntryByName(selectedExerciseName!);
      if (lastEntry != null) {
        setState(() {
          for (int i = 1; i < lastEntry.sets.length; i++) {
            _setsControllers.add(TextEditingController());
          }
        });
      }
    }
  }

  bool _isWeightValid() {
    if (_weightController.text.isEmpty) {
      _showValidationError(context, 'The input field for weight is empty.');
      return false;
    }
    final double number = double.tryParse(_weightController.text) ?? -1.0;
    if (number > 1000000) {
      _showValidationError(
          context,
          'Let\'s be real, you can\'t lift that. Give me some real numbers.');
      return false;
    }
    if (number < 0) {
      _showValidationError(context, 'The weight is incorrect.');
      return false;
    }
    return true;
  }

  bool _isPositiveInteger(String text) {
    final int number = int.tryParse(text) ?? -1;
    return number > 0;
  }

  bool _areSetsValid() {
    for (int index = 1; index <= _setsControllers.length; index++) {
      final controller = _setsControllers[index - 1];
      final text = controller.text.trim();
      if (text.isEmpty) {
        _showValidationError(context, 'Input field in set $index is empty.');
        return false;
      }
      if (!_isPositiveInteger(text)) {
        _showValidationError(context, 'Input in set $index is incorrect.');
        return false;
      }
      if (int.parse(text) > 100000) {
        _showValidationError(
            context,
            'The number of reps is unbelievable, please change it(set $index).');
        return false;
      }
    }
    return true;
  }

  bool _canSaveEntry() {
    if (selectedExerciseName == null && _exerciseNameController.text.isEmpty) {
      _showValidationError(
          context, 'You have to choose a name for the exercise.');
      return false;
    }
    if (_exerciseNameController.text.length > 25) {
      _showValidationError(
          context, 'Your exercise name is too long, please think of something'
          ' shorter(max length is 25 characters).');
      return false;
    }
    if (_exerciseNameController.text == 'New Exercise') {
      _showValidationError(
          context,
          'Please enter a reasonable name for the exercise'
          '(hint: not \'New Exercise\').');
      return false;
    }
    if (!_isWeightValid()) {
      return false;
    }
    if (!_areSetsValid()) {
      return false;
    }
    return true;
  }

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveEntry() {
    final exerciseName = selectedExerciseName ?? _exerciseNameController.text;
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final sets = _getSetsValues();
    final oneRM = TrainingDatabase.calculateOneRepMax(weight, sets);

    final newEntry = Entry(
      exName: exerciseName,
      exDate: DateTime.now(),
      weight: weight,
      sets: sets,
      oneRM: oneRM,
    );

    TrainingDatabase.instance.createEntry(newEntry).then((entry) {
      Navigator.pop(context);
    });
  }

  void _handleSaveButtonPressed(BuildContext context) {
    if (_canSaveEntry()) {
      _saveEntry();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exerciseNames.isEmpty)
              const Center(
                  child: Text(
                'Add some entries to choose from\n'
                ' previously performed exercises.',
                style: TextStyle(color: Colors.black54),
              ))
            else
              DropdownButtonFormField<String>(
                value: selectedExerciseName,
                onChanged: (value) {
                  setState(() {
                    selectedExerciseName = value;
                    _exerciseNameController.text = value ?? '';
                    _initializeWeightController();
                    _initializeSetsControllers();
                  });
                },
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('New Exercise'),
                  ),
                  ...exerciseNames.map((exerciseName) {
                    return DropdownMenuItem<String>(
                      value: exerciseName,
                      child: Text(exerciseName),
                    );
                  }),
                ],
                decoration:
                    const InputDecoration(labelText: 'Select Exercise Name'),
              ),
            if (selectedExerciseName == null)
              TextFormField(
                controller: _exerciseNameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'Enter name',
                ),
              ),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weight',
                hintText: 'Enter weight',
                helperText: selectedExerciseName != null
                    ? 'Last weight: $_lastWeight'
                    : null,
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _setsControllers.length,
                  itemBuilder: (context, index) {
                    final controller = _setsControllers[index];

                    final helperText = (selectedExerciseName != null &&
                            _lastSetRepetitions != null)
                        ? (index < _lastSetRepetitions!.length)
                            ? 'Last repetitions: ${_lastSetRepetitions![index]}'
                            : null
                        : null;

                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Set ${index + 1}',
                              hintText: 'Enter reps',
                              helperText: helperText,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _setsControllers.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _handleSaveButtonPressed(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Save'),
                ),
                IconButton(
                  onPressed: () {
                    if (_setsControllers.length > 99) {
                      _showValidationError(
                          context,
                          'Way too many sets, please finish this workout or'
                          ' stop playing with the app.');
                    } else {
                      setState(() {
                        _setsControllers.add(TextEditingController());
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<int> _getSetsValues() {
    final List<int> sets = [];

    for (final controller in _setsControllers) {
      final text = controller.text;
      final value = int.tryParse(text.trim()) ?? 0;
      sets.add(value);
    }

    return sets;
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _weightController.dispose();
    for (final controller in _setsControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
