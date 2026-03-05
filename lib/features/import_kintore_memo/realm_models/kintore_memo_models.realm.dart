// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kintore_memo_models.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class EventLog extends _EventLog
    with RealmEntity, RealmObjectBase, RealmObject {
  EventLog(
    int id, {
    int? eventId,
    DateTime? date,
    double? weightKg,
    double? weightLbs,
    int? reps,
    int? setNum,
    String? memo,
    EventMaster? eventMaster,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'eventId', eventId);
    RealmObjectBase.set(this, 'date', date);
    RealmObjectBase.set(this, 'weightKg', weightKg);
    RealmObjectBase.set(this, 'weightLbs', weightLbs);
    RealmObjectBase.set(this, 'reps', reps);
    RealmObjectBase.set(this, 'setNum', setNum);
    RealmObjectBase.set(this, 'memo', memo);
    RealmObjectBase.set(this, 'eventMaster', eventMaster);
  }

  EventLog._();

  @override
  int get id => RealmObjectBase.get<int>(this, 'id') as int;
  @override
  set id(int value) => RealmObjectBase.set(this, 'id', value);

  @override
  int? get eventId => RealmObjectBase.get<int>(this, 'eventId') as int?;
  @override
  set eventId(int? value) => RealmObjectBase.set(this, 'eventId', value);

  @override
  DateTime? get date =>
      RealmObjectBase.get<DateTime>(this, 'date') as DateTime?;
  @override
  set date(DateTime? value) => RealmObjectBase.set(this, 'date', value);

  @override
  double? get weightKg =>
      RealmObjectBase.get<double>(this, 'weightKg') as double?;
  @override
  set weightKg(double? value) => RealmObjectBase.set(this, 'weightKg', value);

  @override
  double? get weightLbs =>
      RealmObjectBase.get<double>(this, 'weightLbs') as double?;
  @override
  set weightLbs(double? value) => RealmObjectBase.set(this, 'weightLbs', value);

  @override
  int? get reps => RealmObjectBase.get<int>(this, 'reps') as int?;
  @override
  set reps(int? value) => RealmObjectBase.set(this, 'reps', value);

  @override
  int? get setNum => RealmObjectBase.get<int>(this, 'setNum') as int?;
  @override
  set setNum(int? value) => RealmObjectBase.set(this, 'setNum', value);

  @override
  String? get memo => RealmObjectBase.get<String>(this, 'memo') as String?;
  @override
  set memo(String? value) => RealmObjectBase.set(this, 'memo', value);

  @override
  EventMaster? get eventMaster =>
      RealmObjectBase.get<EventMaster>(this, 'eventMaster') as EventMaster?;
  @override
  set eventMaster(covariant EventMaster? value) =>
      RealmObjectBase.set(this, 'eventMaster', value);

  @override
  Stream<RealmObjectChanges<EventLog>> get changes =>
      RealmObjectBase.getChanges<EventLog>(this);

  @override
  Stream<RealmObjectChanges<EventLog>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<EventLog>(this, keyPaths);

  @override
  EventLog freeze() => RealmObjectBase.freezeObject<EventLog>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'eventId': eventId.toEJson(),
      'date': date.toEJson(),
      'weightKg': weightKg.toEJson(),
      'weightLbs': weightLbs.toEJson(),
      'reps': reps.toEJson(),
      'setNum': setNum.toEJson(),
      'memo': memo.toEJson(),
      'eventMaster': eventMaster.toEJson(),
    };
  }

  static EJsonValue _toEJson(EventLog value) => value.toEJson();
  static EventLog _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'id': EJsonValue id} => EventLog(
        fromEJson(id),
        eventId: fromEJson(ejson['eventId']),
        date: fromEJson(ejson['date']),
        weightKg: fromEJson(ejson['weightKg']),
        weightLbs: fromEJson(ejson['weightLbs']),
        reps: fromEJson(ejson['reps']),
        setNum: fromEJson(ejson['setNum']),
        memo: fromEJson(ejson['memo']),
        eventMaster: fromEJson(ejson['eventMaster']),
      ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(EventLog._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      EventLog,
      'class_eventLog',
      [
        SchemaProperty('id', RealmPropertyType.int, primaryKey: true),
        SchemaProperty('eventId', RealmPropertyType.int, optional: true),
        SchemaProperty('date', RealmPropertyType.timestamp, optional: true),
        SchemaProperty('weightKg', RealmPropertyType.double, optional: true),
        SchemaProperty('weightLbs', RealmPropertyType.double, optional: true),
        SchemaProperty('reps', RealmPropertyType.int, optional: true),
        SchemaProperty('setNum', RealmPropertyType.int, optional: true),
        SchemaProperty('memo', RealmPropertyType.string, optional: true),
        SchemaProperty(
          'eventMaster',
          RealmPropertyType.object,
          optional: true,
          linkTarget: 'class_eventMaster',
        ),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class EventMaster extends _EventMaster
    with RealmEntity, RealmObjectBase, RealmObject {
  EventMaster(int id, {String? name, int? partsId, PartsMaster? partsMaster}) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'partsId', partsId);
    RealmObjectBase.set(this, 'partsMaster', partsMaster);
  }

  EventMaster._();

  @override
  int get id => RealmObjectBase.get<int>(this, 'id') as int;
  @override
  set id(int value) => RealmObjectBase.set(this, 'id', value);

  @override
  String? get name => RealmObjectBase.get<String>(this, 'name') as String?;
  @override
  set name(String? value) => RealmObjectBase.set(this, 'name', value);

  @override
  int? get partsId => RealmObjectBase.get<int>(this, 'partsId') as int?;
  @override
  set partsId(int? value) => RealmObjectBase.set(this, 'partsId', value);

  @override
  PartsMaster? get partsMaster =>
      RealmObjectBase.get<PartsMaster>(this, 'partsMaster') as PartsMaster?;
  @override
  set partsMaster(covariant PartsMaster? value) =>
      RealmObjectBase.set(this, 'partsMaster', value);

  @override
  Stream<RealmObjectChanges<EventMaster>> get changes =>
      RealmObjectBase.getChanges<EventMaster>(this);

  @override
  Stream<RealmObjectChanges<EventMaster>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<EventMaster>(this, keyPaths);

  @override
  EventMaster freeze() => RealmObjectBase.freezeObject<EventMaster>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'partsId': partsId.toEJson(),
      'partsMaster': partsMaster.toEJson(),
    };
  }

  static EJsonValue _toEJson(EventMaster value) => value.toEJson();
  static EventMaster _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'id': EJsonValue id} => EventMaster(
        fromEJson(id),
        name: fromEJson(ejson['name']),
        partsId: fromEJson(ejson['partsId']),
        partsMaster: fromEJson(ejson['partsMaster']),
      ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(EventMaster._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      EventMaster,
      'class_eventMaster',
      [
        SchemaProperty('id', RealmPropertyType.int, primaryKey: true),
        SchemaProperty('name', RealmPropertyType.string, optional: true),
        SchemaProperty('partsId', RealmPropertyType.int, optional: true),
        SchemaProperty(
          'partsMaster',
          RealmPropertyType.object,
          optional: true,
          linkTarget: 'class_partsMaster',
        ),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class PartsMaster extends _PartsMaster
    with RealmEntity, RealmObjectBase, RealmObject {
  PartsMaster(int id, {String? name}) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
  }

  PartsMaster._();

  @override
  int get id => RealmObjectBase.get<int>(this, 'id') as int;
  @override
  set id(int value) => RealmObjectBase.set(this, 'id', value);

  @override
  String? get name => RealmObjectBase.get<String>(this, 'name') as String?;
  @override
  set name(String? value) => RealmObjectBase.set(this, 'name', value);

  @override
  Stream<RealmObjectChanges<PartsMaster>> get changes =>
      RealmObjectBase.getChanges<PartsMaster>(this);

  @override
  Stream<RealmObjectChanges<PartsMaster>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<PartsMaster>(this, keyPaths);

  @override
  PartsMaster freeze() => RealmObjectBase.freezeObject<PartsMaster>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{'id': id.toEJson(), 'name': name.toEJson()};
  }

  static EJsonValue _toEJson(PartsMaster value) => value.toEJson();
  static PartsMaster _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'id': EJsonValue id} => PartsMaster(
        fromEJson(id),
        name: fromEJson(ejson['name']),
      ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(PartsMaster._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      PartsMaster,
      'class_partsMaster',
      [
        SchemaProperty('id', RealmPropertyType.int, primaryKey: true),
        SchemaProperty('name', RealmPropertyType.string, optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
