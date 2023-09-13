const String exercises = 'exercises';

class ExerciseFields {
  static final List<String> values = [id, exName, exDate, oneRM];

  static const String id = '_id';
  static const String exName = 'exName';
  static const String exDate = 'exDate';
  static const String oneRM = 'oneRM';
}

class Exercise {
  final int? id;
  final String exName;
  final DateTime exDate;
  final double oneRM;

  const Exercise({
    this.id,
    required this.exName,
    required this.exDate,
    required this.oneRM,
  });

  Exercise copy({
    int? id,
    String? exName,
    DateTime? exDate,
    double? oneRM,
  }) =>
      Exercise(
        id: id ?? this.id,
        exName: exName ?? this.exName,
        exDate: exDate ?? this.exDate,
        oneRM: oneRM ?? this.oneRM,
      );

  Map<String, Object?> toJson() => {
        ExerciseFields.id: id,
        ExerciseFields.exName: exName,
        ExerciseFields.exDate: exDate.toIso8601String(),
        ExerciseFields.oneRM: oneRM,
      };

  static Exercise fromJson(Map<String, Object?> json) => Exercise(
        id: json[ExerciseFields.id] as int?,
        exName: json[ExerciseFields.exName] as String,
        exDate: DateTime.parse(json[ExerciseFields.exDate] as String),
        oneRM: json[ExerciseFields.oneRM] as double,
      );
}
