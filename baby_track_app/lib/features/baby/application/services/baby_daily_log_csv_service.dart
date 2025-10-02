import 'package:baby_track_app/features/baby/domain/models/baby_daily_log.dart';
import 'package:baby_track_app/features/baby/domain/repositories/baby_daily_log_repository.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

class BabyDailyLogCsvService {
  BabyDailyLogCsvService({required BabyDailyLogRepository logRepository})
      : _logRepository = logRepository;

  final BabyDailyLogRepository _logRepository;

  static const List<String> _standardHeader = <String>[
    'date',
    'time',
    'intake_ml',
    'did_poop',
    'showered',
    'vomited',
    'notes',
  ];

  Future<String> exportLogsAsCsv(int babyId) async {
    final logs = await _logRepository.getAllLogsForBaby(babyId);

    final rows = <List<dynamic>>[_standardHeader];
    final dayFormatter = DateFormat('yyyy-MM-dd');
    final timeFormatter = DateFormat('HH:mm');

    for (final log in logs) {
      rows.add(<dynamic>[
        dayFormatter.format(log.logDay),
        timeFormatter.format(log.loggedAt),
        log.intakeMl?.toString() ?? '',
        log.didPoop,
        log.showered,
        log.vomited,
        log.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<int> importStandardCsv({
    required int babyId,
    required String csvContent,
  }) async {
    final rows = const CsvToListConverter().convert(
      csvContent,
      shouldParseNumbers: false,
    );

    if (rows.isEmpty) {
      return 0;
    }

    final header = rows.first
        .map((dynamic value) => value.toString().trim().toLowerCase())
        .toList();

    final dateIndex = header.indexOf('date');
    final timeIndex = header.indexOf('time');

    if (dateIndex == -1 || timeIndex == -1) {
      throw const FormatException(
        'El CSV debe contener al menos las columnas "date" y "time".',
      );
    }

    final intakeIndex = header.indexOf('intake_ml');
    final poopIndex = header.indexOf('did_poop');
    final showerIndex = header.indexOf('showered');
    final vomitIndex = header.indexOf('vomited');
    final notesIndex = header.indexOf('notes');

    var imported = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];

      final dateString = _readCell(row, dateIndex);
      final timeString = _readCell(row, timeIndex);

      if (dateString == null || timeString == null) {
        continue;
      }

      final loggedAt = _combineDateAndTime(dateString, timeString);
      if (loggedAt == null) {
        continue;
      }

      final intakeValue = _readCell(row, intakeIndex);
      final didPoopValue = _readCell(row, poopIndex);
      final showerValue = _readCell(row, showerIndex);
      final vomitValue = _readCell(row, vomitIndex);
      final notesValue = _readCell(row, notesIndex);

      final log = BabyDailyLog(
        babyId: babyId,
        logDay: DateTime(loggedAt.year, loggedAt.month, loggedAt.day),
        loggedAt: loggedAt,
        intakeMl: _parseInt(intakeValue),
        didPoop: _parseBool(didPoopValue),
        showered: _parseBool(showerValue),
        vomited: _parseBool(vomitValue),
        notes: notesValue?.replaceAll('\\n', '\n'),
        createdAt: DateTime.now(),
      );

      await _logRepository.createLog(log);
      imported++;
    }

    return imported;
  }

  Future<int> importLegacyCsv({
    required int babyId,
    required String csvContent,
  }) async {
    final rows = const CsvToListConverter().convert(
      csvContent,
      shouldParseNumbers: false,
    );

    if (rows.isEmpty) {
      return 0;
    }

    final header = rows.first
        .map((dynamic value) => _normalizeHeader(value.toString()))
        .toList();

    final dateIndex = header.indexOf('fecha');
    final timeIndex = header.indexOf('hora');

    if (dateIndex == -1 || timeIndex == -1) {
      throw const FormatException(
        'El CSV anterior debe tener las columnas "Fecha" y "Hora".',
      );
    }

    final bottleIndex = header.indexOf('biberon (ml)');
    final poopIndex = header.indexOf('caca');
    final vomitIndex = header.indexOf('vomito');
    final bathIndex = header.indexOf('bano');

    var imported = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final dateString = _readCell(row, dateIndex);
      final timeString = _readCell(row, timeIndex);

      if (dateString == null || timeString == null) {
        continue;
      }

      final loggedAt = _combineDateAndTime(dateString, timeString);
      if (loggedAt == null) {
        continue;
      }

      final intakeValue = _readCell(row, bottleIndex);
      final poopValue = _readCell(row, poopIndex);
      final vomitValue = _readCell(row, vomitIndex);
      final bathValue = _readCell(row, bathIndex);

      final log = BabyDailyLog(
        babyId: babyId,
        logDay: DateTime(loggedAt.year, loggedAt.month, loggedAt.day),
        loggedAt: loggedAt,
        intakeMl: _parseInt(intakeValue),
        didPoop: _parseBool(poopValue),
        vomited: _parseBool(vomitValue),
        showered: _parseBool(bathValue),
        createdAt: DateTime.now(),
      );

      await _logRepository.createLog(log);
      imported++;
    }

    return imported;
  }

  String? _readCell(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) {
      return null;
    }
    final dynamic value = row[index];
    if (value == null) {
      return null;
    }
    final result = value.toString().trim();
    if (result.isEmpty) {
      return null;
    }
    return result;
  }

  DateTime? _combineDateAndTime(String dateString, String timeString) {
    final normalizedTime = timeString.replaceAll('.', ':');
    final date = DateTime.tryParse(dateString);
    if (date == null) {
      return null;
    }

    final timeParts = normalizedTime.split(':');
    if (timeParts.length < 2) {
      return null;
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  int? _parseInt(String? value) {
    if (value == null) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp('[^0-9-]'), '');
    if (cleaned.isEmpty) {
      return null;
    }
    return int.tryParse(cleaned);
  }

  bool _parseBool(String? value) {
    if (value == null) {
      return false;
    }
    final normalized = _normalizeValue(value);
    if (normalized.isEmpty) {
      return false;
    }

    const truthy = <String>{
      '1',
      'true',
      't',
      'si',
      'sí',
      's',
      'x',
      'yes',
      'y',
    };

    return truthy.contains(normalized);
  }

  String _normalizeValue(String value) {
    var normalized = value.toLowerCase().trim();
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'Ã¡': 'a',
      'Ã¢': 'a',
      'Ã¤': 'a',
      'Â': '',
      'Ã©': 'e',
      'Ã«': 'e',
      'Ã¨': 'e',
      'Ã­': 'i',
      'Ã¯': 'i',
      'Ã²': 'o',
      'Ã³': 'o',
      'Ã¶': 'o',
      'Ãµ': 'o',
      'Ãº': 'u',
      'Ã¼': 'u',
      'Ã¹': 'u',
      'Ã±': 'n',
    };

    replacements.forEach((String key, String value) {
      normalized = normalized.replaceAll(key, value);
    });

    normalized = normalized.replaceAll(RegExp('[^a-z0-9]'), '');
    return normalized;
  }

  String _normalizeHeader(String value) {
    var normalized = value.toLowerCase().trim();

    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'Ã¡': 'a',
      'Ã¢': 'a',
      'Ã¤': 'a',
      'Ã©': 'e',
      'Ã«': 'e',
      'Ã¨': 'e',
      'Ã­': 'i',
      'Ã¯': 'i',
      'Ã³': 'o',
      'Ã´': 'o',
      'Ã¶': 'o',
      'Ãµ': 'o',
      'Ãº': 'u',
      'Ã¼': 'u',
      'Ã¹': 'u',
      'Ã±': 'n',
    };

    replacements.forEach((String key, String value) {
      normalized = normalized.replaceAll(key, value);
    });

    normalized = normalized.replaceAll(RegExp('[^a-z0-9 ()/_-]'), '');
    return normalized;
  }
}
