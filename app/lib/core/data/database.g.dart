// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SensorSamplesTable extends SensorSamples
    with TableInfo<$SensorSamplesTable, SensorSampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SensorSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valuesMeta = const VerificationMeta('values');
  @override
  late final GeneratedColumn<String> values = GeneratedColumn<String>(
    'values',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    sessionId,
    type,
    sourceId,
    values,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sensor_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<SensorSampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('values')) {
      context.handle(
        _valuesMeta,
        values.isAcceptableOrUnknown(data['values']!, _valuesMeta),
      );
    } else if (isInserting) {
      context.missing(_valuesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SensorSampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SensorSampleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      values: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}values'],
      )!,
    );
  }

  @override
  $SensorSamplesTable createAlias(String alias) {
    return $SensorSamplesTable(attachedDatabase, alias);
  }
}

class SensorSampleRow extends DataClass implements Insertable<SensorSampleRow> {
  final int id;
  final DateTime timestamp;
  final String sessionId;
  final String type;
  final String sourceId;
  final String values;
  const SensorSampleRow({
    required this.id,
    required this.timestamp,
    required this.sessionId,
    required this.type,
    required this.sourceId,
    required this.values,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['session_id'] = Variable<String>(sessionId);
    map['type'] = Variable<String>(type);
    map['source_id'] = Variable<String>(sourceId);
    map['values'] = Variable<String>(values);
    return map;
  }

  SensorSamplesCompanion toCompanion(bool nullToAbsent) {
    return SensorSamplesCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      sessionId: Value(sessionId),
      type: Value(type),
      sourceId: Value(sourceId),
      values: Value(values),
    );
  }

  factory SensorSampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SensorSampleRow(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      type: serializer.fromJson<String>(json['type']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      values: serializer.fromJson<String>(json['values']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'sessionId': serializer.toJson<String>(sessionId),
      'type': serializer.toJson<String>(type),
      'sourceId': serializer.toJson<String>(sourceId),
      'values': serializer.toJson<String>(values),
    };
  }

  SensorSampleRow copyWith({
    int? id,
    DateTime? timestamp,
    String? sessionId,
    String? type,
    String? sourceId,
    String? values,
  }) => SensorSampleRow(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    sessionId: sessionId ?? this.sessionId,
    type: type ?? this.type,
    sourceId: sourceId ?? this.sourceId,
    values: values ?? this.values,
  );
  SensorSampleRow copyWithCompanion(SensorSamplesCompanion data) {
    return SensorSampleRow(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      type: data.type.present ? data.type.value : this.type,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      values: data.values.present ? data.values.value : this.values,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SensorSampleRow(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('sessionId: $sessionId, ')
          ..write('type: $type, ')
          ..write('sourceId: $sourceId, ')
          ..write('values: $values')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, sessionId, type, sourceId, values);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SensorSampleRow &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.sessionId == this.sessionId &&
          other.type == this.type &&
          other.sourceId == this.sourceId &&
          other.values == this.values);
}

class SensorSamplesCompanion extends UpdateCompanion<SensorSampleRow> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String> sessionId;
  final Value<String> type;
  final Value<String> sourceId;
  final Value<String> values;
  const SensorSamplesCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.type = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.values = const Value.absent(),
  });
  SensorSamplesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required String sessionId,
    required String type,
    required String sourceId,
    required String values,
  }) : timestamp = Value(timestamp),
       sessionId = Value(sessionId),
       type = Value(type),
       sourceId = Value(sourceId),
       values = Value(values);
  static Insertable<SensorSampleRow> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? sessionId,
    Expression<String>? type,
    Expression<String>? sourceId,
    Expression<String>? values,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (sessionId != null) 'session_id': sessionId,
      if (type != null) 'type': type,
      if (sourceId != null) 'source_id': sourceId,
      if (values != null) 'values': values,
    });
  }

  SensorSamplesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String>? sessionId,
    Value<String>? type,
    Value<String>? sourceId,
    Value<String>? values,
  }) {
    return SensorSamplesCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      values: values ?? this.values,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (values.present) {
      map['values'] = Variable<String>(values.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SensorSamplesCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('sessionId: $sessionId, ')
          ..write('type: $type, ')
          ..write('sourceId: $sourceId, ')
          ..write('values: $values')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, timestamp, height, age];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    } else if (isInserting) {
      context.missing(_ageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String? name;
  final DateTime timestamp;
  final int height;
  final int age;
  const Profile({
    required this.id,
    this.name,
    required this.timestamp,
    required this.height,
    required this.age,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['height'] = Variable<int>(height);
    map['age'] = Variable<int>(age);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      timestamp: Value(timestamp),
      height: Value(height),
      age: Value(age),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      height: serializer.fromJson<int>(json['height']),
      age: serializer.fromJson<int>(json['age']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'height': serializer.toJson<int>(height),
      'age': serializer.toJson<int>(age),
    };
  }

  Profile copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
    DateTime? timestamp,
    int? height,
    int? age,
  }) => Profile(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    timestamp: timestamp ?? this.timestamp,
    height: height ?? this.height,
    age: age ?? this.age,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      height: data.height.present ? data.height.value : this.height,
      age: data.age.present ? data.age.value : this.age,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('timestamp: $timestamp, ')
          ..write('height: $height, ')
          ..write('age: $age')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, timestamp, height, age);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.timestamp == this.timestamp &&
          other.height == this.height &&
          other.age == this.age);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String?> name;
  final Value<DateTime> timestamp;
  final Value<int> height;
  final Value<int> age;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.height = const Value.absent(),
    this.age = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.timestamp = const Value.absent(),
    required int height,
    required int age,
  }) : height = Value(height),
       age = Value(age);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? timestamp,
    Expression<int>? height,
    Expression<int>? age,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (timestamp != null) 'timestamp': timestamp,
      if (height != null) 'height': height,
      if (age != null) 'age': age,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String?>? name,
    Value<DateTime>? timestamp,
    Value<int>? height,
    Value<int>? age,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      height: height ?? this.height,
      age: age ?? this.age,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('timestamp: $timestamp, ')
          ..write('height: $height, ')
          ..write('age: $age')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SensorSamplesTable sensorSamples = $SensorSamplesTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final Index sampleSessionId = Index(
    'sample_session_id',
    'CREATE INDEX sample_session_id ON sensor_samples (session_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sensorSamples,
    profiles,
    sampleSessionId,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SensorSamplesTableCreateCompanionBuilder =
    SensorSamplesCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      required String sessionId,
      required String type,
      required String sourceId,
      required String values,
    });
typedef $$SensorSamplesTableUpdateCompanionBuilder =
    SensorSamplesCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<String> sessionId,
      Value<String> type,
      Value<String> sourceId,
      Value<String> values,
    });

class $$SensorSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $SensorSamplesTable> {
  $$SensorSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get values => $composableBuilder(
    column: $table.values,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SensorSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $SensorSamplesTable> {
  $$SensorSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get values => $composableBuilder(
    column: $table.values,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SensorSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SensorSamplesTable> {
  $$SensorSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get values =>
      $composableBuilder(column: $table.values, builder: (column) => column);
}

class $$SensorSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SensorSamplesTable,
          SensorSampleRow,
          $$SensorSamplesTableFilterComposer,
          $$SensorSamplesTableOrderingComposer,
          $$SensorSamplesTableAnnotationComposer,
          $$SensorSamplesTableCreateCompanionBuilder,
          $$SensorSamplesTableUpdateCompanionBuilder,
          (
            SensorSampleRow,
            BaseReferences<_$AppDatabase, $SensorSamplesTable, SensorSampleRow>,
          ),
          SensorSampleRow,
          PrefetchHooks Function()
        > {
  $$SensorSamplesTableTableManager(_$AppDatabase db, $SensorSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SensorSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SensorSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SensorSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> values = const Value.absent(),
              }) => SensorSamplesCompanion(
                id: id,
                timestamp: timestamp,
                sessionId: sessionId,
                type: type,
                sourceId: sourceId,
                values: values,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required String sessionId,
                required String type,
                required String sourceId,
                required String values,
              }) => SensorSamplesCompanion.insert(
                id: id,
                timestamp: timestamp,
                sessionId: sessionId,
                type: type,
                sourceId: sourceId,
                values: values,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SensorSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SensorSamplesTable,
      SensorSampleRow,
      $$SensorSamplesTableFilterComposer,
      $$SensorSamplesTableOrderingComposer,
      $$SensorSamplesTableAnnotationComposer,
      $$SensorSamplesTableCreateCompanionBuilder,
      $$SensorSamplesTableUpdateCompanionBuilder,
      (
        SensorSampleRow,
        BaseReferences<_$AppDatabase, $SensorSamplesTable, SensorSampleRow>,
      ),
      SensorSampleRow,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<DateTime> timestamp,
      required int height,
      required int age,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<DateTime> timestamp,
      Value<int> height,
      Value<int> age,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> age = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                timestamp: timestamp,
                height: height,
                age: age,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                required int height,
                required int age,
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                timestamp: timestamp,
                height: height,
                age: age,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SensorSamplesTableTableManager get sensorSamples =>
      $$SensorSamplesTableTableManager(_db, _db.sensorSamples);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
}
