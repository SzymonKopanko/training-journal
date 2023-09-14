const String entries = 'entries';

class EntryFields {
  static final List<String> values = [id, exName, exDate, weight, sets, oneRM];

  static const String id = '_id';
  static const String exName = 'exName';
  static const String exDate = 'exDate';
  static const String weight = 'weight';
  static const String sets = 'sets';
  static const String oneRM = 'oneRM';
}

class Entry {
  final int? id;
  final String exName;
  final DateTime exDate;
  final double weight;
  final List<int> sets;
  final double oneRM;

  const Entry({
    this.id,
    required this.exName,
    required this.exDate,
    required this.weight,
    required this.sets,
    required this.oneRM,
  });

  Entry copy({
    int? id,
    String? exName,
    DateTime? exDate,
    double? weight,
    List<int>? sets,
    double? oneRM,
  }) =>
      Entry(
        id: id ?? this.id,
        exName: exName ?? this.exName,
        exDate: exDate ?? this.exDate,
        weight: weight ?? this.weight,
        sets: sets ?? this.sets,
        oneRM: oneRM ?? this.oneRM,
      );

  Map<String, Object?> toJson() => {
        EntryFields.id: id,
        EntryFields.exName: exName,
        EntryFields.exDate: exDate.toIso8601String(),
        EntryFields.weight: weight,
        EntryFields.sets: sets.join(','),
        EntryFields.oneRM: oneRM,
      };

  static Entry fromJson(Map<String, Object?> json) => Entry(
        id: json[EntryFields.id] as int?,
        exName: json[EntryFields.exName] as String,
        exDate: DateTime.parse(json[EntryFields.exDate] as String),
        weight: json[EntryFields.weight] as double,
        sets: stringToIntList(json[EntryFields.sets] as String),
        oneRM: json[EntryFields.oneRM] as double,
      );

  static List<int> stringToIntList(String input) {
    List<String> stringList = input.split(',');
    List<int> integerList = [];

    for (String str in stringList) {
      int? intValue = int.tryParse(str);
      if (intValue != null) {
        integerList.add(intValue);
      }
    }
    return integerList;
  }
}
