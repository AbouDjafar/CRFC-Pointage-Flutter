// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StateRecordsTable extends StateRecords
    with TableInfo<$StateRecordsTable, StateRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StateRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'state_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StateRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  StateRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StateRecord(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $StateRecordsTable createAlias(String alias) {
    return $StateRecordsTable(attachedDatabase, alias);
  }
}

class StateRecord extends DataClass implements Insertable<StateRecord> {
  final String key;
  final String json;
  const StateRecord({required this.key, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['json'] = Variable<String>(json);
    return map;
  }

  StateRecordsCompanion toCompanion(bool nullToAbsent) {
    return StateRecordsCompanion(key: Value(key), json: Value(json));
  }

  factory StateRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StateRecord(
      key: serializer.fromJson<String>(json['key']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'json': serializer.toJson<String>(json),
    };
  }

  StateRecord copyWith({String? key, String? json}) =>
      StateRecord(key: key ?? this.key, json: json ?? this.json);
  StateRecord copyWithCompanion(StateRecordsCompanion data) {
    return StateRecord(
      key: data.key.present ? data.key.value : this.key,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StateRecord(')
          ..write('key: $key, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StateRecord &&
          other.key == this.key &&
          other.json == this.json);
}

class StateRecordsCompanion extends UpdateCompanion<StateRecord> {
  final Value<String> key;
  final Value<String> json;
  final Value<int> rowid;
  const StateRecordsCompanion({
    this.key = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StateRecordsCompanion.insert({
    required String key,
    required String json,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       json = Value(json);
  static Insertable<StateRecord> custom({
    Expression<String>? key,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StateRecordsCompanion copyWith({
    Value<String>? key,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return StateRecordsCompanion(
      key: key ?? this.key,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StateRecordsCompanion(')
          ..write('key: $key, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StateRecordsTable stateRecords = $StateRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [stateRecords];
}

typedef $$StateRecordsTableCreateCompanionBuilder =
    StateRecordsCompanion Function({
      required String key,
      required String json,
      Value<int> rowid,
    });
typedef $$StateRecordsTableUpdateCompanionBuilder =
    StateRecordsCompanion Function({
      Value<String> key,
      Value<String> json,
      Value<int> rowid,
    });

class $$StateRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $StateRecordsTable> {
  $$StateRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StateRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $StateRecordsTable> {
  $$StateRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StateRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StateRecordsTable> {
  $$StateRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$StateRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StateRecordsTable,
          StateRecord,
          $$StateRecordsTableFilterComposer,
          $$StateRecordsTableOrderingComposer,
          $$StateRecordsTableAnnotationComposer,
          $$StateRecordsTableCreateCompanionBuilder,
          $$StateRecordsTableUpdateCompanionBuilder,
          (
            StateRecord,
            BaseReferences<_$AppDatabase, $StateRecordsTable, StateRecord>,
          ),
          StateRecord,
          PrefetchHooks Function()
        > {
  $$StateRecordsTableTableManager(_$AppDatabase db, $StateRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StateRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StateRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StateRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StateRecordsCompanion(key: key, json: json, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => StateRecordsCompanion.insert(
                key: key,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StateRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StateRecordsTable,
      StateRecord,
      $$StateRecordsTableFilterComposer,
      $$StateRecordsTableOrderingComposer,
      $$StateRecordsTableAnnotationComposer,
      $$StateRecordsTableCreateCompanionBuilder,
      $$StateRecordsTableUpdateCompanionBuilder,
      (
        StateRecord,
        BaseReferences<_$AppDatabase, $StateRecordsTable, StateRecord>,
      ),
      StateRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StateRecordsTableTableManager get stateRecords =>
      $$StateRecordsTableTableManager(_db, _db.stateRecords);
}
