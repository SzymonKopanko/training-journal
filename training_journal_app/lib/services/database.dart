import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:training_journal_app/models/entry.dart';
import 'package:training_journal_app/models/exercise.dart';

class TrainingDatabase {
  static final TrainingDatabase instance = TrainingDatabase._init();
  static Database? _database;

  TrainingDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'training.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE $entries (
      ${EntryFields.id} $idType, 
      ${EntryFields.exName} $textType,
      ${EntryFields.exDate} $textType,
      ${EntryFields.weight} $realType,
      ${EntryFields.sets} $textType,
      ${EntryFields.oneRM} $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE $exercises (
      ${ExerciseFields.id} $idType, 
      ${ExerciseFields.exName} $textType,
      ${ExerciseFields.exDate} $integerType,
      ${ExerciseFields.oneRM} $realType
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<Entry> createEntry(Entry entry) async {
    final db = await instance.database;

    final id = await db.insert(entries, entry.toJson());
    updateOrInsertExerciseSummary(entry);
    return entry.copy(id: id);
  }

  Future<Entry> readEntryById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      entries,
      columns: EntryFields.values,
      where: '${EntryFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Entry.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Entry>> readAllEntries() async {
    final db = await instance.database;
    final result = await db.query(entries);
    return result.map((json) => Entry.fromJson(json)).toList();
  }

  Future<List<Entry>> readAllEntriesByName(String exerciseName) async {
    final db = await instance.database;
    final result = await db.query(
      entries,
      where: '${EntryFields.exName} = ?',
      whereArgs: [exerciseName],
    );
    return result.map((json) => Entry.fromJson(json)).toList();
  }

  Future<int> deleteEntry(int id) async {
    final db = await instance.database;
    final entryToDelete = await readEntryById(id);

    final rowsDeleted = await db.delete(
      entries,
      where: '${EntryFields.id} = ?',
      whereArgs: [id],
    );

    if (rowsDeleted > 0) {
      final existingExercise = await readExerciseByName(entryToDelete.exName);
      if (existingExercise != null) {
        final entriesWithSameName = await db.query(
          entries,
          where: '${EntryFields.exName} = ?',
          whereArgs: [entryToDelete.exName],
        );

        if (entriesWithSameName.isEmpty) {
          await deleteExercise(existingExercise.id!);
        } else if (entryToDelete.oneRM == existingExercise.oneRM) {
          double maxOneRepMax = 0;
          DateTime latestDate = existingExercise.exDate;
          for (final entry in entriesWithSameName) {
            final entryOneRM = entry[EntryFields.oneRM] as double;
            final entryDate =
                DateTime.parse(entry[EntryFields.exDate] as String);

            if (entryOneRM > maxOneRepMax) {
              maxOneRepMax = entryOneRM;
              latestDate = entryDate;
            }
          }

          final updatedExercise =
              existingExercise.copy(oneRM: maxOneRepMax, exDate: latestDate);
          await updateExercise(updatedExercise);
        }
      }
    }

    return rowsDeleted;
  }

  Future<int> deleteAllEntriesByName(String exerciseName) async {
    final db = await instance.database;

    return await db.delete(
      entries,
      where: '${EntryFields.exName} = ?',
      whereArgs: [exerciseName],
    );
  }

  Future<Exercise> createExercise(Exercise exercise) async {
    final db = await instance.database;

    final id = await db.insert(exercises, exercise.toJson());
    return exercise.copy(id: id);
  }

  Future<Exercise?> readExerciseByName(String name) async {
    final db = await instance.database;
    final result = await db.query(
      exercises,
      where: '${ExerciseFields.exName} = ?',
      whereArgs: [name],
    );
    if (result.isEmpty) {
      return null;
    } else {
      return Exercise.fromJson(result.first);
    }
  }

  Future<Exercise> readExerciseById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      exercises,
      columns: ExerciseFields.values,
      where: '${ExerciseFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Exercise.fromJson(maps.first);
    } else {
      throw Exception('Exercise with ID $id not found');
    }
  }

  Future<List<Exercise>> readAllExercises() async {
    final db = await instance.database;
    final result = await db.query(
      exercises,
      orderBy: '${ExerciseFields.exName} ASC',
    );
    return result.map((json) => Exercise.fromJson(json)).toList();
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await instance.database;
    return await db.update(
      exercises,
      exercise.toJson(),
      where: '${ExerciseFields.id} = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> deleteExercise(int id) async {
    final db = await instance.database;
    final exerciseToDelete = await readExerciseById(id);

    final rowsDeleted = await db.delete(
      exercises,
      where: '${ExerciseFields.id} = ?',
      whereArgs: [id],
    );

    if (rowsDeleted > 0) {
      await deleteAllEntriesByName(exerciseToDelete.exName);
    }

    return rowsDeleted;
  }


  static final Map<int, double> repPercentages = {
    1: 1.0,
    2: 0.97,
    3: 0.94,
    4: 0.92,
    5: 0.89,
    6: 0.86,
    7: 0.83,
    8: 0.81,
    9: 0.78,
    10: 0.75,
    11: 0.73,
    12: 0.71,
    13: 0.70,
    14: 0.68,
    15: 0.67,
    16: 0.65,
    17: 0.64,
    18: 0.63,
    19: 0.61,
    20: 0.60,
    21: 0.59,
    22: 0.58,
    23: 0.57,
    24: 0.56,
    25: 0.55,
    26: 0.54,
    27: 0.53,
    28: 0.52,
    29: 0.51,
    30: 0.50,
  };

  static double calculateOneRepMax(double weight, List<int> sets) {
    int maxRepetitions = 1;
    for (int repetitions in sets) {
      if (repetitions > maxRepetitions) {
        maxRepetitions = repetitions;
      }
    }

    if (!repPercentages.containsKey(maxRepetitions)) {
      if (maxRepetitions < 60) {
        return weight * (1 + maxRepetitions * 0.022);
      } else if (maxRepetitions < 100) {
        return weight * (2 + (maxRepetitions-60) * 0.011);
      } else {
        return weight * 3.2;
      }
    }
    double percentage = repPercentages[maxRepetitions]!;
    return weight / percentage;
  }

  Future<void> updateOrInsertExerciseSummary(Entry newEntry) async {
    String exName = newEntry.exName;
    double newOneRepMax = calculateOneRepMax(newEntry.weight, newEntry.sets);
    Future<Exercise?> futureExistingExercise = readExerciseByName(exName);
    Exercise? existingExercise = await futureExistingExercise;
    if (existingExercise == null) {
      Exercise newExercise =
          Exercise(exName: exName, exDate: DateTime.now(), oneRM: newOneRepMax);
      createExercise(newExercise);
    } else {
      double existingOneRepMax = existingExercise.oneRM;
      if (newOneRepMax > existingOneRepMax) {
        Exercise updatedExercise =
            existingExercise.copy(oneRM: newOneRepMax, exDate: DateTime.now());
        updateExercise(updatedExercise);
      }
    }
  }

  Future<Entry?> readLastEntryByName(String name) async {
    final db = await instance.database;
    final result = await db.query(
      entries,
      where: '${EntryFields.exName} = ?',
      whereArgs: [name],
      orderBy: '${EntryFields.exDate} DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Entry.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<void> deleteDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'training.db');
    await deleteDatabase(path);
    _database = null;
  }
}
