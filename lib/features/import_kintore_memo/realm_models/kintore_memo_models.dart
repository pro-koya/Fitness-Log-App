// 筋トレMemo（iOS）の default.realm 用 Realm モデル
// Realm Studio で確認したスキーマに合わせてフィールドを調整すること
// dart run realm generate で kintore_memo_models.realm.dart を生成

import 'package:realm/realm.dart';

part 'kintore_memo_models.realm.dart';

@RealmModel()
@MapTo('class_eventLog')
class _EventLog {
  @PrimaryKey()
  late int id;

  int? eventId;
  DateTime? date;
  double? weightKg;
  double? weightLbs;
  int? reps;
  int? setNum;
  String? memo;
  _EventMaster? eventMaster;

  // 代替フィールド名（スキーマによっては snake_case）
  // weight_kg, weight_lbs, set_number 等が使われている場合は MapTo で対応
}

@RealmModel()
@MapTo('class_eventMaster')
class _EventMaster {
  @PrimaryKey()
  late int id;

  String? name;
  int? partsId;
  _PartsMaster? partsMaster;
}

@RealmModel()
@MapTo('class_partsMaster')
class _PartsMaster {
  @PrimaryKey()
  late int id;

  String? name;
}
