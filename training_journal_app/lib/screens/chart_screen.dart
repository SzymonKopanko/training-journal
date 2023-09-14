import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:training_journal_app/models/entry.dart';
import 'package:training_journal_app/services/database.dart';

class ExerciseChartScreen extends StatefulWidget {
  final String exerciseName;

  const ExerciseChartScreen({Key? key, required this.exerciseName})
      : super(key: key);

  @override
  _ExerciseChartScreenState createState() => _ExerciseChartScreenState();
}

class _ExerciseChartScreenState extends State<ExerciseChartScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Chart'),
      ),
      body: FutureBuilder<List<Entry>>(
        future: _loadExerciseData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available.'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildChart(context, snapshot.data!),
            );
          }
        },
      ),
    );
  }

  Future<List<Entry>> _loadExerciseData() async {
    final database = TrainingDatabase.instance;
    final entries = await database.readAllEntriesByName(widget.exerciseName);
    return entries;
  }

  Widget _buildChart(BuildContext context, List<Entry> data) {
    List<charts.Series<Entry, DateTime>> seriesList = [
      charts.Series<Entry, DateTime>(
        id: '${widget.exerciseName} One Rep Max',
        domainFn: (Entry entry, _) => entry.exDate,
        measureFn: (Entry entry, _) => entry.oneRM,
        data: data,
      ),
    ];

    return charts.TimeSeriesChart(
      seriesList,
      animate: true,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      behaviors: [
        charts.SeriesLegend(),
      ],
      defaultRenderer: charts.LineRendererConfig(includePoints: true),
      customSeriesRenderers: [
        charts.PointRendererConfig(
          customRendererId: 'customPoint',
        ),
      ],
      selectionModels: [
        charts.SelectionModelConfig(
          changedListener: (charts.SelectionModel model) {
            _onSelectionChanged(model, context);
          },
        ),
      ],
      primaryMeasureAxis: const charts.NumericAxisSpec(
          tickProviderSpec:
              charts.BasicNumericTickProviderSpec(desiredTickCount: 5),
          renderSpec: charts.GridlineRendererSpec()),
      domainAxis: charts.DateTimeAxisSpec(
        tickFormatterSpec: const charts.AutoDateTimeTickFormatterSpec(
          day: charts.TimeFormatterSpec(
            format: 'dd.MM',
            transitionFormat: 'dd.MM',
          ),
          hour: charts.TimeFormatterSpec(
            format: 'HH:mm',
            transitionFormat: 'HH:mm',
          ),
        ),
        showAxisLine: true,
        renderSpec: charts.GridlineRendererSpec(
          axisLineStyle: const charts.LineStyleSpec(
            color: charts.Color.transparent,
          ),
          labelStyle: charts.TextStyleSpec(
            color: charts.Color.fromHex(code: '#FF000000'),
            fontSize: 10,
          ),
          lineStyle: charts.LineStyleSpec(
            color: charts.Color.fromHex(code: '#FF000000'),
          ),
        ),
        viewport: charts.DateTimeExtents(
          start: data.isNotEmpty ? data.first.exDate : DateTime.now(),
          end: data.isNotEmpty ? data.last.exDate : DateTime.now(),
        ),
      ),
      defaultInteractions: true,
    );
  }

  void _onSelectionChanged(charts.SelectionModel model, BuildContext context) {
    final selectedDatum = model.selectedDatum;

    if (selectedDatum.isNotEmpty) {
      final entry = selectedDatum.first.datum as Entry;
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.exDate);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Selected Entry'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: $formattedDate'),
                Text('One Rep Max: ${entry.oneRM.toStringAsFixed(2)} kg'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }
}
