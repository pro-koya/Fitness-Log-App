import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';
import 'domain/liftly_workout_import.dart';
import 'domain/workout_repository.dart';

/// 筋トレMemoのインポートサービス
///
/// ダイナミックスキーマ検出により、Realm ファイル内のテーブル名を
/// 事前に知る必要なくデータを読み取る。
class ImportService {
  static const String _dedupHashPrefix = 'kintore_memo';

  /// ファイル選択（.realm）
  /// FileType.custom + allowedExtensions: ['realm'] は iOS で非対応の場合があるため、
  /// FileType.any で選択し、拡張子でフィルタする
  static Future<File?> pickRealmFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true, // iOS で path が null の場合に bytes を使用
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    if (f.bytes != null && f.bytes!.isNotEmpty) {
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(
        tempDir.path,
        'kintore_memo_pick_${DateTime.now().millisecondsSinceEpoch}.realm',
      );
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(f.bytes!);
      return tempFile;
    }
    final path = f.path;
    if (path == null) return null;
    return File(path);
  }

  /// Realm を read-only で開き、イベントログを変換して返す
  static Future<ImportPreview> parseRealmFile(File file) async {
    final bytes = await file.readAsBytes();
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(tempDir.path, 'kintore_memo_import_${DateTime.now().millisecondsSinceEpoch}.realm');
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(bytes);

    Realm? realm;
    try {
      debugPrint('[ImportService] Attempting to open Realm with schemaVersion=0');
      realm = _openRealmReadOnly(tempPath, schemaVersion: 0);
      debugPrint('[ImportService] Realm opened successfully with schemaVersion=0');
    } on Exception catch (e) {
      // Schema version mismatch: parse actual version from error and retry
      final msg = e.toString();
      debugPrint('[ImportService] Failed to open with v0: $msg');
      final actualVersion = _parseSchemaVersion(msg);
      if (actualVersion != null) {
        debugPrint('[ImportService] Retrying with detected schemaVersion=$actualVersion');
        try {
          realm = _openRealmReadOnly(tempPath, schemaVersion: actualVersion);
          debugPrint('[ImportService] Realm opened successfully with schemaVersion=$actualVersion');
        } on Exception catch (e2) {
          debugPrint('[ImportService] Failed again: ${e2.toString()}');
          await tempFile.delete();
          throw ImportException(
            _classifyError(e2.toString()),
            e2.toString(),
          );
        }
      } else {
        debugPrint('[ImportService] Could not parse schema version from error');
        await tempFile.delete();
        throw ImportException(
          _classifyError(msg),
          msg,
        );
      }
    } catch (e) {
      debugPrint('[ImportService] Unexpected error: $e');
      await tempFile.delete();
      rethrow;
    }

    try {
      // デバッグ: スキーマ情報を出力
      debugPrint('[ImportService] Realm schema objects: ${realm.schema.length}');
      for (final obj in realm.schema) {
        final propNames = obj.map((p) => '${p.name}(${p.propertyType})').join(', ');
        debugPrint('[ImportService]   Table: ${obj.name} => $propNames');
      }

      // スキーマをダイナミックに検出
      final schema = _detectSchema(realm);
      if (schema == null) {
        debugPrint('[ImportService] Schema detection FAILED - no matching tables found');
        throw ImportException(
          ImportErrorType.schemaMismatch,
          'Could not detect workout data tables in this Realm file.',
        );
      }

      debugPrint('[ImportService] Detected schema:');
      debugPrint('[ImportService]   logTable=${schema.logTable}');
      debugPrint('[ImportService]   dateProp=${schema.dateProp}');
      debugPrint('[ImportService]   weightKgProp=${schema.weightKgProp}');
      debugPrint('[ImportService]   weightLbsProp=${schema.weightLbsProp}');
      debugPrint('[ImportService]   repsProp=${schema.repsProp}');
      debugPrint('[ImportService]   setNumProp=${schema.setNumProp}');
      debugPrint('[ImportService]   memoProp=${schema.memoProp}');
      debugPrint('[ImportService]   masterLinkProp=${schema.masterLinkProp}');
      debugPrint('[ImportService]   masterTable=${schema.masterTable}');
      debugPrint('[ImportService]   masterNameProp=${schema.masterNameProp}');
      debugPrint('[ImportService]   partsTable=${schema.partsTable}');
      debugPrint('[ImportService]   partsNameProp=${schema.partsNameProp}');
      debugPrint('[ImportService]   usesForeignKeys=${schema.usesForeignKeys}');
      debugPrint('[ImportService]   logFkProp=${schema.logFkProp}');
      debugPrint('[ImportService]   masterFkProp=${schema.masterFkProp}');
      debugPrint('[ImportService]   masterPartsNoFkProp=${schema.masterPartsNoFkProp}');
      debugPrint('[ImportService]   partsNoFkProp=${schema.partsNoFkProp}');

      // デバッグ: レコード数を確認
      try {
        final logCount = realm.dynamic.all(schema.logTable).length;
        debugPrint('[ImportService] ${schema.logTable} record count: $logCount');
      } catch (e) {
        debugPrint('[ImportService] ERROR reading ${schema.logTable}: $e');
      }

      if (schema.masterTable != null) {
        try {
          final masterCount = realm.dynamic.all(schema.masterTable!).length;
          debugPrint('[ImportService] ${schema.masterTable} record count: $masterCount');
        } catch (e) {
          debugPrint('[ImportService] ERROR reading ${schema.masterTable}: $e');
        }
      }

      if (schema.partsTable != null) {
        try {
          final partsCount = realm.dynamic.all(schema.partsTable!).length;
          debugPrint('[ImportService] ${schema.partsTable} record count: $partsCount');
        } catch (e) {
          debugPrint('[ImportService] ERROR reading ${schema.partsTable}: $e');
        }
      }

      // デバッグ: 最初のレコードの全プロパティを出力
      try {
        final firstLogs = realm.dynamic.all(schema.logTable);
        if (firstLogs.isNotEmpty) {
          final first = firstLogs.first;
          debugPrint('[ImportService] First eventLog record properties:');
          for (final prop in realm.schema.firstWhere((s) => s.name == schema.logTable)) {
            try {
              dynamic value;
              switch (prop.propertyType) {
                case RealmPropertyType.string:
                  value = _getDynamic<String>(first, prop.name);
                  break;
                case RealmPropertyType.int:
                  value = _getDynamic<int>(first, prop.name);
                  break;
                case RealmPropertyType.double:
                case RealmPropertyType.float:
                  value = _getNumericAsDouble(first, prop.name);
                  break;
                case RealmPropertyType.bool:
                  value = _getDynamic<bool>(first, prop.name);
                  break;
                case RealmPropertyType.timestamp:
                  value = _getDynamic<DateTime>(first, prop.name);
                  break;
                default:
                  value = '(${prop.propertyType})';
              }
              debugPrint('[ImportService]   ${prop.name} = $value');
            } catch (e) {
              debugPrint('[ImportService]   ${prop.name} = ERROR: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('[ImportService] ERROR dumping first record: $e');
      }

      // ダイナミックにデータを読み取り変換
      final workouts = _readAndConvert(realm, schema);

      debugPrint('[ImportService] Converted workouts: ${workouts.length}');
      for (final w in workouts.take(3)) {
        debugPrint('[ImportService]   ${w.workoutDate} | ${w.exerciseName} | ${w.bodyPart} | sets=${w.sets.length}');
      }

      final dates = workouts.map((w) => w.workoutDate).toSet().toList()..sort();
      final exerciseNames = workouts.map((w) => w.exerciseName).toSet().toList();
      final totalSets = workouts.fold<int>(0, (acc, w) => acc + w.sets.length);

      return ImportPreview(
        workoutCount: workouts.length,
        totalSets: totalSets,
        dateRange: dates.isEmpty ? null : (dates.first, dates.last),
        sampleExercises: exerciseNames.take(5).toList(),
        workouts: workouts,
        tempPath: tempPath,
      );
    } finally {
      realm.close();
    }
  }

  /// 空スキーマで Realm を開く（ファイルからスキーマを自動読み取り）
  static Realm _openRealmReadOnly(String path, {required int schemaVersion}) {
    final config = Configuration.local(
      [], // 空スキーマ → ファイルから自動検出
      path: path,
      isReadOnly: true,
      schemaVersion: schemaVersion,
    );
    return Realm(config);
  }

  /// エラーメッセージからスキーマバージョンをパース
  static int? _parseSchemaVersion(String? message) {
    if (message == null) return null;
    final match = RegExp(r'last set version (\d+)').firstMatch(message);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  // ---------------------------------------------------------------------------
  // スキーマ検出
  // ---------------------------------------------------------------------------

  /// Realm ファイル内のテーブル構造をダイナミックに検出する
  static _DetectedSchema? _detectSchema(Realm realm) {
    final schemaObjects = <String, SchemaObject>{};
    for (final obj in realm.schema) {
      schemaObjects[obj.name] = obj;
    }
    if (schemaObjects.isEmpty) return null;

    // --- 筋トレMemo 既知スキーマの検出 ---
    final knownSchema = _detectKintoreMemoSchema(schemaObjects);
    if (knownSchema != null) return knownSchema;

    // --- 汎用スキーマ検出（フォールバック） ---

    // ログテーブルを検出: date(timestamp) + (weight(double) or reps(int)) を持つテーブル
    String? logTable;
    Map<String, SchemaProperty>? logProps;

    for (final entry in schemaObjects.entries) {
      final props = _propsMap(entry.value);

      final hasDate = props.values.any((p) =>
          p.propertyType == RealmPropertyType.timestamp);
      final hasNumeric = props.values.any((p) =>
          p.propertyType == RealmPropertyType.double ||
          p.propertyType == RealmPropertyType.float ||
          p.propertyType == RealmPropertyType.int);

      if (hasDate && hasNumeric) {
        // オブジェクトリンクまたは FK (int) でマスタテーブルと関連付け可能か
        final hasObjectLink = props.values.any((p) =>
            p.propertyType == RealmPropertyType.object);
        final hasForeignKey = props.values.any((p) =>
            p.propertyType == RealmPropertyType.int &&
            _matchesAny(p.name.toLowerCase(), ['eventno', 'event_no', 'eventid', 'event_id']));

        if (hasObjectLink || hasForeignKey) {
          logTable = entry.key;
          logProps = props;
          break;
        }
      }
    }

    // フォールバック: テーブル名パターンで検出
    if (logTable == null) {
      for (final entry in schemaObjects.entries) {
        final lower = entry.key.toLowerCase();
        if (_matchesAny(lower, ['log', 'event', 'record', 'training', 'workout'])) {
          logTable = entry.key;
          logProps = _propsMap(entry.value);
          break;
        }
      }
    }

    if (logTable == null || logProps == null) return null;

    // ログテーブル内のプロパティ名を特定
    final dateProp = _findPropByType(logProps, RealmPropertyType.timestamp,
        ['date', 'time', 'day', 'createdat']);
    final weightKgProp = _findPropByType(logProps, RealmPropertyType.double,
        ['weightkg', 'weight_kg']);
    final weightLbsProp = _findPropByType(logProps, RealmPropertyType.double,
        ['weightlbs', 'weight_lbs', 'weightlb', 'weight_lb']);
    // kg/lbs 特定できなければ汎用 weight
    final genericWeightProp = (weightKgProp == null && weightLbsProp == null)
        ? _findPropByType(logProps, RealmPropertyType.double, ['weight'])
            ?? _findPropByType(logProps, RealmPropertyType.float, ['weight'])
        : null;
    final repsProp = _findPropByType(logProps, RealmPropertyType.int,
        ['reps', 'rep', 'count', 'repscnt']);
    final setNumProp = _findPropByType(logProps, RealmPropertyType.int,
        ['setnum', 'set_num', 'setnumber', 'set_number', 'set', 'setcnt', 'set_cnt']);
    final memoProp = _findPropByType(logProps, RealmPropertyType.string,
        ['memo', 'note', 'comment']);

    // ログテーブルからリンク先（種目マスタ）を検出
    String? masterLinkProp;
    String? masterTable;
    for (final prop in logProps.values) {
      if (prop.propertyType == RealmPropertyType.object && prop.linkTarget != null) {
        masterLinkProp = prop.name;
        masterTable = prop.linkTarget;
        break;
      }
    }

    // オブジェクトリンクがない場合、FK ベースの結合を検出
    String? logFkProp;
    String? masterFkProp;
    String? masterPartsNoFkProp;
    String? partsNoFkProp;

    if (masterLinkProp == null) {
      // eventNo / eventId をFKとして検出
      logFkProp = _findPropByType(logProps, RealmPropertyType.int,
          ['eventno', 'event_no', 'eventid', 'event_id']);
      if (logFkProp != null) {
        // マスタテーブルを検出（同じ FK フィールドを持つテーブル）
        for (final entry in schemaObjects.entries) {
          if (entry.key == logTable) continue;
          final props = _propsMap(entry.value);
          final lower = entry.key.toLowerCase();
          final hasMasterPattern = _matchesAny(lower, ['master', 'event']);
          final hasMatchingFk = props.values.any((p) =>
              p.propertyType == RealmPropertyType.int &&
              p.name.toLowerCase() == logFkProp!.toLowerCase());
          if (hasMasterPattern && hasMatchingFk) {
            masterTable = entry.key;
            masterFkProp = logFkProp;
            break;
          }
        }
      }
    }

    // 種目マスタのプロパティを検出
    String? masterNameProp;
    String? partsLinkProp;
    String? partsTable;
    String? partsNameProp;

    if (masterTable != null && schemaObjects.containsKey(masterTable)) {
      final masterProps = _propsMap(schemaObjects[masterTable]!);
      masterNameProp = _findPropByType(masterProps, RealmPropertyType.string,
          ['name', 'eventname', 'event_name', 'title', 'label']);

      // 種目マスタからリンク先（部位マスタ）を検出（オブジェクトリンク）
      for (final prop in masterProps.values) {
        if (prop.propertyType == RealmPropertyType.object &&
            prop.linkTarget != null &&
            prop.linkTarget != logTable) {
          partsLinkProp = prop.name;
          partsTable = prop.linkTarget;
          break;
        }
      }

      // オブジェクトリンクがない場合、FK ベースで部位マスタを検出
      if (partsLinkProp == null) {
        masterPartsNoFkProp = _findPropByType(masterProps, RealmPropertyType.int,
            ['partsno', 'parts_no', 'partsid', 'parts_id']);
        if (masterPartsNoFkProp != null) {
          for (final entry in schemaObjects.entries) {
            if (entry.key == logTable || entry.key == masterTable) continue;
            final props = _propsMap(entry.value);
            final lower = entry.key.toLowerCase();
            final hasPartsPattern = _matchesAny(lower, ['parts', 'muscle', 'bodypart']);
            final hasMatchingFk = props.values.any((p) =>
                p.propertyType == RealmPropertyType.int &&
                p.name.toLowerCase() == masterPartsNoFkProp!.toLowerCase());
            if (hasPartsPattern && hasMatchingFk) {
              partsTable = entry.key;
              partsNoFkProp = masterPartsNoFkProp;
              break;
            }
          }
        }
      }
    }

    if (partsTable != null && schemaObjects.containsKey(partsTable)) {
      final partsProps = _propsMap(schemaObjects[partsTable]!);
      partsNameProp = _findPropByType(partsProps, RealmPropertyType.string,
          ['name', 'title', 'label']);
    }

    return _DetectedSchema(
      logTable: logTable,
      dateProp: dateProp,
      weightKgProp: weightKgProp ?? genericWeightProp,
      weightLbsProp: weightLbsProp,
      repsProp: repsProp,
      setNumProp: setNumProp,
      memoProp: memoProp,
      masterLinkProp: masterLinkProp,
      masterTable: masterTable,
      masterNameProp: masterNameProp,
      partsLinkProp: partsLinkProp,
      partsTable: partsTable,
      partsNameProp: partsNameProp,
      // FK ベース結合用
      logFkProp: logFkProp,
      masterFkProp: masterFkProp,
      masterPartsNoFkProp: masterPartsNoFkProp,
      partsNoFkProp: partsNoFkProp,
    );
  }

  /// 筋トレMemo の既知スキーマを検出する
  /// Realm SDK はテーブル名から class_ プレフィックスを除去するため、
  /// 両方のパターンで検出する
  static _DetectedSchema? _detectKintoreMemoSchema(Map<String, SchemaObject> schemaObjects) {
    // class_ プレフィックスあり・なし両方で検出
    final logTableName = schemaObjects.containsKey('eventLog')
        ? 'eventLog'
        : schemaObjects.containsKey('class_eventLog')
            ? 'class_eventLog'
            : null;
    final masterTableName = schemaObjects.containsKey('eventMaster')
        ? 'eventMaster'
        : schemaObjects.containsKey('class_eventMaster')
            ? 'class_eventMaster'
            : null;
    final partsTableName = schemaObjects.containsKey('partsMaster')
        ? 'partsMaster'
        : schemaObjects.containsKey('class_partsMaster')
            ? 'class_partsMaster'
            : null;

    if (logTableName == null || masterTableName == null || partsTableName == null) {
      return null;
    }

    final logProps = _propsMap(schemaObjects[logTableName]!);
    final masterProps = _propsMap(schemaObjects[masterTableName]!);
    final partsProps = _propsMap(schemaObjects[partsTableName]!);

    // 必須フィールドの存在確認
    if (!logProps.containsKey('date') || !logProps.containsKey('eventNo')) {
      return null;
    }

    debugPrint('[ImportService] Kintore Memo schema detected: log=$logTableName, master=$masterTableName, parts=$partsTableName');

    return _DetectedSchema(
      logTable: logTableName,
      dateProp: 'date',
      weightKgProp: logProps.containsKey('weight_kg') ? 'weight_kg' : null,
      weightLbsProp: logProps.containsKey('weight_lbs') ? 'weight_lbs' : null,
      repsProp: logProps.containsKey('repsCnt') ? 'repsCnt' : null,
      setNumProp: logProps.containsKey('setCnt') ? 'setCnt' : null,
      memoProp: logProps.containsKey('memo') ? 'memo' : null,
      masterLinkProp: null, // オブジェクトリンクではなく FK
      masterTable: masterTableName,
      masterNameProp: masterProps.containsKey('eventName') ? 'eventName' : null,
      partsLinkProp: null,
      partsTable: partsTableName,
      partsNameProp: partsProps.containsKey('name') ? 'name' : null,
      // FK ベース結合
      logFkProp: 'eventNo',
      masterFkProp: 'eventNo',
      masterPartsNoFkProp: masterProps.containsKey('partsNo') ? 'partsNo' : null,
      partsNoFkProp: partsProps.containsKey('partsNo') ? 'partsNo' : null,
    );
  }

  static Map<String, SchemaProperty> _propsMap(SchemaObject obj) {
    final map = <String, SchemaProperty>{};
    for (final prop in obj) {
      map[prop.name] = prop;
    }
    return map;
  }

  static bool _matchesAny(String value, List<String> patterns) {
    return patterns.any((p) => value.contains(p));
  }

  /// 指定タイプ+名前パターンに一致するプロパティ名を検索
  static String? _findPropByType(
    Map<String, SchemaProperty> props,
    RealmPropertyType type,
    List<String> namePatterns,
  ) {
    // 完全一致優先
    for (final pattern in namePatterns) {
      for (final entry in props.entries) {
        if (entry.value.propertyType == type &&
            entry.key.toLowerCase() == pattern) {
          return entry.key;
        }
      }
    }
    // 部分一致
    for (final pattern in namePatterns) {
      for (final entry in props.entries) {
        if (entry.value.propertyType == type &&
            entry.key.toLowerCase().contains(pattern)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // データ読み取り・変換
  // ---------------------------------------------------------------------------

  static List<LiftlyWorkoutImport> _readAndConvert(Realm realm, _DetectedSchema schema) {
    final logs = realm.dynamic.all(schema.logTable);

    // FK ベースの場合、マスタテーブルからルックアップマップを構築
    Map<int, _MasterRecord>? masterLookup;
    Map<int, String>? partsLookup;

    if (schema.usesForeignKeys) {
      masterLookup = _buildMasterLookup(realm, schema);
      partsLookup = _buildPartsLookup(realm, schema);
    }

    // (date, exerciseName) でグループ化
    final grouped = <String, List<_LogRecord>>{};

    for (final log in logs) {
      DateTime? date;
      if (schema.dateProp != null) {
        date = _getDynamic<DateTime>(log, schema.dateProp!);
      }
      if (date == null) continue;

      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      String exerciseName = '不明な種目';
      String? bodyPart;

      if (schema.usesForeignKeys && masterLookup != null) {
        // FK ベースの結合
        final fkValue = _getDynamic<int>(log, schema.logFkProp!);
        if (fkValue != null) {
          final master = masterLookup[fkValue];
          if (master != null) {
            exerciseName = master.name ?? exerciseName;
            if (master.partsNo != null && partsLookup != null) {
              bodyPart = partsLookup[master.partsNo];
            }
          }
        }
      } else if (schema.masterLinkProp != null) {
        // オブジェクトリンクベースの結合
        final master = _getDynamic<RealmObject>(log, schema.masterLinkProp!);
        if (master != null && schema.masterNameProp != null) {
          exerciseName = _getDynamic<String>(master, schema.masterNameProp!) ?? exerciseName;

          if (schema.partsLinkProp != null) {
            final parts = _getDynamic<RealmObject>(master, schema.partsLinkProp!);
            if (parts != null && schema.partsNameProp != null) {
              bodyPart = _getDynamic<String>(parts, schema.partsNameProp!);
            }
          }
        }
      }

      double? weightKg;
      if (schema.weightKgProp != null) {
        weightKg = _getNumericAsDouble(log, schema.weightKgProp!);
      }
      double? weightLbs;
      if (schema.weightLbsProp != null) {
        weightLbs = _getNumericAsDouble(log, schema.weightLbsProp!);
      }
      int? reps;
      if (schema.repsProp != null) {
        reps = _getDynamic<int>(log, schema.repsProp!);
      }
      int? setNum;
      if (schema.setNumProp != null) {
        setNum = _getDynamic<int>(log, schema.setNumProp!);
      }
      String? memo;
      if (schema.memoProp != null) {
        memo = _getDynamic<String>(log, schema.memoProp!);
      }

      // デバッグ: 最初の数レコードの weight 値を出力
      if (grouped.isEmpty || grouped.length < 3) {
        debugPrint('[ImportService] Record: date=$dateKey exercise=$exerciseName weightKg=$weightKg weightLbs=$weightLbs reps=$reps setCnt=$setNum');
      }

      final key = '$dateKey|$exerciseName';
      grouped.putIfAbsent(key, () => []).add(_LogRecord(
        date: date,
        exerciseName: exerciseName,
        bodyPart: bodyPart,
        weightKg: weightKg,
        weightLbs: weightLbs,
        reps: reps,
        setNum: setNum,
        memo: memo,
      ));
    }

    const lbsToKg = 0.45359237;
    final result = <LiftlyWorkoutImport>[];

    for (final entry in grouped.entries) {
      final records = entry.value;
      if (records.isEmpty) continue;

      records.sort((a, b) {
        final setA = a.setNum ?? 0;
        final setB = b.setNum ?? 0;
        if (setA != setB) return setA.compareTo(setB);
        return 0;
      });

      final first = records.first;

      final sets = <LiftlySetEntry>[];
      String? workoutNote;

      for (final r in records) {
        double? wKg;
        if (r.weightKg != null && r.weightKg! > 0) {
          wKg = r.weightKg;
        } else if (r.weightLbs != null && r.weightLbs! > 0) {
          wKg = r.weightLbs! * lbsToKg;
        }
        sets.add(LiftlySetEntry(weightKg: wKg, reps: r.reps, memo: r.memo));
        if (r.memo != null && r.memo!.trim().isNotEmpty && workoutNote == null) {
          workoutNote = r.memo;
        }
      }

      result.add(LiftlyWorkoutImport(
        workoutDate: first.date,
        exerciseName: first.exerciseName,
        bodyPart: first.bodyPart,
        sets: sets,
        note: workoutNote,
      ));
    }

    result.sort((a, b) => a.workoutDate.compareTo(b.workoutDate));
    return result;
  }

  /// eventMaster テーブルから eventNo → (eventName, partsNo) のルックアップマップを構築
  static Map<int, _MasterRecord> _buildMasterLookup(Realm realm, _DetectedSchema schema) {
    final lookup = <int, _MasterRecord>{};
    if (schema.masterTable == null || schema.masterFkProp == null) return lookup;

    try {
      final masters = realm.dynamic.all(schema.masterTable!);
      for (final master in masters) {
        final fkValue = _getDynamic<int>(master, schema.masterFkProp!);
        if (fkValue == null) continue;

        String? name;
        if (schema.masterNameProp != null) {
          name = _getDynamic<String>(master, schema.masterNameProp!);
        }

        int? partsNo;
        if (schema.masterPartsNoFkProp != null) {
          partsNo = _getDynamic<int>(master, schema.masterPartsNoFkProp!);
        }

        lookup[fkValue] = _MasterRecord(name: name, partsNo: partsNo);
      }
    } catch (_) {}
    return lookup;
  }

  /// partsMaster テーブルから partsNo → name のルックアップマップを構築
  static Map<int, String> _buildPartsLookup(Realm realm, _DetectedSchema schema) {
    final lookup = <int, String>{};
    if (schema.partsTable == null || schema.partsNoFkProp == null) return lookup;

    try {
      final parts = realm.dynamic.all(schema.partsTable!);
      for (final part in parts) {
        final fkValue = _getDynamic<int>(part, schema.partsNoFkProp!);
        if (fkValue == null) continue;

        String? name;
        if (schema.partsNameProp != null) {
          name = _getDynamic<String>(part, schema.partsNameProp!);
        }
        if (name != null) {
          lookup[fkValue] = name;
        }
      }
    } catch (_) {}
    return lookup;
  }

  /// ダイナミックプロパティを安全に取得
  /// Realm の required プロパティは get<T>（非nullable）で取得する必要がある。
  /// optional は get<T?>（nullable）で取得。両方を試行する。
  static T? _getDynamic<T extends Object>(RealmObjectBase obj, String name) {
    // 1. 非nullable（required プロパティ用）
    try {
      return obj.dynamic.get<T>(name);
    } catch (_) {}
    // 2. nullable（optional プロパティ用）
    try {
      return obj.dynamic.get<T?>(name);
    } catch (_) {}
    return null;
  }

  /// float/double どちらでも取得できる数値取得ヘルパー
  /// Realm SDK の float プロパティは get<double> でアクセスできるが、
  /// 型の厳密なチェックにより失敗する場合がある。
  /// 全パターンを網羅的に試行する。
  static double? _getNumericAsDouble(RealmObjectBase obj, String name) {
    final errors = <String>[];

    // 1. non-nullable double (required double/float)
    try {
      final v = obj.dynamic.get<double>(name);
      return v;
    } catch (e) {
      errors.add('get<double>: $e');
    }
    // 2. nullable double (optional double/float)
    try {
      final v = obj.dynamic.get<double?>(name);
      return v;
    } catch (e) {
      errors.add('get<double?>: $e');
    }
    // 3. RealmValue 経由でアクセス（型チェックをバイパス）
    try {
      final rv = obj.dynamic.get<RealmValue>(name);
      if (rv.type == RealmValueType.double) {
        return rv.as<double>();
      } else if (rv.type == RealmValueType.int) {
        return rv.as<int>().toDouble();
      }
    } catch (e) {
      errors.add('get<RealmValue>: $e');
    }
    // 4. non-nullable int → double
    try {
      final v = obj.dynamic.get<int>(name).toDouble();
      return v;
    } catch (e) {
      errors.add('get<int>: $e');
    }
    // 5. nullable int → double
    try {
      final v = obj.dynamic.get<int?>(name)?.toDouble();
      return v;
    } catch (e) {
      errors.add('get<int?>: $e');
    }

    debugPrint('[ImportService] _getNumericAsDouble FAILED for "$name": ${errors.join(' | ')}');
    return null;
  }

  // ---------------------------------------------------------------------------
  // エラー分類
  // ---------------------------------------------------------------------------

  static ImportErrorType _classifyError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('encrypt') || msg.contains('decrypt') || msg.contains('key')) {
      return ImportErrorType.encrypted;
    }
    if (msg.contains('schema') || msg.contains('migration') || msg.contains('class')) {
      return ImportErrorType.schemaMismatch;
    }
    if (msg.contains('invalid') || msg.contains('corrupt')) {
      return ImportErrorType.invalidFile;
    }
    return ImportErrorType.unknown;
  }

  /// プレビュー結果を Liftly に保存
  static Future<ImportResult> executeImport(
    ImportPreview preview,
    WorkoutRepository repository,
  ) async {
    final result = await repository.saveImportedWorkouts(
      preview.workouts,
      _dedupHashPrefix,
    );
    // 一時ファイル削除
    try {
      await File(preview.tempPath).delete();
    } catch (_) {}
    return result;
  }
}

// ---------------------------------------------------------------------------
// 内部モデル
// ---------------------------------------------------------------------------

/// 検出されたスキーマ情報
class _DetectedSchema {
  final String logTable;
  final String? dateProp;
  final String? weightKgProp;
  final String? weightLbsProp;
  final String? repsProp;
  final String? setNumProp;
  final String? memoProp;
  final String? masterLinkProp;
  final String? masterTable;
  final String? masterNameProp;
  final String? partsLinkProp;
  final String? partsTable;
  final String? partsNameProp;
  // FK ベース結合用（オブジェクトリンクがない場合）
  final String? logFkProp;
  final String? masterFkProp;
  final String? masterPartsNoFkProp;
  final String? partsNoFkProp;

  const _DetectedSchema({
    required this.logTable,
    this.dateProp,
    this.weightKgProp,
    this.weightLbsProp,
    this.repsProp,
    this.setNumProp,
    this.memoProp,
    this.masterLinkProp,
    this.masterTable,
    this.masterNameProp,
    this.partsLinkProp,
    this.partsTable,
    this.partsNameProp,
    this.logFkProp,
    this.masterFkProp,
    this.masterPartsNoFkProp,
    this.partsNoFkProp,
  });

  /// FK ベースの結合が必要かどうか
  bool get usesForeignKeys => masterLinkProp == null && logFkProp != null;
}

/// FK ベース結合用のマスタレコード
class _MasterRecord {
  final String? name;
  final int? partsNo;

  const _MasterRecord({this.name, this.partsNo});
}

/// ダイナミック読み取り結果の一時レコード
class _LogRecord {
  final DateTime date;
  final String exerciseName;
  final String? bodyPart;
  final double? weightKg;
  final double? weightLbs;
  final int? reps;
  final int? setNum;
  final String? memo;

  const _LogRecord({
    required this.date,
    required this.exerciseName,
    this.bodyPart,
    this.weightKg,
    this.weightLbs,
    this.reps,
    this.setNum,
    this.memo,
  });
}

/// プレビュー結果
class ImportPreview {
  final int workoutCount;
  final int totalSets;
  final (DateTime, DateTime)? dateRange;
  final List<String> sampleExercises;
  final List<LiftlyWorkoutImport> workouts;
  final String tempPath;

  const ImportPreview({
    required this.workoutCount,
    required this.totalSets,
    this.dateRange,
    required this.sampleExercises,
    required this.workouts,
    required this.tempPath,
  });
}

enum ImportErrorType {
  encrypted,
  schemaMismatch,
  invalidFile,
  unknown,
}

class ImportException implements Exception {
  final ImportErrorType type;
  final String message;

  ImportException(this.type, this.message);

  @override
  String toString() => message;
}
