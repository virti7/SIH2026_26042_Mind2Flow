// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TeachersTable extends Teachers
    with TableInfo<$TeachersTable, TeacherData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeachersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schoolMeta = const VerificationMeta('school');
  @override
  late final GeneratedColumn<String> school = GeneratedColumn<String>(
    'school',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _districtMeta = const VerificationMeta(
    'district',
  );
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
    'district',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classesTaughtJsonMeta = const VerificationMeta(
    'classesTaughtJson',
  );
  @override
  late final GeneratedColumn<String> classesTaughtJson =
      GeneratedColumn<String>(
        'classes_taught_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _teachingLanguageMeta = const VerificationMeta(
    'teachingLanguage',
  );
  @override
  late final GeneratedColumn<String> teachingLanguage = GeneratedColumn<String>(
    'teaching_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supportedLanguagesJsonMeta =
      const VerificationMeta('supportedLanguagesJson');
  @override
  late final GeneratedColumn<String> supportedLanguagesJson =
      GeneratedColumn<String>(
        'supported_languages_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _activeSessionLanguageMeta =
      const VerificationMeta('activeSessionLanguage');
  @override
  late final GeneratedColumn<String> activeSessionLanguage =
      GeneratedColumn<String>(
        'active_session_language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    school,
    district,
    state,
    classesTaughtJson,
    teachingLanguage,
    supportedLanguagesJson,
    activeSessionLanguage,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teachers';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeacherData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('school')) {
      context.handle(
        _schoolMeta,
        school.isAcceptableOrUnknown(data['school']!, _schoolMeta),
      );
    } else if (isInserting) {
      context.missing(_schoolMeta);
    }
    if (data.containsKey('district')) {
      context.handle(
        _districtMeta,
        district.isAcceptableOrUnknown(data['district']!, _districtMeta),
      );
    } else if (isInserting) {
      context.missing(_districtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('classes_taught_json')) {
      context.handle(
        _classesTaughtJsonMeta,
        classesTaughtJson.isAcceptableOrUnknown(
          data['classes_taught_json']!,
          _classesTaughtJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classesTaughtJsonMeta);
    }
    if (data.containsKey('teaching_language')) {
      context.handle(
        _teachingLanguageMeta,
        teachingLanguage.isAcceptableOrUnknown(
          data['teaching_language']!,
          _teachingLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_teachingLanguageMeta);
    }
    if (data.containsKey('supported_languages_json')) {
      context.handle(
        _supportedLanguagesJsonMeta,
        supportedLanguagesJson.isAcceptableOrUnknown(
          data['supported_languages_json']!,
          _supportedLanguagesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_supportedLanguagesJsonMeta);
    }
    if (data.containsKey('active_session_language')) {
      context.handle(
        _activeSessionLanguageMeta,
        activeSessionLanguage.isAcceptableOrUnknown(
          data['active_session_language']!,
          _activeSessionLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activeSessionLanguageMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeacherData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeacherData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      school: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school'],
      )!,
      district: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      classesTaughtJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classes_taught_json'],
      )!,
      teachingLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teaching_language'],
      )!,
      supportedLanguagesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supported_languages_json'],
      )!,
      activeSessionLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_session_language'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TeachersTable createAlias(String alias) {
    return $TeachersTable(attachedDatabase, alias);
  }
}

class TeacherData extends DataClass implements Insertable<TeacherData> {
  final String id;
  final String name;
  final String school;
  final String district;
  final String state;
  final String classesTaughtJson;
  final String teachingLanguage;
  final String supportedLanguagesJson;
  final String activeSessionLanguage;
  final DateTime updatedAt;
  const TeacherData({
    required this.id,
    required this.name,
    required this.school,
    required this.district,
    required this.state,
    required this.classesTaughtJson,
    required this.teachingLanguage,
    required this.supportedLanguagesJson,
    required this.activeSessionLanguage,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['school'] = Variable<String>(school);
    map['district'] = Variable<String>(district);
    map['state'] = Variable<String>(state);
    map['classes_taught_json'] = Variable<String>(classesTaughtJson);
    map['teaching_language'] = Variable<String>(teachingLanguage);
    map['supported_languages_json'] = Variable<String>(supportedLanguagesJson);
    map['active_session_language'] = Variable<String>(activeSessionLanguage);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TeachersCompanion toCompanion(bool nullToAbsent) {
    return TeachersCompanion(
      id: Value(id),
      name: Value(name),
      school: Value(school),
      district: Value(district),
      state: Value(state),
      classesTaughtJson: Value(classesTaughtJson),
      teachingLanguage: Value(teachingLanguage),
      supportedLanguagesJson: Value(supportedLanguagesJson),
      activeSessionLanguage: Value(activeSessionLanguage),
      updatedAt: Value(updatedAt),
    );
  }

  factory TeacherData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeacherData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      school: serializer.fromJson<String>(json['school']),
      district: serializer.fromJson<String>(json['district']),
      state: serializer.fromJson<String>(json['state']),
      classesTaughtJson: serializer.fromJson<String>(json['classesTaughtJson']),
      teachingLanguage: serializer.fromJson<String>(json['teachingLanguage']),
      supportedLanguagesJson: serializer.fromJson<String>(
        json['supportedLanguagesJson'],
      ),
      activeSessionLanguage: serializer.fromJson<String>(
        json['activeSessionLanguage'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'school': serializer.toJson<String>(school),
      'district': serializer.toJson<String>(district),
      'state': serializer.toJson<String>(state),
      'classesTaughtJson': serializer.toJson<String>(classesTaughtJson),
      'teachingLanguage': serializer.toJson<String>(teachingLanguage),
      'supportedLanguagesJson': serializer.toJson<String>(
        supportedLanguagesJson,
      ),
      'activeSessionLanguage': serializer.toJson<String>(activeSessionLanguage),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TeacherData copyWith({
    String? id,
    String? name,
    String? school,
    String? district,
    String? state,
    String? classesTaughtJson,
    String? teachingLanguage,
    String? supportedLanguagesJson,
    String? activeSessionLanguage,
    DateTime? updatedAt,
  }) => TeacherData(
    id: id ?? this.id,
    name: name ?? this.name,
    school: school ?? this.school,
    district: district ?? this.district,
    state: state ?? this.state,
    classesTaughtJson: classesTaughtJson ?? this.classesTaughtJson,
    teachingLanguage: teachingLanguage ?? this.teachingLanguage,
    supportedLanguagesJson:
        supportedLanguagesJson ?? this.supportedLanguagesJson,
    activeSessionLanguage: activeSessionLanguage ?? this.activeSessionLanguage,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TeacherData copyWithCompanion(TeachersCompanion data) {
    return TeacherData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      school: data.school.present ? data.school.value : this.school,
      district: data.district.present ? data.district.value : this.district,
      state: data.state.present ? data.state.value : this.state,
      classesTaughtJson: data.classesTaughtJson.present
          ? data.classesTaughtJson.value
          : this.classesTaughtJson,
      teachingLanguage: data.teachingLanguage.present
          ? data.teachingLanguage.value
          : this.teachingLanguage,
      supportedLanguagesJson: data.supportedLanguagesJson.present
          ? data.supportedLanguagesJson.value
          : this.supportedLanguagesJson,
      activeSessionLanguage: data.activeSessionLanguage.present
          ? data.activeSessionLanguage.value
          : this.activeSessionLanguage,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeacherData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('school: $school, ')
          ..write('district: $district, ')
          ..write('state: $state, ')
          ..write('classesTaughtJson: $classesTaughtJson, ')
          ..write('teachingLanguage: $teachingLanguage, ')
          ..write('supportedLanguagesJson: $supportedLanguagesJson, ')
          ..write('activeSessionLanguage: $activeSessionLanguage, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    school,
    district,
    state,
    classesTaughtJson,
    teachingLanguage,
    supportedLanguagesJson,
    activeSessionLanguage,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeacherData &&
          other.id == this.id &&
          other.name == this.name &&
          other.school == this.school &&
          other.district == this.district &&
          other.state == this.state &&
          other.classesTaughtJson == this.classesTaughtJson &&
          other.teachingLanguage == this.teachingLanguage &&
          other.supportedLanguagesJson == this.supportedLanguagesJson &&
          other.activeSessionLanguage == this.activeSessionLanguage &&
          other.updatedAt == this.updatedAt);
}

class TeachersCompanion extends UpdateCompanion<TeacherData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> school;
  final Value<String> district;
  final Value<String> state;
  final Value<String> classesTaughtJson;
  final Value<String> teachingLanguage;
  final Value<String> supportedLanguagesJson;
  final Value<String> activeSessionLanguage;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TeachersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.school = const Value.absent(),
    this.district = const Value.absent(),
    this.state = const Value.absent(),
    this.classesTaughtJson = const Value.absent(),
    this.teachingLanguage = const Value.absent(),
    this.supportedLanguagesJson = const Value.absent(),
    this.activeSessionLanguage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeachersCompanion.insert({
    required String id,
    required String name,
    required String school,
    required String district,
    required String state,
    required String classesTaughtJson,
    required String teachingLanguage,
    required String supportedLanguagesJson,
    required String activeSessionLanguage,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       school = Value(school),
       district = Value(district),
       state = Value(state),
       classesTaughtJson = Value(classesTaughtJson),
       teachingLanguage = Value(teachingLanguage),
       supportedLanguagesJson = Value(supportedLanguagesJson),
       activeSessionLanguage = Value(activeSessionLanguage),
       updatedAt = Value(updatedAt);
  static Insertable<TeacherData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? school,
    Expression<String>? district,
    Expression<String>? state,
    Expression<String>? classesTaughtJson,
    Expression<String>? teachingLanguage,
    Expression<String>? supportedLanguagesJson,
    Expression<String>? activeSessionLanguage,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (school != null) 'school': school,
      if (district != null) 'district': district,
      if (state != null) 'state': state,
      if (classesTaughtJson != null) 'classes_taught_json': classesTaughtJson,
      if (teachingLanguage != null) 'teaching_language': teachingLanguage,
      if (supportedLanguagesJson != null)
        'supported_languages_json': supportedLanguagesJson,
      if (activeSessionLanguage != null)
        'active_session_language': activeSessionLanguage,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeachersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? school,
    Value<String>? district,
    Value<String>? state,
    Value<String>? classesTaughtJson,
    Value<String>? teachingLanguage,
    Value<String>? supportedLanguagesJson,
    Value<String>? activeSessionLanguage,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TeachersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      school: school ?? this.school,
      district: district ?? this.district,
      state: state ?? this.state,
      classesTaughtJson: classesTaughtJson ?? this.classesTaughtJson,
      teachingLanguage: teachingLanguage ?? this.teachingLanguage,
      supportedLanguagesJson:
          supportedLanguagesJson ?? this.supportedLanguagesJson,
      activeSessionLanguage:
          activeSessionLanguage ?? this.activeSessionLanguage,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (school.present) {
      map['school'] = Variable<String>(school.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (classesTaughtJson.present) {
      map['classes_taught_json'] = Variable<String>(classesTaughtJson.value);
    }
    if (teachingLanguage.present) {
      map['teaching_language'] = Variable<String>(teachingLanguage.value);
    }
    if (supportedLanguagesJson.present) {
      map['supported_languages_json'] = Variable<String>(
        supportedLanguagesJson.value,
      );
    }
    if (activeSessionLanguage.present) {
      map['active_session_language'] = Variable<String>(
        activeSessionLanguage.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeachersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('school: $school, ')
          ..write('district: $district, ')
          ..write('state: $state, ')
          ..write('classesTaughtJson: $classesTaughtJson, ')
          ..write('teachingLanguage: $teachingLanguage, ')
          ..write('supportedLanguagesJson: $supportedLanguagesJson, ')
          ..write('activeSessionLanguage: $activeSessionLanguage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassroomsTable extends Classrooms
    with TableInfo<$ClassroomsTable, ClassroomData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassroomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('A'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, grade, name, section, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classrooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassroomData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassroomData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassroomData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $ClassroomsTable createAlias(String alias) {
    return $ClassroomsTable(attachedDatabase, alias);
  }
}

class ClassroomData extends DataClass implements Insertable<ClassroomData> {
  final String id;
  final int grade;
  final String name;
  final String section;
  final bool isActive;
  const ClassroomData({
    required this.id,
    required this.grade,
    required this.name,
    required this.section,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['grade'] = Variable<int>(grade);
    map['name'] = Variable<String>(name);
    map['section'] = Variable<String>(section);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ClassroomsCompanion toCompanion(bool nullToAbsent) {
    return ClassroomsCompanion(
      id: Value(id),
      grade: Value(grade),
      name: Value(name),
      section: Value(section),
      isActive: Value(isActive),
    );
  }

  factory ClassroomData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassroomData(
      id: serializer.fromJson<String>(json['id']),
      grade: serializer.fromJson<int>(json['grade']),
      name: serializer.fromJson<String>(json['name']),
      section: serializer.fromJson<String>(json['section']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'grade': serializer.toJson<int>(grade),
      'name': serializer.toJson<String>(name),
      'section': serializer.toJson<String>(section),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  ClassroomData copyWith({
    String? id,
    int? grade,
    String? name,
    String? section,
    bool? isActive,
  }) => ClassroomData(
    id: id ?? this.id,
    grade: grade ?? this.grade,
    name: name ?? this.name,
    section: section ?? this.section,
    isActive: isActive ?? this.isActive,
  );
  ClassroomData copyWithCompanion(ClassroomsCompanion data) {
    return ClassroomData(
      id: data.id.present ? data.id.value : this.id,
      grade: data.grade.present ? data.grade.value : this.grade,
      name: data.name.present ? data.name.value : this.name,
      section: data.section.present ? data.section.value : this.section,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassroomData(')
          ..write('id: $id, ')
          ..write('grade: $grade, ')
          ..write('name: $name, ')
          ..write('section: $section, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, grade, name, section, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassroomData &&
          other.id == this.id &&
          other.grade == this.grade &&
          other.name == this.name &&
          other.section == this.section &&
          other.isActive == this.isActive);
}

class ClassroomsCompanion extends UpdateCompanion<ClassroomData> {
  final Value<String> id;
  final Value<int> grade;
  final Value<String> name;
  final Value<String> section;
  final Value<bool> isActive;
  final Value<int> rowid;
  const ClassroomsCompanion({
    this.id = const Value.absent(),
    this.grade = const Value.absent(),
    this.name = const Value.absent(),
    this.section = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassroomsCompanion.insert({
    required String id,
    required int grade,
    required String name,
    this.section = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       grade = Value(grade),
       name = Value(name);
  static Insertable<ClassroomData> custom({
    Expression<String>? id,
    Expression<int>? grade,
    Expression<String>? name,
    Expression<String>? section,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (grade != null) 'grade': grade,
      if (name != null) 'name': name,
      if (section != null) 'section': section,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassroomsCompanion copyWith({
    Value<String>? id,
    Value<int>? grade,
    Value<String>? name,
    Value<String>? section,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return ClassroomsCompanion(
      id: id ?? this.id,
      grade: grade ?? this.grade,
      name: name ?? this.name,
      section: section ?? this.section,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassroomsCompanion(')
          ..write('id: $id, ')
          ..write('grade: $grade, ')
          ..write('name: $name, ')
          ..write('section: $section, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NipunOutcomesTable extends NipunOutcomes
    with TableInfo<$NipunOutcomesTable, NipunOutcomeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NipunOutcomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _competencyMeta = const VerificationMeta(
    'competency',
  );
  @override
  late final GeneratedColumn<String> competency = GeneratedColumn<String>(
    'competency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleEnMeta = const VerificationMeta(
    'titleEn',
  );
  @override
  late final GeneratedColumn<String> titleEn = GeneratedColumn<String>(
    'title_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleHiMeta = const VerificationMeta(
    'titleHi',
  );
  @override
  late final GeneratedColumn<String> titleHi = GeneratedColumn<String>(
    'title_hi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDescriptionMeta = const VerificationMeta(
    'targetDescription',
  );
  @override
  late final GeneratedColumn<String> targetDescription =
      GeneratedColumn<String>(
        'target_description',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _defaultStatusMeta = const VerificationMeta(
    'defaultStatus',
  );
  @override
  late final GeneratedColumn<String> defaultStatus = GeneratedColumn<String>(
    'default_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unfinishedSkillMeta = const VerificationMeta(
    'unfinishedSkill',
  );
  @override
  late final GeneratedColumn<String> unfinishedSkill = GeneratedColumn<String>(
    'unfinished_skill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    grade,
    domain,
    competency,
    titleEn,
    titleHi,
    targetDescription,
    defaultStatus,
    unfinishedSkill,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nipun_outcomes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NipunOutcomeData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('competency')) {
      context.handle(
        _competencyMeta,
        competency.isAcceptableOrUnknown(data['competency']!, _competencyMeta),
      );
    } else if (isInserting) {
      context.missing(_competencyMeta);
    }
    if (data.containsKey('title_en')) {
      context.handle(
        _titleEnMeta,
        titleEn.isAcceptableOrUnknown(data['title_en']!, _titleEnMeta),
      );
    } else if (isInserting) {
      context.missing(_titleEnMeta);
    }
    if (data.containsKey('title_hi')) {
      context.handle(
        _titleHiMeta,
        titleHi.isAcceptableOrUnknown(data['title_hi']!, _titleHiMeta),
      );
    } else if (isInserting) {
      context.missing(_titleHiMeta);
    }
    if (data.containsKey('target_description')) {
      context.handle(
        _targetDescriptionMeta,
        targetDescription.isAcceptableOrUnknown(
          data['target_description']!,
          _targetDescriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetDescriptionMeta);
    }
    if (data.containsKey('default_status')) {
      context.handle(
        _defaultStatusMeta,
        defaultStatus.isAcceptableOrUnknown(
          data['default_status']!,
          _defaultStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultStatusMeta);
    }
    if (data.containsKey('unfinished_skill')) {
      context.handle(
        _unfinishedSkillMeta,
        unfinishedSkill.isAcceptableOrUnknown(
          data['unfinished_skill']!,
          _unfinishedSkillMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unfinishedSkillMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NipunOutcomeData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NipunOutcomeData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      competency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competency'],
      )!,
      titleEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_en'],
      )!,
      titleHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_hi'],
      )!,
      targetDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_description'],
      )!,
      defaultStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_status'],
      )!,
      unfinishedSkill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unfinished_skill'],
      )!,
    );
  }

  @override
  $NipunOutcomesTable createAlias(String alias) {
    return $NipunOutcomesTable(attachedDatabase, alias);
  }
}

class NipunOutcomeData extends DataClass
    implements Insertable<NipunOutcomeData> {
  final String id;
  final String code;
  final int grade;
  final String domain;
  final String competency;
  final String titleEn;
  final String titleHi;
  final String targetDescription;
  final String defaultStatus;
  final String unfinishedSkill;
  const NipunOutcomeData({
    required this.id,
    required this.code,
    required this.grade,
    required this.domain,
    required this.competency,
    required this.titleEn,
    required this.titleHi,
    required this.targetDescription,
    required this.defaultStatus,
    required this.unfinishedSkill,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['grade'] = Variable<int>(grade);
    map['domain'] = Variable<String>(domain);
    map['competency'] = Variable<String>(competency);
    map['title_en'] = Variable<String>(titleEn);
    map['title_hi'] = Variable<String>(titleHi);
    map['target_description'] = Variable<String>(targetDescription);
    map['default_status'] = Variable<String>(defaultStatus);
    map['unfinished_skill'] = Variable<String>(unfinishedSkill);
    return map;
  }

  NipunOutcomesCompanion toCompanion(bool nullToAbsent) {
    return NipunOutcomesCompanion(
      id: Value(id),
      code: Value(code),
      grade: Value(grade),
      domain: Value(domain),
      competency: Value(competency),
      titleEn: Value(titleEn),
      titleHi: Value(titleHi),
      targetDescription: Value(targetDescription),
      defaultStatus: Value(defaultStatus),
      unfinishedSkill: Value(unfinishedSkill),
    );
  }

  factory NipunOutcomeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NipunOutcomeData(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      grade: serializer.fromJson<int>(json['grade']),
      domain: serializer.fromJson<String>(json['domain']),
      competency: serializer.fromJson<String>(json['competency']),
      titleEn: serializer.fromJson<String>(json['titleEn']),
      titleHi: serializer.fromJson<String>(json['titleHi']),
      targetDescription: serializer.fromJson<String>(json['targetDescription']),
      defaultStatus: serializer.fromJson<String>(json['defaultStatus']),
      unfinishedSkill: serializer.fromJson<String>(json['unfinishedSkill']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'grade': serializer.toJson<int>(grade),
      'domain': serializer.toJson<String>(domain),
      'competency': serializer.toJson<String>(competency),
      'titleEn': serializer.toJson<String>(titleEn),
      'titleHi': serializer.toJson<String>(titleHi),
      'targetDescription': serializer.toJson<String>(targetDescription),
      'defaultStatus': serializer.toJson<String>(defaultStatus),
      'unfinishedSkill': serializer.toJson<String>(unfinishedSkill),
    };
  }

  NipunOutcomeData copyWith({
    String? id,
    String? code,
    int? grade,
    String? domain,
    String? competency,
    String? titleEn,
    String? titleHi,
    String? targetDescription,
    String? defaultStatus,
    String? unfinishedSkill,
  }) => NipunOutcomeData(
    id: id ?? this.id,
    code: code ?? this.code,
    grade: grade ?? this.grade,
    domain: domain ?? this.domain,
    competency: competency ?? this.competency,
    titleEn: titleEn ?? this.titleEn,
    titleHi: titleHi ?? this.titleHi,
    targetDescription: targetDescription ?? this.targetDescription,
    defaultStatus: defaultStatus ?? this.defaultStatus,
    unfinishedSkill: unfinishedSkill ?? this.unfinishedSkill,
  );
  NipunOutcomeData copyWithCompanion(NipunOutcomesCompanion data) {
    return NipunOutcomeData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      grade: data.grade.present ? data.grade.value : this.grade,
      domain: data.domain.present ? data.domain.value : this.domain,
      competency: data.competency.present
          ? data.competency.value
          : this.competency,
      titleEn: data.titleEn.present ? data.titleEn.value : this.titleEn,
      titleHi: data.titleHi.present ? data.titleHi.value : this.titleHi,
      targetDescription: data.targetDescription.present
          ? data.targetDescription.value
          : this.targetDescription,
      defaultStatus: data.defaultStatus.present
          ? data.defaultStatus.value
          : this.defaultStatus,
      unfinishedSkill: data.unfinishedSkill.present
          ? data.unfinishedSkill.value
          : this.unfinishedSkill,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NipunOutcomeData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('grade: $grade, ')
          ..write('domain: $domain, ')
          ..write('competency: $competency, ')
          ..write('titleEn: $titleEn, ')
          ..write('titleHi: $titleHi, ')
          ..write('targetDescription: $targetDescription, ')
          ..write('defaultStatus: $defaultStatus, ')
          ..write('unfinishedSkill: $unfinishedSkill')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    grade,
    domain,
    competency,
    titleEn,
    titleHi,
    targetDescription,
    defaultStatus,
    unfinishedSkill,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NipunOutcomeData &&
          other.id == this.id &&
          other.code == this.code &&
          other.grade == this.grade &&
          other.domain == this.domain &&
          other.competency == this.competency &&
          other.titleEn == this.titleEn &&
          other.titleHi == this.titleHi &&
          other.targetDescription == this.targetDescription &&
          other.defaultStatus == this.defaultStatus &&
          other.unfinishedSkill == this.unfinishedSkill);
}

class NipunOutcomesCompanion extends UpdateCompanion<NipunOutcomeData> {
  final Value<String> id;
  final Value<String> code;
  final Value<int> grade;
  final Value<String> domain;
  final Value<String> competency;
  final Value<String> titleEn;
  final Value<String> titleHi;
  final Value<String> targetDescription;
  final Value<String> defaultStatus;
  final Value<String> unfinishedSkill;
  final Value<int> rowid;
  const NipunOutcomesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.grade = const Value.absent(),
    this.domain = const Value.absent(),
    this.competency = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.titleHi = const Value.absent(),
    this.targetDescription = const Value.absent(),
    this.defaultStatus = const Value.absent(),
    this.unfinishedSkill = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NipunOutcomesCompanion.insert({
    required String id,
    required String code,
    required int grade,
    required String domain,
    required String competency,
    required String titleEn,
    required String titleHi,
    required String targetDescription,
    required String defaultStatus,
    required String unfinishedSkill,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       grade = Value(grade),
       domain = Value(domain),
       competency = Value(competency),
       titleEn = Value(titleEn),
       titleHi = Value(titleHi),
       targetDescription = Value(targetDescription),
       defaultStatus = Value(defaultStatus),
       unfinishedSkill = Value(unfinishedSkill);
  static Insertable<NipunOutcomeData> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<int>? grade,
    Expression<String>? domain,
    Expression<String>? competency,
    Expression<String>? titleEn,
    Expression<String>? titleHi,
    Expression<String>? targetDescription,
    Expression<String>? defaultStatus,
    Expression<String>? unfinishedSkill,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (grade != null) 'grade': grade,
      if (domain != null) 'domain': domain,
      if (competency != null) 'competency': competency,
      if (titleEn != null) 'title_en': titleEn,
      if (titleHi != null) 'title_hi': titleHi,
      if (targetDescription != null) 'target_description': targetDescription,
      if (defaultStatus != null) 'default_status': defaultStatus,
      if (unfinishedSkill != null) 'unfinished_skill': unfinishedSkill,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NipunOutcomesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<int>? grade,
    Value<String>? domain,
    Value<String>? competency,
    Value<String>? titleEn,
    Value<String>? titleHi,
    Value<String>? targetDescription,
    Value<String>? defaultStatus,
    Value<String>? unfinishedSkill,
    Value<int>? rowid,
  }) {
    return NipunOutcomesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      grade: grade ?? this.grade,
      domain: domain ?? this.domain,
      competency: competency ?? this.competency,
      titleEn: titleEn ?? this.titleEn,
      titleHi: titleHi ?? this.titleHi,
      targetDescription: targetDescription ?? this.targetDescription,
      defaultStatus: defaultStatus ?? this.defaultStatus,
      unfinishedSkill: unfinishedSkill ?? this.unfinishedSkill,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (competency.present) {
      map['competency'] = Variable<String>(competency.value);
    }
    if (titleEn.present) {
      map['title_en'] = Variable<String>(titleEn.value);
    }
    if (titleHi.present) {
      map['title_hi'] = Variable<String>(titleHi.value);
    }
    if (targetDescription.present) {
      map['target_description'] = Variable<String>(targetDescription.value);
    }
    if (defaultStatus.present) {
      map['default_status'] = Variable<String>(defaultStatus.value);
    }
    if (unfinishedSkill.present) {
      map['unfinished_skill'] = Variable<String>(unfinishedSkill.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NipunOutcomesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('grade: $grade, ')
          ..write('domain: $domain, ')
          ..write('competency: $competency, ')
          ..write('titleEn: $titleEn, ')
          ..write('titleHi: $titleHi, ')
          ..write('targetDescription: $targetDescription, ')
          ..write('defaultStatus: $defaultStatus, ')
          ..write('unfinishedSkill: $unfinishedSkill, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonsTable extends Lessons with TableInfo<$LessonsTable, LessonData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleHiMeta = const VerificationMeta(
    'titleHi',
  );
  @override
  late final GeneratedColumn<String> titleHi = GeneratedColumn<String>(
    'title_hi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeCodeMeta = const VerificationMeta(
    'outcomeCode',
  );
  @override
  late final GeneratedColumn<String> outcomeCode = GeneratedColumn<String>(
    'outcome_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeTitleMeta = const VerificationMeta(
    'outcomeTitle',
  );
  @override
  late final GeneratedColumn<String> outcomeTitle = GeneratedColumn<String>(
    'outcome_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learningObjectiveMeta = const VerificationMeta(
    'learningObjective',
  );
  @override
  late final GeneratedColumn<String> learningObjective =
      GeneratedColumn<String>(
        'learning_objective',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _prerequisiteKnowledgeMeta =
      const VerificationMeta('prerequisiteKnowledge');
  @override
  late final GeneratedColumn<String> prerequisiteKnowledge =
      GeneratedColumn<String>(
        'prerequisite_knowledge',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _teacherMovesMeta = const VerificationMeta(
    'teacherMoves',
  );
  @override
  late final GeneratedColumn<String> teacherMoves = GeneratedColumn<String>(
    'teacher_moves',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityOverviewMeta = const VerificationMeta(
    'activityOverview',
  );
  @override
  late final GeneratedColumn<String> activityOverview = GeneratedColumn<String>(
    'activity_overview',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assessmentStrategyMeta =
      const VerificationMeta('assessmentStrategy');
  @override
  late final GeneratedColumn<String> assessmentStrategy =
      GeneratedColumn<String>(
        'assessment_strategy',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _remediationOptionMeta = const VerificationMeta(
    'remediationOption',
  );
  @override
  late final GeneratedColumn<String> remediationOption =
      GeneratedColumn<String>(
        'remediation_option',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _tribalVocabularyJsonMeta =
      const VerificationMeta('tribalVocabularyJson');
  @override
  late final GeneratedColumn<String> tribalVocabularyJson =
      GeneratedColumn<String>(
        'tribal_vocabulary_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _requiredMaterialsJsonMeta =
      const VerificationMeta('requiredMaterialsJson');
  @override
  late final GeneratedColumn<String> requiredMaterialsJson =
      GeneratedColumn<String>(
        'required_materials_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _stepsJsonMeta = const VerificationMeta(
    'stepsJson',
  );
  @override
  late final GeneratedColumn<String> stepsJson = GeneratedColumn<String>(
    'steps_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    titleHi,
    outcomeCode,
    outcomeTitle,
    grade,
    subject,
    durationMinutes,
    learningObjective,
    prerequisiteKnowledge,
    teacherMoves,
    activityOverview,
    assessmentStrategy,
    remediationOption,
    tribalVocabularyJson,
    requiredMaterialsJson,
    stepsJson,
    createdAt,
    updatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lessons';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_hi')) {
      context.handle(
        _titleHiMeta,
        titleHi.isAcceptableOrUnknown(data['title_hi']!, _titleHiMeta),
      );
    } else if (isInserting) {
      context.missing(_titleHiMeta);
    }
    if (data.containsKey('outcome_code')) {
      context.handle(
        _outcomeCodeMeta,
        outcomeCode.isAcceptableOrUnknown(
          data['outcome_code']!,
          _outcomeCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outcomeCodeMeta);
    }
    if (data.containsKey('outcome_title')) {
      context.handle(
        _outcomeTitleMeta,
        outcomeTitle.isAcceptableOrUnknown(
          data['outcome_title']!,
          _outcomeTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outcomeTitleMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('learning_objective')) {
      context.handle(
        _learningObjectiveMeta,
        learningObjective.isAcceptableOrUnknown(
          data['learning_objective']!,
          _learningObjectiveMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learningObjectiveMeta);
    }
    if (data.containsKey('prerequisite_knowledge')) {
      context.handle(
        _prerequisiteKnowledgeMeta,
        prerequisiteKnowledge.isAcceptableOrUnknown(
          data['prerequisite_knowledge']!,
          _prerequisiteKnowledgeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prerequisiteKnowledgeMeta);
    }
    if (data.containsKey('teacher_moves')) {
      context.handle(
        _teacherMovesMeta,
        teacherMoves.isAcceptableOrUnknown(
          data['teacher_moves']!,
          _teacherMovesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_teacherMovesMeta);
    }
    if (data.containsKey('activity_overview')) {
      context.handle(
        _activityOverviewMeta,
        activityOverview.isAcceptableOrUnknown(
          data['activity_overview']!,
          _activityOverviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityOverviewMeta);
    }
    if (data.containsKey('assessment_strategy')) {
      context.handle(
        _assessmentStrategyMeta,
        assessmentStrategy.isAcceptableOrUnknown(
          data['assessment_strategy']!,
          _assessmentStrategyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assessmentStrategyMeta);
    }
    if (data.containsKey('remediation_option')) {
      context.handle(
        _remediationOptionMeta,
        remediationOption.isAcceptableOrUnknown(
          data['remediation_option']!,
          _remediationOptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remediationOptionMeta);
    }
    if (data.containsKey('tribal_vocabulary_json')) {
      context.handle(
        _tribalVocabularyJsonMeta,
        tribalVocabularyJson.isAcceptableOrUnknown(
          data['tribal_vocabulary_json']!,
          _tribalVocabularyJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tribalVocabularyJsonMeta);
    }
    if (data.containsKey('required_materials_json')) {
      context.handle(
        _requiredMaterialsJsonMeta,
        requiredMaterialsJson.isAcceptableOrUnknown(
          data['required_materials_json']!,
          _requiredMaterialsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requiredMaterialsJsonMeta);
    }
    if (data.containsKey('steps_json')) {
      context.handle(
        _stepsJsonMeta,
        stepsJson.isAcceptableOrUnknown(data['steps_json']!, _stepsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_hi'],
      )!,
      outcomeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_code'],
      )!,
      outcomeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_title'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      learningObjective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learning_objective'],
      )!,
      prerequisiteKnowledge: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prerequisite_knowledge'],
      )!,
      teacherMoves: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_moves'],
      )!,
      activityOverview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_overview'],
      )!,
      assessmentStrategy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assessment_strategy'],
      )!,
      remediationOption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remediation_option'],
      )!,
      tribalVocabularyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tribal_vocabulary_json'],
      )!,
      requiredMaterialsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}required_materials_json'],
      )!,
      stepsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}steps_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $LessonsTable createAlias(String alias) {
    return $LessonsTable(attachedDatabase, alias);
  }
}

class LessonData extends DataClass implements Insertable<LessonData> {
  final String id;
  final String title;
  final String titleHi;
  final String outcomeCode;
  final String outcomeTitle;
  final int grade;
  final String subject;
  final int durationMinutes;
  final String learningObjective;
  final String prerequisiteKnowledge;
  final String teacherMoves;
  final String activityOverview;
  final String assessmentStrategy;
  final String remediationOption;
  final String tribalVocabularyJson;
  final String requiredMaterialsJson;
  final String stepsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  const LessonData({
    required this.id,
    required this.title,
    required this.titleHi,
    required this.outcomeCode,
    required this.outcomeTitle,
    required this.grade,
    required this.subject,
    required this.durationMinutes,
    required this.learningObjective,
    required this.prerequisiteKnowledge,
    required this.teacherMoves,
    required this.activityOverview,
    required this.assessmentStrategy,
    required this.remediationOption,
    required this.tribalVocabularyJson,
    required this.requiredMaterialsJson,
    required this.stepsJson,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['title_hi'] = Variable<String>(titleHi);
    map['outcome_code'] = Variable<String>(outcomeCode);
    map['outcome_title'] = Variable<String>(outcomeTitle);
    map['grade'] = Variable<int>(grade);
    map['subject'] = Variable<String>(subject);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['learning_objective'] = Variable<String>(learningObjective);
    map['prerequisite_knowledge'] = Variable<String>(prerequisiteKnowledge);
    map['teacher_moves'] = Variable<String>(teacherMoves);
    map['activity_overview'] = Variable<String>(activityOverview);
    map['assessment_strategy'] = Variable<String>(assessmentStrategy);
    map['remediation_option'] = Variable<String>(remediationOption);
    map['tribal_vocabulary_json'] = Variable<String>(tribalVocabularyJson);
    map['required_materials_json'] = Variable<String>(requiredMaterialsJson);
    map['steps_json'] = Variable<String>(stepsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LessonsCompanion toCompanion(bool nullToAbsent) {
    return LessonsCompanion(
      id: Value(id),
      title: Value(title),
      titleHi: Value(titleHi),
      outcomeCode: Value(outcomeCode),
      outcomeTitle: Value(outcomeTitle),
      grade: Value(grade),
      subject: Value(subject),
      durationMinutes: Value(durationMinutes),
      learningObjective: Value(learningObjective),
      prerequisiteKnowledge: Value(prerequisiteKnowledge),
      teacherMoves: Value(teacherMoves),
      activityOverview: Value(activityOverview),
      assessmentStrategy: Value(assessmentStrategy),
      remediationOption: Value(remediationOption),
      tribalVocabularyJson: Value(tribalVocabularyJson),
      requiredMaterialsJson: Value(requiredMaterialsJson),
      stepsJson: Value(stepsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory LessonData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      titleHi: serializer.fromJson<String>(json['titleHi']),
      outcomeCode: serializer.fromJson<String>(json['outcomeCode']),
      outcomeTitle: serializer.fromJson<String>(json['outcomeTitle']),
      grade: serializer.fromJson<int>(json['grade']),
      subject: serializer.fromJson<String>(json['subject']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      learningObjective: serializer.fromJson<String>(json['learningObjective']),
      prerequisiteKnowledge: serializer.fromJson<String>(
        json['prerequisiteKnowledge'],
      ),
      teacherMoves: serializer.fromJson<String>(json['teacherMoves']),
      activityOverview: serializer.fromJson<String>(json['activityOverview']),
      assessmentStrategy: serializer.fromJson<String>(
        json['assessmentStrategy'],
      ),
      remediationOption: serializer.fromJson<String>(json['remediationOption']),
      tribalVocabularyJson: serializer.fromJson<String>(
        json['tribalVocabularyJson'],
      ),
      requiredMaterialsJson: serializer.fromJson<String>(
        json['requiredMaterialsJson'],
      ),
      stepsJson: serializer.fromJson<String>(json['stepsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'titleHi': serializer.toJson<String>(titleHi),
      'outcomeCode': serializer.toJson<String>(outcomeCode),
      'outcomeTitle': serializer.toJson<String>(outcomeTitle),
      'grade': serializer.toJson<int>(grade),
      'subject': serializer.toJson<String>(subject),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'learningObjective': serializer.toJson<String>(learningObjective),
      'prerequisiteKnowledge': serializer.toJson<String>(prerequisiteKnowledge),
      'teacherMoves': serializer.toJson<String>(teacherMoves),
      'activityOverview': serializer.toJson<String>(activityOverview),
      'assessmentStrategy': serializer.toJson<String>(assessmentStrategy),
      'remediationOption': serializer.toJson<String>(remediationOption),
      'tribalVocabularyJson': serializer.toJson<String>(tribalVocabularyJson),
      'requiredMaterialsJson': serializer.toJson<String>(requiredMaterialsJson),
      'stepsJson': serializer.toJson<String>(stepsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LessonData copyWith({
    String? id,
    String? title,
    String? titleHi,
    String? outcomeCode,
    String? outcomeTitle,
    int? grade,
    String? subject,
    int? durationMinutes,
    String? learningObjective,
    String? prerequisiteKnowledge,
    String? teacherMoves,
    String? activityOverview,
    String? assessmentStrategy,
    String? remediationOption,
    String? tribalVocabularyJson,
    String? requiredMaterialsJson,
    String? stepsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) => LessonData(
    id: id ?? this.id,
    title: title ?? this.title,
    titleHi: titleHi ?? this.titleHi,
    outcomeCode: outcomeCode ?? this.outcomeCode,
    outcomeTitle: outcomeTitle ?? this.outcomeTitle,
    grade: grade ?? this.grade,
    subject: subject ?? this.subject,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    learningObjective: learningObjective ?? this.learningObjective,
    prerequisiteKnowledge: prerequisiteKnowledge ?? this.prerequisiteKnowledge,
    teacherMoves: teacherMoves ?? this.teacherMoves,
    activityOverview: activityOverview ?? this.activityOverview,
    assessmentStrategy: assessmentStrategy ?? this.assessmentStrategy,
    remediationOption: remediationOption ?? this.remediationOption,
    tribalVocabularyJson: tribalVocabularyJson ?? this.tribalVocabularyJson,
    requiredMaterialsJson: requiredMaterialsJson ?? this.requiredMaterialsJson,
    stepsJson: stepsJson ?? this.stepsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  LessonData copyWithCompanion(LessonsCompanion data) {
    return LessonData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      titleHi: data.titleHi.present ? data.titleHi.value : this.titleHi,
      outcomeCode: data.outcomeCode.present
          ? data.outcomeCode.value
          : this.outcomeCode,
      outcomeTitle: data.outcomeTitle.present
          ? data.outcomeTitle.value
          : this.outcomeTitle,
      grade: data.grade.present ? data.grade.value : this.grade,
      subject: data.subject.present ? data.subject.value : this.subject,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      learningObjective: data.learningObjective.present
          ? data.learningObjective.value
          : this.learningObjective,
      prerequisiteKnowledge: data.prerequisiteKnowledge.present
          ? data.prerequisiteKnowledge.value
          : this.prerequisiteKnowledge,
      teacherMoves: data.teacherMoves.present
          ? data.teacherMoves.value
          : this.teacherMoves,
      activityOverview: data.activityOverview.present
          ? data.activityOverview.value
          : this.activityOverview,
      assessmentStrategy: data.assessmentStrategy.present
          ? data.assessmentStrategy.value
          : this.assessmentStrategy,
      remediationOption: data.remediationOption.present
          ? data.remediationOption.value
          : this.remediationOption,
      tribalVocabularyJson: data.tribalVocabularyJson.present
          ? data.tribalVocabularyJson.value
          : this.tribalVocabularyJson,
      requiredMaterialsJson: data.requiredMaterialsJson.present
          ? data.requiredMaterialsJson.value
          : this.requiredMaterialsJson,
      stepsJson: data.stepsJson.present ? data.stepsJson.value : this.stepsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleHi: $titleHi, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('outcomeTitle: $outcomeTitle, ')
          ..write('grade: $grade, ')
          ..write('subject: $subject, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('learningObjective: $learningObjective, ')
          ..write('prerequisiteKnowledge: $prerequisiteKnowledge, ')
          ..write('teacherMoves: $teacherMoves, ')
          ..write('activityOverview: $activityOverview, ')
          ..write('assessmentStrategy: $assessmentStrategy, ')
          ..write('remediationOption: $remediationOption, ')
          ..write('tribalVocabularyJson: $tribalVocabularyJson, ')
          ..write('requiredMaterialsJson: $requiredMaterialsJson, ')
          ..write('stepsJson: $stepsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    titleHi,
    outcomeCode,
    outcomeTitle,
    grade,
    subject,
    durationMinutes,
    learningObjective,
    prerequisiteKnowledge,
    teacherMoves,
    activityOverview,
    assessmentStrategy,
    remediationOption,
    tribalVocabularyJson,
    requiredMaterialsJson,
    stepsJson,
    createdAt,
    updatedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonData &&
          other.id == this.id &&
          other.title == this.title &&
          other.titleHi == this.titleHi &&
          other.outcomeCode == this.outcomeCode &&
          other.outcomeTitle == this.outcomeTitle &&
          other.grade == this.grade &&
          other.subject == this.subject &&
          other.durationMinutes == this.durationMinutes &&
          other.learningObjective == this.learningObjective &&
          other.prerequisiteKnowledge == this.prerequisiteKnowledge &&
          other.teacherMoves == this.teacherMoves &&
          other.activityOverview == this.activityOverview &&
          other.assessmentStrategy == this.assessmentStrategy &&
          other.remediationOption == this.remediationOption &&
          other.tribalVocabularyJson == this.tribalVocabularyJson &&
          other.requiredMaterialsJson == this.requiredMaterialsJson &&
          other.stepsJson == this.stepsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class LessonsCompanion extends UpdateCompanion<LessonData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> titleHi;
  final Value<String> outcomeCode;
  final Value<String> outcomeTitle;
  final Value<int> grade;
  final Value<String> subject;
  final Value<int> durationMinutes;
  final Value<String> learningObjective;
  final Value<String> prerequisiteKnowledge;
  final Value<String> teacherMoves;
  final Value<String> activityOverview;
  final Value<String> assessmentStrategy;
  final Value<String> remediationOption;
  final Value<String> tribalVocabularyJson;
  final Value<String> requiredMaterialsJson;
  final Value<String> stepsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LessonsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.titleHi = const Value.absent(),
    this.outcomeCode = const Value.absent(),
    this.outcomeTitle = const Value.absent(),
    this.grade = const Value.absent(),
    this.subject = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.learningObjective = const Value.absent(),
    this.prerequisiteKnowledge = const Value.absent(),
    this.teacherMoves = const Value.absent(),
    this.activityOverview = const Value.absent(),
    this.assessmentStrategy = const Value.absent(),
    this.remediationOption = const Value.absent(),
    this.tribalVocabularyJson = const Value.absent(),
    this.requiredMaterialsJson = const Value.absent(),
    this.stepsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonsCompanion.insert({
    required String id,
    required String title,
    required String titleHi,
    required String outcomeCode,
    required String outcomeTitle,
    required int grade,
    required String subject,
    required int durationMinutes,
    required String learningObjective,
    required String prerequisiteKnowledge,
    required String teacherMoves,
    required String activityOverview,
    required String assessmentStrategy,
    required String remediationOption,
    required String tribalVocabularyJson,
    required String requiredMaterialsJson,
    required String stepsJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       titleHi = Value(titleHi),
       outcomeCode = Value(outcomeCode),
       outcomeTitle = Value(outcomeTitle),
       grade = Value(grade),
       subject = Value(subject),
       durationMinutes = Value(durationMinutes),
       learningObjective = Value(learningObjective),
       prerequisiteKnowledge = Value(prerequisiteKnowledge),
       teacherMoves = Value(teacherMoves),
       activityOverview = Value(activityOverview),
       assessmentStrategy = Value(assessmentStrategy),
       remediationOption = Value(remediationOption),
       tribalVocabularyJson = Value(tribalVocabularyJson),
       requiredMaterialsJson = Value(requiredMaterialsJson),
       stepsJson = Value(stepsJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LessonData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? titleHi,
    Expression<String>? outcomeCode,
    Expression<String>? outcomeTitle,
    Expression<int>? grade,
    Expression<String>? subject,
    Expression<int>? durationMinutes,
    Expression<String>? learningObjective,
    Expression<String>? prerequisiteKnowledge,
    Expression<String>? teacherMoves,
    Expression<String>? activityOverview,
    Expression<String>? assessmentStrategy,
    Expression<String>? remediationOption,
    Expression<String>? tribalVocabularyJson,
    Expression<String>? requiredMaterialsJson,
    Expression<String>? stepsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (titleHi != null) 'title_hi': titleHi,
      if (outcomeCode != null) 'outcome_code': outcomeCode,
      if (outcomeTitle != null) 'outcome_title': outcomeTitle,
      if (grade != null) 'grade': grade,
      if (subject != null) 'subject': subject,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (learningObjective != null) 'learning_objective': learningObjective,
      if (prerequisiteKnowledge != null)
        'prerequisite_knowledge': prerequisiteKnowledge,
      if (teacherMoves != null) 'teacher_moves': teacherMoves,
      if (activityOverview != null) 'activity_overview': activityOverview,
      if (assessmentStrategy != null) 'assessment_strategy': assessmentStrategy,
      if (remediationOption != null) 'remediation_option': remediationOption,
      if (tribalVocabularyJson != null)
        'tribal_vocabulary_json': tribalVocabularyJson,
      if (requiredMaterialsJson != null)
        'required_materials_json': requiredMaterialsJson,
      if (stepsJson != null) 'steps_json': stepsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? titleHi,
    Value<String>? outcomeCode,
    Value<String>? outcomeTitle,
    Value<int>? grade,
    Value<String>? subject,
    Value<int>? durationMinutes,
    Value<String>? learningObjective,
    Value<String>? prerequisiteKnowledge,
    Value<String>? teacherMoves,
    Value<String>? activityOverview,
    Value<String>? assessmentStrategy,
    Value<String>? remediationOption,
    Value<String>? tribalVocabularyJson,
    Value<String>? requiredMaterialsJson,
    Value<String>? stepsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return LessonsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      titleHi: titleHi ?? this.titleHi,
      outcomeCode: outcomeCode ?? this.outcomeCode,
      outcomeTitle: outcomeTitle ?? this.outcomeTitle,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      learningObjective: learningObjective ?? this.learningObjective,
      prerequisiteKnowledge:
          prerequisiteKnowledge ?? this.prerequisiteKnowledge,
      teacherMoves: teacherMoves ?? this.teacherMoves,
      activityOverview: activityOverview ?? this.activityOverview,
      assessmentStrategy: assessmentStrategy ?? this.assessmentStrategy,
      remediationOption: remediationOption ?? this.remediationOption,
      tribalVocabularyJson: tribalVocabularyJson ?? this.tribalVocabularyJson,
      requiredMaterialsJson:
          requiredMaterialsJson ?? this.requiredMaterialsJson,
      stepsJson: stepsJson ?? this.stepsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (titleHi.present) {
      map['title_hi'] = Variable<String>(titleHi.value);
    }
    if (outcomeCode.present) {
      map['outcome_code'] = Variable<String>(outcomeCode.value);
    }
    if (outcomeTitle.present) {
      map['outcome_title'] = Variable<String>(outcomeTitle.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (learningObjective.present) {
      map['learning_objective'] = Variable<String>(learningObjective.value);
    }
    if (prerequisiteKnowledge.present) {
      map['prerequisite_knowledge'] = Variable<String>(
        prerequisiteKnowledge.value,
      );
    }
    if (teacherMoves.present) {
      map['teacher_moves'] = Variable<String>(teacherMoves.value);
    }
    if (activityOverview.present) {
      map['activity_overview'] = Variable<String>(activityOverview.value);
    }
    if (assessmentStrategy.present) {
      map['assessment_strategy'] = Variable<String>(assessmentStrategy.value);
    }
    if (remediationOption.present) {
      map['remediation_option'] = Variable<String>(remediationOption.value);
    }
    if (tribalVocabularyJson.present) {
      map['tribal_vocabulary_json'] = Variable<String>(
        tribalVocabularyJson.value,
      );
    }
    if (requiredMaterialsJson.present) {
      map['required_materials_json'] = Variable<String>(
        requiredMaterialsJson.value,
      );
    }
    if (stepsJson.present) {
      map['steps_json'] = Variable<String>(stepsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleHi: $titleHi, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('outcomeTitle: $outcomeTitle, ')
          ..write('grade: $grade, ')
          ..write('subject: $subject, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('learningObjective: $learningObjective, ')
          ..write('prerequisiteKnowledge: $prerequisiteKnowledge, ')
          ..write('teacherMoves: $teacherMoves, ')
          ..write('activityOverview: $activityOverview, ')
          ..write('assessmentStrategy: $assessmentStrategy, ')
          ..write('remediationOption: $remediationOption, ')
          ..write('tribalVocabularyJson: $tribalVocabularyJson, ')
          ..write('requiredMaterialsJson: $requiredMaterialsJson, ')
          ..write('stepsJson: $stepsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, ActivityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleHiMeta = const VerificationMeta(
    'titleHi',
  );
  @override
  late final GeneratedColumn<String> titleHi = GeneratedColumn<String>(
    'title_hi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strandOrStageMeta = const VerificationMeta(
    'strandOrStage',
  );
  @override
  late final GeneratedColumn<String> strandOrStage = GeneratedColumn<String>(
    'strand_or_stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _materialsMeta = const VerificationMeta(
    'materials',
  );
  @override
  late final GeneratedColumn<String> materials = GeneratedColumn<String>(
    'materials',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherStepsJsonMeta = const VerificationMeta(
    'teacherStepsJson',
  );
  @override
  late final GeneratedColumn<String> teacherStepsJson = GeneratedColumn<String>(
    'teacher_steps_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentStepsJsonMeta = const VerificationMeta(
    'studentStepsJson',
  );
  @override
  late final GeneratedColumn<String> studentStepsJson = GeneratedColumn<String>(
    'student_steps_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsJsonMeta = const VerificationMeta(
    'questionsJson',
  );
  @override
  late final GeneratedColumn<String> questionsJson = GeneratedColumn<String>(
    'questions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedResponseMeta = const VerificationMeta(
    'expectedResponse',
  );
  @override
  late final GeneratedColumn<String> expectedResponse = GeneratedColumn<String>(
    'expected_response',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioPromptHindiMeta = const VerificationMeta(
    'audioPromptHindi',
  );
  @override
  late final GeneratedColumn<String> audioPromptHindi = GeneratedColumn<String>(
    'audio_prompt_hindi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioPromptTribalMeta = const VerificationMeta(
    'audioPromptTribal',
  );
  @override
  late final GeneratedColumn<String> audioPromptTribal =
      GeneratedColumn<String>(
        'audio_prompt_tribal',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isSavedMeta = const VerificationMeta(
    'isSaved',
  );
  @override
  late final GeneratedColumn<bool> isSaved = GeneratedColumn<bool>(
    'is_saved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_saved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    titleHi,
    grade,
    subject,
    strandOrStage,
    language,
    durationMinutes,
    difficulty,
    materials,
    teacherStepsJson,
    studentStepsJson,
    questionsJson,
    expectedResponse,
    audioPromptHindi,
    audioPromptTribal,
    isSaved,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_hi')) {
      context.handle(
        _titleHiMeta,
        titleHi.isAcceptableOrUnknown(data['title_hi']!, _titleHiMeta),
      );
    } else if (isInserting) {
      context.missing(_titleHiMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('strand_or_stage')) {
      context.handle(
        _strandOrStageMeta,
        strandOrStage.isAcceptableOrUnknown(
          data['strand_or_stage']!,
          _strandOrStageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strandOrStageMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('materials')) {
      context.handle(
        _materialsMeta,
        materials.isAcceptableOrUnknown(data['materials']!, _materialsMeta),
      );
    } else if (isInserting) {
      context.missing(_materialsMeta);
    }
    if (data.containsKey('teacher_steps_json')) {
      context.handle(
        _teacherStepsJsonMeta,
        teacherStepsJson.isAcceptableOrUnknown(
          data['teacher_steps_json']!,
          _teacherStepsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_teacherStepsJsonMeta);
    }
    if (data.containsKey('student_steps_json')) {
      context.handle(
        _studentStepsJsonMeta,
        studentStepsJson.isAcceptableOrUnknown(
          data['student_steps_json']!,
          _studentStepsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentStepsJsonMeta);
    }
    if (data.containsKey('questions_json')) {
      context.handle(
        _questionsJsonMeta,
        questionsJson.isAcceptableOrUnknown(
          data['questions_json']!,
          _questionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionsJsonMeta);
    }
    if (data.containsKey('expected_response')) {
      context.handle(
        _expectedResponseMeta,
        expectedResponse.isAcceptableOrUnknown(
          data['expected_response']!,
          _expectedResponseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedResponseMeta);
    }
    if (data.containsKey('audio_prompt_hindi')) {
      context.handle(
        _audioPromptHindiMeta,
        audioPromptHindi.isAcceptableOrUnknown(
          data['audio_prompt_hindi']!,
          _audioPromptHindiMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_audioPromptHindiMeta);
    }
    if (data.containsKey('audio_prompt_tribal')) {
      context.handle(
        _audioPromptTribalMeta,
        audioPromptTribal.isAcceptableOrUnknown(
          data['audio_prompt_tribal']!,
          _audioPromptTribalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_audioPromptTribalMeta);
    }
    if (data.containsKey('is_saved')) {
      context.handle(
        _isSavedMeta,
        isSaved.isAcceptableOrUnknown(data['is_saved']!, _isSavedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_hi'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      strandOrStage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strand_or_stage'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      materials: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}materials'],
      )!,
      teacherStepsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_steps_json'],
      )!,
      studentStepsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_steps_json'],
      )!,
      questionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}questions_json'],
      )!,
      expectedResponse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_response'],
      )!,
      audioPromptHindi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_prompt_hindi'],
      )!,
      audioPromptTribal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_prompt_tribal'],
      )!,
      isSaved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_saved'],
      )!,
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class ActivityData extends DataClass implements Insertable<ActivityData> {
  final String id;
  final String title;
  final String titleHi;
  final int grade;
  final String subject;
  final String strandOrStage;
  final String language;
  final int durationMinutes;
  final String difficulty;
  final String materials;
  final String teacherStepsJson;
  final String studentStepsJson;
  final String questionsJson;
  final String expectedResponse;
  final String audioPromptHindi;
  final String audioPromptTribal;
  final bool isSaved;
  const ActivityData({
    required this.id,
    required this.title,
    required this.titleHi,
    required this.grade,
    required this.subject,
    required this.strandOrStage,
    required this.language,
    required this.durationMinutes,
    required this.difficulty,
    required this.materials,
    required this.teacherStepsJson,
    required this.studentStepsJson,
    required this.questionsJson,
    required this.expectedResponse,
    required this.audioPromptHindi,
    required this.audioPromptTribal,
    required this.isSaved,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['title_hi'] = Variable<String>(titleHi);
    map['grade'] = Variable<int>(grade);
    map['subject'] = Variable<String>(subject);
    map['strand_or_stage'] = Variable<String>(strandOrStage);
    map['language'] = Variable<String>(language);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['difficulty'] = Variable<String>(difficulty);
    map['materials'] = Variable<String>(materials);
    map['teacher_steps_json'] = Variable<String>(teacherStepsJson);
    map['student_steps_json'] = Variable<String>(studentStepsJson);
    map['questions_json'] = Variable<String>(questionsJson);
    map['expected_response'] = Variable<String>(expectedResponse);
    map['audio_prompt_hindi'] = Variable<String>(audioPromptHindi);
    map['audio_prompt_tribal'] = Variable<String>(audioPromptTribal);
    map['is_saved'] = Variable<bool>(isSaved);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      title: Value(title),
      titleHi: Value(titleHi),
      grade: Value(grade),
      subject: Value(subject),
      strandOrStage: Value(strandOrStage),
      language: Value(language),
      durationMinutes: Value(durationMinutes),
      difficulty: Value(difficulty),
      materials: Value(materials),
      teacherStepsJson: Value(teacherStepsJson),
      studentStepsJson: Value(studentStepsJson),
      questionsJson: Value(questionsJson),
      expectedResponse: Value(expectedResponse),
      audioPromptHindi: Value(audioPromptHindi),
      audioPromptTribal: Value(audioPromptTribal),
      isSaved: Value(isSaved),
    );
  }

  factory ActivityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      titleHi: serializer.fromJson<String>(json['titleHi']),
      grade: serializer.fromJson<int>(json['grade']),
      subject: serializer.fromJson<String>(json['subject']),
      strandOrStage: serializer.fromJson<String>(json['strandOrStage']),
      language: serializer.fromJson<String>(json['language']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      materials: serializer.fromJson<String>(json['materials']),
      teacherStepsJson: serializer.fromJson<String>(json['teacherStepsJson']),
      studentStepsJson: serializer.fromJson<String>(json['studentStepsJson']),
      questionsJson: serializer.fromJson<String>(json['questionsJson']),
      expectedResponse: serializer.fromJson<String>(json['expectedResponse']),
      audioPromptHindi: serializer.fromJson<String>(json['audioPromptHindi']),
      audioPromptTribal: serializer.fromJson<String>(json['audioPromptTribal']),
      isSaved: serializer.fromJson<bool>(json['isSaved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'titleHi': serializer.toJson<String>(titleHi),
      'grade': serializer.toJson<int>(grade),
      'subject': serializer.toJson<String>(subject),
      'strandOrStage': serializer.toJson<String>(strandOrStage),
      'language': serializer.toJson<String>(language),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'difficulty': serializer.toJson<String>(difficulty),
      'materials': serializer.toJson<String>(materials),
      'teacherStepsJson': serializer.toJson<String>(teacherStepsJson),
      'studentStepsJson': serializer.toJson<String>(studentStepsJson),
      'questionsJson': serializer.toJson<String>(questionsJson),
      'expectedResponse': serializer.toJson<String>(expectedResponse),
      'audioPromptHindi': serializer.toJson<String>(audioPromptHindi),
      'audioPromptTribal': serializer.toJson<String>(audioPromptTribal),
      'isSaved': serializer.toJson<bool>(isSaved),
    };
  }

  ActivityData copyWith({
    String? id,
    String? title,
    String? titleHi,
    int? grade,
    String? subject,
    String? strandOrStage,
    String? language,
    int? durationMinutes,
    String? difficulty,
    String? materials,
    String? teacherStepsJson,
    String? studentStepsJson,
    String? questionsJson,
    String? expectedResponse,
    String? audioPromptHindi,
    String? audioPromptTribal,
    bool? isSaved,
  }) => ActivityData(
    id: id ?? this.id,
    title: title ?? this.title,
    titleHi: titleHi ?? this.titleHi,
    grade: grade ?? this.grade,
    subject: subject ?? this.subject,
    strandOrStage: strandOrStage ?? this.strandOrStage,
    language: language ?? this.language,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    difficulty: difficulty ?? this.difficulty,
    materials: materials ?? this.materials,
    teacherStepsJson: teacherStepsJson ?? this.teacherStepsJson,
    studentStepsJson: studentStepsJson ?? this.studentStepsJson,
    questionsJson: questionsJson ?? this.questionsJson,
    expectedResponse: expectedResponse ?? this.expectedResponse,
    audioPromptHindi: audioPromptHindi ?? this.audioPromptHindi,
    audioPromptTribal: audioPromptTribal ?? this.audioPromptTribal,
    isSaved: isSaved ?? this.isSaved,
  );
  ActivityData copyWithCompanion(ActivitiesCompanion data) {
    return ActivityData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      titleHi: data.titleHi.present ? data.titleHi.value : this.titleHi,
      grade: data.grade.present ? data.grade.value : this.grade,
      subject: data.subject.present ? data.subject.value : this.subject,
      strandOrStage: data.strandOrStage.present
          ? data.strandOrStage.value
          : this.strandOrStage,
      language: data.language.present ? data.language.value : this.language,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      materials: data.materials.present ? data.materials.value : this.materials,
      teacherStepsJson: data.teacherStepsJson.present
          ? data.teacherStepsJson.value
          : this.teacherStepsJson,
      studentStepsJson: data.studentStepsJson.present
          ? data.studentStepsJson.value
          : this.studentStepsJson,
      questionsJson: data.questionsJson.present
          ? data.questionsJson.value
          : this.questionsJson,
      expectedResponse: data.expectedResponse.present
          ? data.expectedResponse.value
          : this.expectedResponse,
      audioPromptHindi: data.audioPromptHindi.present
          ? data.audioPromptHindi.value
          : this.audioPromptHindi,
      audioPromptTribal: data.audioPromptTribal.present
          ? data.audioPromptTribal.value
          : this.audioPromptTribal,
      isSaved: data.isSaved.present ? data.isSaved.value : this.isSaved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleHi: $titleHi, ')
          ..write('grade: $grade, ')
          ..write('subject: $subject, ')
          ..write('strandOrStage: $strandOrStage, ')
          ..write('language: $language, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('difficulty: $difficulty, ')
          ..write('materials: $materials, ')
          ..write('teacherStepsJson: $teacherStepsJson, ')
          ..write('studentStepsJson: $studentStepsJson, ')
          ..write('questionsJson: $questionsJson, ')
          ..write('expectedResponse: $expectedResponse, ')
          ..write('audioPromptHindi: $audioPromptHindi, ')
          ..write('audioPromptTribal: $audioPromptTribal, ')
          ..write('isSaved: $isSaved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    titleHi,
    grade,
    subject,
    strandOrStage,
    language,
    durationMinutes,
    difficulty,
    materials,
    teacherStepsJson,
    studentStepsJson,
    questionsJson,
    expectedResponse,
    audioPromptHindi,
    audioPromptTribal,
    isSaved,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityData &&
          other.id == this.id &&
          other.title == this.title &&
          other.titleHi == this.titleHi &&
          other.grade == this.grade &&
          other.subject == this.subject &&
          other.strandOrStage == this.strandOrStage &&
          other.language == this.language &&
          other.durationMinutes == this.durationMinutes &&
          other.difficulty == this.difficulty &&
          other.materials == this.materials &&
          other.teacherStepsJson == this.teacherStepsJson &&
          other.studentStepsJson == this.studentStepsJson &&
          other.questionsJson == this.questionsJson &&
          other.expectedResponse == this.expectedResponse &&
          other.audioPromptHindi == this.audioPromptHindi &&
          other.audioPromptTribal == this.audioPromptTribal &&
          other.isSaved == this.isSaved);
}

class ActivitiesCompanion extends UpdateCompanion<ActivityData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> titleHi;
  final Value<int> grade;
  final Value<String> subject;
  final Value<String> strandOrStage;
  final Value<String> language;
  final Value<int> durationMinutes;
  final Value<String> difficulty;
  final Value<String> materials;
  final Value<String> teacherStepsJson;
  final Value<String> studentStepsJson;
  final Value<String> questionsJson;
  final Value<String> expectedResponse;
  final Value<String> audioPromptHindi;
  final Value<String> audioPromptTribal;
  final Value<bool> isSaved;
  final Value<int> rowid;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.titleHi = const Value.absent(),
    this.grade = const Value.absent(),
    this.subject = const Value.absent(),
    this.strandOrStage = const Value.absent(),
    this.language = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.materials = const Value.absent(),
    this.teacherStepsJson = const Value.absent(),
    this.studentStepsJson = const Value.absent(),
    this.questionsJson = const Value.absent(),
    this.expectedResponse = const Value.absent(),
    this.audioPromptHindi = const Value.absent(),
    this.audioPromptTribal = const Value.absent(),
    this.isSaved = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    required String id,
    required String title,
    required String titleHi,
    required int grade,
    required String subject,
    required String strandOrStage,
    required String language,
    required int durationMinutes,
    required String difficulty,
    required String materials,
    required String teacherStepsJson,
    required String studentStepsJson,
    required String questionsJson,
    required String expectedResponse,
    required String audioPromptHindi,
    required String audioPromptTribal,
    this.isSaved = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       titleHi = Value(titleHi),
       grade = Value(grade),
       subject = Value(subject),
       strandOrStage = Value(strandOrStage),
       language = Value(language),
       durationMinutes = Value(durationMinutes),
       difficulty = Value(difficulty),
       materials = Value(materials),
       teacherStepsJson = Value(teacherStepsJson),
       studentStepsJson = Value(studentStepsJson),
       questionsJson = Value(questionsJson),
       expectedResponse = Value(expectedResponse),
       audioPromptHindi = Value(audioPromptHindi),
       audioPromptTribal = Value(audioPromptTribal);
  static Insertable<ActivityData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? titleHi,
    Expression<int>? grade,
    Expression<String>? subject,
    Expression<String>? strandOrStage,
    Expression<String>? language,
    Expression<int>? durationMinutes,
    Expression<String>? difficulty,
    Expression<String>? materials,
    Expression<String>? teacherStepsJson,
    Expression<String>? studentStepsJson,
    Expression<String>? questionsJson,
    Expression<String>? expectedResponse,
    Expression<String>? audioPromptHindi,
    Expression<String>? audioPromptTribal,
    Expression<bool>? isSaved,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (titleHi != null) 'title_hi': titleHi,
      if (grade != null) 'grade': grade,
      if (subject != null) 'subject': subject,
      if (strandOrStage != null) 'strand_or_stage': strandOrStage,
      if (language != null) 'language': language,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (difficulty != null) 'difficulty': difficulty,
      if (materials != null) 'materials': materials,
      if (teacherStepsJson != null) 'teacher_steps_json': teacherStepsJson,
      if (studentStepsJson != null) 'student_steps_json': studentStepsJson,
      if (questionsJson != null) 'questions_json': questionsJson,
      if (expectedResponse != null) 'expected_response': expectedResponse,
      if (audioPromptHindi != null) 'audio_prompt_hindi': audioPromptHindi,
      if (audioPromptTribal != null) 'audio_prompt_tribal': audioPromptTribal,
      if (isSaved != null) 'is_saved': isSaved,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? titleHi,
    Value<int>? grade,
    Value<String>? subject,
    Value<String>? strandOrStage,
    Value<String>? language,
    Value<int>? durationMinutes,
    Value<String>? difficulty,
    Value<String>? materials,
    Value<String>? teacherStepsJson,
    Value<String>? studentStepsJson,
    Value<String>? questionsJson,
    Value<String>? expectedResponse,
    Value<String>? audioPromptHindi,
    Value<String>? audioPromptTribal,
    Value<bool>? isSaved,
    Value<int>? rowid,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      titleHi: titleHi ?? this.titleHi,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      strandOrStage: strandOrStage ?? this.strandOrStage,
      language: language ?? this.language,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      materials: materials ?? this.materials,
      teacherStepsJson: teacherStepsJson ?? this.teacherStepsJson,
      studentStepsJson: studentStepsJson ?? this.studentStepsJson,
      questionsJson: questionsJson ?? this.questionsJson,
      expectedResponse: expectedResponse ?? this.expectedResponse,
      audioPromptHindi: audioPromptHindi ?? this.audioPromptHindi,
      audioPromptTribal: audioPromptTribal ?? this.audioPromptTribal,
      isSaved: isSaved ?? this.isSaved,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (titleHi.present) {
      map['title_hi'] = Variable<String>(titleHi.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (strandOrStage.present) {
      map['strand_or_stage'] = Variable<String>(strandOrStage.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (materials.present) {
      map['materials'] = Variable<String>(materials.value);
    }
    if (teacherStepsJson.present) {
      map['teacher_steps_json'] = Variable<String>(teacherStepsJson.value);
    }
    if (studentStepsJson.present) {
      map['student_steps_json'] = Variable<String>(studentStepsJson.value);
    }
    if (questionsJson.present) {
      map['questions_json'] = Variable<String>(questionsJson.value);
    }
    if (expectedResponse.present) {
      map['expected_response'] = Variable<String>(expectedResponse.value);
    }
    if (audioPromptHindi.present) {
      map['audio_prompt_hindi'] = Variable<String>(audioPromptHindi.value);
    }
    if (audioPromptTribal.present) {
      map['audio_prompt_tribal'] = Variable<String>(audioPromptTribal.value);
    }
    if (isSaved.present) {
      map['is_saved'] = Variable<bool>(isSaved.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleHi: $titleHi, ')
          ..write('grade: $grade, ')
          ..write('subject: $subject, ')
          ..write('strandOrStage: $strandOrStage, ')
          ..write('language: $language, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('difficulty: $difficulty, ')
          ..write('materials: $materials, ')
          ..write('teacherStepsJson: $teacherStepsJson, ')
          ..write('studentStepsJson: $studentStepsJson, ')
          ..write('questionsJson: $questionsJson, ')
          ..write('expectedResponse: $expectedResponse, ')
          ..write('audioPromptHindi: $audioPromptHindi, ')
          ..write('audioPromptTribal: $audioPromptTribal, ')
          ..write('isSaved: $isSaved, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonDeliveryProgressTable extends LessonDeliveryProgress
    with TableInfo<$LessonDeliveryProgressTable, LessonDeliveryProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonDeliveryProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentStepMeta = const VerificationMeta(
    'currentStep',
  );
  @override
  late final GeneratedColumn<int> currentStep = GeneratedColumn<int>(
    'current_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lessonId,
    currentStep,
    isCompleted,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_delivery_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonDeliveryProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('current_step')) {
      context.handle(
        _currentStepMeta,
        currentStep.isAcceptableOrUnknown(
          data['current_step']!,
          _currentStepMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentStepMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  LessonDeliveryProgressData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonDeliveryProgressData(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      currentStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_step'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $LessonDeliveryProgressTable createAlias(String alias) {
    return $LessonDeliveryProgressTable(attachedDatabase, alias);
  }
}

class LessonDeliveryProgressData extends DataClass
    implements Insertable<LessonDeliveryProgressData> {
  final String lessonId;
  final int currentStep;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;
  const LessonDeliveryProgressData({
    required this.lessonId,
    required this.currentStep,
    required this.isCompleted,
    required this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['current_step'] = Variable<int>(currentStep);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  LessonDeliveryProgressCompanion toCompanion(bool nullToAbsent) {
    return LessonDeliveryProgressCompanion(
      lessonId: Value(lessonId),
      currentStep: Value(currentStep),
      isCompleted: Value(isCompleted),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory LessonDeliveryProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonDeliveryProgressData(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      currentStep: serializer.fromJson<int>(json['currentStep']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'currentStep': serializer.toJson<int>(currentStep),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  LessonDeliveryProgressData copyWith({
    String? lessonId,
    int? currentStep,
    bool? isCompleted,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => LessonDeliveryProgressData(
    lessonId: lessonId ?? this.lessonId,
    currentStep: currentStep ?? this.currentStep,
    isCompleted: isCompleted ?? this.isCompleted,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  LessonDeliveryProgressData copyWithCompanion(
    LessonDeliveryProgressCompanion data,
  ) {
    return LessonDeliveryProgressData(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      currentStep: data.currentStep.present
          ? data.currentStep.value
          : this.currentStep,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonDeliveryProgressData(')
          ..write('lessonId: $lessonId, ')
          ..write('currentStep: $currentStep, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(lessonId, currentStep, isCompleted, startedAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonDeliveryProgressData &&
          other.lessonId == this.lessonId &&
          other.currentStep == this.currentStep &&
          other.isCompleted == this.isCompleted &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class LessonDeliveryProgressCompanion
    extends UpdateCompanion<LessonDeliveryProgressData> {
  final Value<String> lessonId;
  final Value<int> currentStep;
  final Value<bool> isCompleted;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const LessonDeliveryProgressCompanion({
    this.lessonId = const Value.absent(),
    this.currentStep = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonDeliveryProgressCompanion.insert({
    required String lessonId,
    required int currentStep,
    this.isCompleted = const Value.absent(),
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId),
       currentStep = Value(currentStep),
       startedAt = Value(startedAt);
  static Insertable<LessonDeliveryProgressData> custom({
    Expression<String>? lessonId,
    Expression<int>? currentStep,
    Expression<bool>? isCompleted,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (currentStep != null) 'current_step': currentStep,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonDeliveryProgressCompanion copyWith({
    Value<String>? lessonId,
    Value<int>? currentStep,
    Value<bool>? isCompleted,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return LessonDeliveryProgressCompanion(
      lessonId: lessonId ?? this.lessonId,
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (currentStep.present) {
      map['current_step'] = Variable<int>(currentStep.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonDeliveryProgressCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('currentStep: $currentStep, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalContextsTable extends LocalContexts
    with TableInfo<$LocalContextsTable, LocalContextData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleHiMeta = const VerificationMeta(
    'titleHi',
  );
  @override
  late final GeneratedColumn<String> titleHi = GeneratedColumn<String>(
    'title_hi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _culturalRelevanceMeta = const VerificationMeta(
    'culturalRelevance',
  );
  @override
  late final GeneratedColumn<String> culturalRelevance =
      GeneratedColumn<String>(
        'cultural_relevance',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _tribalTermMeta = const VerificationMeta(
    'tribalTerm',
  );
  @override
  late final GeneratedColumn<String> tribalTerm = GeneratedColumn<String>(
    'tribal_term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    title,
    titleHi,
    description,
    culturalRelevance,
    tribalTerm,
    language,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalContextData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_hi')) {
      context.handle(
        _titleHiMeta,
        titleHi.isAcceptableOrUnknown(data['title_hi']!, _titleHiMeta),
      );
    } else if (isInserting) {
      context.missing(_titleHiMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('cultural_relevance')) {
      context.handle(
        _culturalRelevanceMeta,
        culturalRelevance.isAcceptableOrUnknown(
          data['cultural_relevance']!,
          _culturalRelevanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_culturalRelevanceMeta);
    }
    if (data.containsKey('tribal_term')) {
      context.handle(
        _tribalTermMeta,
        tribalTerm.isAcceptableOrUnknown(data['tribal_term']!, _tribalTermMeta),
      );
    } else if (isInserting) {
      context.missing(_tribalTermMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalContextData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalContextData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_hi'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      culturalRelevance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cultural_relevance'],
      )!,
      tribalTerm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tribal_term'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
    );
  }

  @override
  $LocalContextsTable createAlias(String alias) {
    return $LocalContextsTable(attachedDatabase, alias);
  }
}

class LocalContextData extends DataClass
    implements Insertable<LocalContextData> {
  final String id;
  final String category;
  final String title;
  final String titleHi;
  final String description;
  final String culturalRelevance;
  final String tribalTerm;
  final String language;
  const LocalContextData({
    required this.id,
    required this.category,
    required this.title,
    required this.titleHi,
    required this.description,
    required this.culturalRelevance,
    required this.tribalTerm,
    required this.language,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['title'] = Variable<String>(title);
    map['title_hi'] = Variable<String>(titleHi);
    map['description'] = Variable<String>(description);
    map['cultural_relevance'] = Variable<String>(culturalRelevance);
    map['tribal_term'] = Variable<String>(tribalTerm);
    map['language'] = Variable<String>(language);
    return map;
  }

  LocalContextsCompanion toCompanion(bool nullToAbsent) {
    return LocalContextsCompanion(
      id: Value(id),
      category: Value(category),
      title: Value(title),
      titleHi: Value(titleHi),
      description: Value(description),
      culturalRelevance: Value(culturalRelevance),
      tribalTerm: Value(tribalTerm),
      language: Value(language),
    );
  }

  factory LocalContextData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalContextData(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      titleHi: serializer.fromJson<String>(json['titleHi']),
      description: serializer.fromJson<String>(json['description']),
      culturalRelevance: serializer.fromJson<String>(json['culturalRelevance']),
      tribalTerm: serializer.fromJson<String>(json['tribalTerm']),
      language: serializer.fromJson<String>(json['language']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String>(title),
      'titleHi': serializer.toJson<String>(titleHi),
      'description': serializer.toJson<String>(description),
      'culturalRelevance': serializer.toJson<String>(culturalRelevance),
      'tribalTerm': serializer.toJson<String>(tribalTerm),
      'language': serializer.toJson<String>(language),
    };
  }

  LocalContextData copyWith({
    String? id,
    String? category,
    String? title,
    String? titleHi,
    String? description,
    String? culturalRelevance,
    String? tribalTerm,
    String? language,
  }) => LocalContextData(
    id: id ?? this.id,
    category: category ?? this.category,
    title: title ?? this.title,
    titleHi: titleHi ?? this.titleHi,
    description: description ?? this.description,
    culturalRelevance: culturalRelevance ?? this.culturalRelevance,
    tribalTerm: tribalTerm ?? this.tribalTerm,
    language: language ?? this.language,
  );
  LocalContextData copyWithCompanion(LocalContextsCompanion data) {
    return LocalContextData(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      titleHi: data.titleHi.present ? data.titleHi.value : this.titleHi,
      description: data.description.present
          ? data.description.value
          : this.description,
      culturalRelevance: data.culturalRelevance.present
          ? data.culturalRelevance.value
          : this.culturalRelevance,
      tribalTerm: data.tribalTerm.present
          ? data.tribalTerm.value
          : this.tribalTerm,
      language: data.language.present ? data.language.value : this.language,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalContextData(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('titleHi: $titleHi, ')
          ..write('description: $description, ')
          ..write('culturalRelevance: $culturalRelevance, ')
          ..write('tribalTerm: $tribalTerm, ')
          ..write('language: $language')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    title,
    titleHi,
    description,
    culturalRelevance,
    tribalTerm,
    language,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalContextData &&
          other.id == this.id &&
          other.category == this.category &&
          other.title == this.title &&
          other.titleHi == this.titleHi &&
          other.description == this.description &&
          other.culturalRelevance == this.culturalRelevance &&
          other.tribalTerm == this.tribalTerm &&
          other.language == this.language);
}

class LocalContextsCompanion extends UpdateCompanion<LocalContextData> {
  final Value<String> id;
  final Value<String> category;
  final Value<String> title;
  final Value<String> titleHi;
  final Value<String> description;
  final Value<String> culturalRelevance;
  final Value<String> tribalTerm;
  final Value<String> language;
  final Value<int> rowid;
  const LocalContextsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.titleHi = const Value.absent(),
    this.description = const Value.absent(),
    this.culturalRelevance = const Value.absent(),
    this.tribalTerm = const Value.absent(),
    this.language = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalContextsCompanion.insert({
    required String id,
    required String category,
    required String title,
    required String titleHi,
    required String description,
    required String culturalRelevance,
    required String tribalTerm,
    required String language,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       title = Value(title),
       titleHi = Value(titleHi),
       description = Value(description),
       culturalRelevance = Value(culturalRelevance),
       tribalTerm = Value(tribalTerm),
       language = Value(language);
  static Insertable<LocalContextData> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? titleHi,
    Expression<String>? description,
    Expression<String>? culturalRelevance,
    Expression<String>? tribalTerm,
    Expression<String>? language,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (titleHi != null) 'title_hi': titleHi,
      if (description != null) 'description': description,
      if (culturalRelevance != null) 'cultural_relevance': culturalRelevance,
      if (tribalTerm != null) 'tribal_term': tribalTerm,
      if (language != null) 'language': language,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalContextsCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<String>? title,
    Value<String>? titleHi,
    Value<String>? description,
    Value<String>? culturalRelevance,
    Value<String>? tribalTerm,
    Value<String>? language,
    Value<int>? rowid,
  }) {
    return LocalContextsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      titleHi: titleHi ?? this.titleHi,
      description: description ?? this.description,
      culturalRelevance: culturalRelevance ?? this.culturalRelevance,
      tribalTerm: tribalTerm ?? this.tribalTerm,
      language: language ?? this.language,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (titleHi.present) {
      map['title_hi'] = Variable<String>(titleHi.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (culturalRelevance.present) {
      map['cultural_relevance'] = Variable<String>(culturalRelevance.value);
    }
    if (tribalTerm.present) {
      map['tribal_term'] = Variable<String>(tribalTerm.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalContextsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('titleHi: $titleHi, ')
          ..write('description: $description, ')
          ..write('culturalRelevance: $culturalRelevance, ')
          ..write('tribalTerm: $tribalTerm, ')
          ..write('language: $language, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudentsTable extends Students
    with TableInfo<$StudentsTable, StudentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rollNumberMeta = const VerificationMeta(
    'rollNumber',
  );
  @override
  late final GeneratedColumn<int> rollNumber = GeneratedColumn<int>(
    'roll_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _motherTongueMeta = const VerificationMeta(
    'motherTongue',
  );
  @override
  late final GeneratedColumn<String> motherTongue = GeneratedColumn<String>(
    'mother_tongue',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _achievedOutcomesMeta = const VerificationMeta(
    'achievedOutcomes',
  );
  @override
  late final GeneratedColumn<int> achievedOutcomes = GeneratedColumn<int>(
    'achieved_outcomes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _developingOutcomesMeta =
      const VerificationMeta('developingOutcomes');
  @override
  late final GeneratedColumn<int> developingOutcomes = GeneratedColumn<int>(
    'developing_outcomes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _needsSupportOutcomesMeta =
      const VerificationMeta('needsSupportOutcomes');
  @override
  late final GeneratedColumn<int> needsSupportOutcomes = GeneratedColumn<int>(
    'needs_support_outcomes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _literacyProgressMeta = const VerificationMeta(
    'literacyProgress',
  );
  @override
  late final GeneratedColumn<double> literacyProgress = GeneratedColumn<double>(
    'literacy_progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _numeracyProgressMeta = const VerificationMeta(
    'numeracyProgress',
  );
  @override
  late final GeneratedColumn<double> numeracyProgress = GeneratedColumn<double>(
    'numeracy_progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _recentEvidenceMeta = const VerificationMeta(
    'recentEvidence',
  );
  @override
  late final GeneratedColumn<String> recentEvidence = GeneratedColumn<String>(
    'recent_evidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identifiedGapsJsonMeta =
      const VerificationMeta('identifiedGapsJson');
  @override
  late final GeneratedColumn<String> identifiedGapsJson =
      GeneratedColumn<String>(
        'identified_gaps_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    rollNumber,
    grade,
    motherTongue,
    achievedOutcomes,
    developingOutcomes,
    needsSupportOutcomes,
    literacyProgress,
    numeracyProgress,
    recentEvidence,
    identifiedGapsJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('roll_number')) {
      context.handle(
        _rollNumberMeta,
        rollNumber.isAcceptableOrUnknown(data['roll_number']!, _rollNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_rollNumberMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('mother_tongue')) {
      context.handle(
        _motherTongueMeta,
        motherTongue.isAcceptableOrUnknown(
          data['mother_tongue']!,
          _motherTongueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_motherTongueMeta);
    }
    if (data.containsKey('achieved_outcomes')) {
      context.handle(
        _achievedOutcomesMeta,
        achievedOutcomes.isAcceptableOrUnknown(
          data['achieved_outcomes']!,
          _achievedOutcomesMeta,
        ),
      );
    }
    if (data.containsKey('developing_outcomes')) {
      context.handle(
        _developingOutcomesMeta,
        developingOutcomes.isAcceptableOrUnknown(
          data['developing_outcomes']!,
          _developingOutcomesMeta,
        ),
      );
    }
    if (data.containsKey('needs_support_outcomes')) {
      context.handle(
        _needsSupportOutcomesMeta,
        needsSupportOutcomes.isAcceptableOrUnknown(
          data['needs_support_outcomes']!,
          _needsSupportOutcomesMeta,
        ),
      );
    }
    if (data.containsKey('literacy_progress')) {
      context.handle(
        _literacyProgressMeta,
        literacyProgress.isAcceptableOrUnknown(
          data['literacy_progress']!,
          _literacyProgressMeta,
        ),
      );
    }
    if (data.containsKey('numeracy_progress')) {
      context.handle(
        _numeracyProgressMeta,
        numeracyProgress.isAcceptableOrUnknown(
          data['numeracy_progress']!,
          _numeracyProgressMeta,
        ),
      );
    }
    if (data.containsKey('recent_evidence')) {
      context.handle(
        _recentEvidenceMeta,
        recentEvidence.isAcceptableOrUnknown(
          data['recent_evidence']!,
          _recentEvidenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recentEvidenceMeta);
    }
    if (data.containsKey('identified_gaps_json')) {
      context.handle(
        _identifiedGapsJsonMeta,
        identifiedGapsJson.isAcceptableOrUnknown(
          data['identified_gaps_json']!,
          _identifiedGapsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rollNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}roll_number'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      )!,
      motherTongue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mother_tongue'],
      )!,
      achievedOutcomes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}achieved_outcomes'],
      )!,
      developingOutcomes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}developing_outcomes'],
      )!,
      needsSupportOutcomes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}needs_support_outcomes'],
      )!,
      literacyProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}literacy_progress'],
      )!,
      numeracyProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}numeracy_progress'],
      )!,
      recentEvidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recent_evidence'],
      )!,
      identifiedGapsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identified_gaps_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StudentsTable createAlias(String alias) {
    return $StudentsTable(attachedDatabase, alias);
  }
}

class StudentData extends DataClass implements Insertable<StudentData> {
  final String id;
  final String name;
  final int rollNumber;
  final int grade;
  final String motherTongue;
  final int achievedOutcomes;
  final int developingOutcomes;
  final int needsSupportOutcomes;
  final double literacyProgress;
  final double numeracyProgress;
  final String recentEvidence;
  final String identifiedGapsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StudentData({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.grade,
    required this.motherTongue,
    required this.achievedOutcomes,
    required this.developingOutcomes,
    required this.needsSupportOutcomes,
    required this.literacyProgress,
    required this.numeracyProgress,
    required this.recentEvidence,
    required this.identifiedGapsJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['roll_number'] = Variable<int>(rollNumber);
    map['grade'] = Variable<int>(grade);
    map['mother_tongue'] = Variable<String>(motherTongue);
    map['achieved_outcomes'] = Variable<int>(achievedOutcomes);
    map['developing_outcomes'] = Variable<int>(developingOutcomes);
    map['needs_support_outcomes'] = Variable<int>(needsSupportOutcomes);
    map['literacy_progress'] = Variable<double>(literacyProgress);
    map['numeracy_progress'] = Variable<double>(numeracyProgress);
    map['recent_evidence'] = Variable<String>(recentEvidence);
    map['identified_gaps_json'] = Variable<String>(identifiedGapsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      id: Value(id),
      name: Value(name),
      rollNumber: Value(rollNumber),
      grade: Value(grade),
      motherTongue: Value(motherTongue),
      achievedOutcomes: Value(achievedOutcomes),
      developingOutcomes: Value(developingOutcomes),
      needsSupportOutcomes: Value(needsSupportOutcomes),
      literacyProgress: Value(literacyProgress),
      numeracyProgress: Value(numeracyProgress),
      recentEvidence: Value(recentEvidence),
      identifiedGapsJson: Value(identifiedGapsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StudentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rollNumber: serializer.fromJson<int>(json['rollNumber']),
      grade: serializer.fromJson<int>(json['grade']),
      motherTongue: serializer.fromJson<String>(json['motherTongue']),
      achievedOutcomes: serializer.fromJson<int>(json['achievedOutcomes']),
      developingOutcomes: serializer.fromJson<int>(json['developingOutcomes']),
      needsSupportOutcomes: serializer.fromJson<int>(
        json['needsSupportOutcomes'],
      ),
      literacyProgress: serializer.fromJson<double>(json['literacyProgress']),
      numeracyProgress: serializer.fromJson<double>(json['numeracyProgress']),
      recentEvidence: serializer.fromJson<String>(json['recentEvidence']),
      identifiedGapsJson: serializer.fromJson<String>(
        json['identifiedGapsJson'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'rollNumber': serializer.toJson<int>(rollNumber),
      'grade': serializer.toJson<int>(grade),
      'motherTongue': serializer.toJson<String>(motherTongue),
      'achievedOutcomes': serializer.toJson<int>(achievedOutcomes),
      'developingOutcomes': serializer.toJson<int>(developingOutcomes),
      'needsSupportOutcomes': serializer.toJson<int>(needsSupportOutcomes),
      'literacyProgress': serializer.toJson<double>(literacyProgress),
      'numeracyProgress': serializer.toJson<double>(numeracyProgress),
      'recentEvidence': serializer.toJson<String>(recentEvidence),
      'identifiedGapsJson': serializer.toJson<String>(identifiedGapsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StudentData copyWith({
    String? id,
    String? name,
    int? rollNumber,
    int? grade,
    String? motherTongue,
    int? achievedOutcomes,
    int? developingOutcomes,
    int? needsSupportOutcomes,
    double? literacyProgress,
    double? numeracyProgress,
    String? recentEvidence,
    String? identifiedGapsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StudentData(
    id: id ?? this.id,
    name: name ?? this.name,
    rollNumber: rollNumber ?? this.rollNumber,
    grade: grade ?? this.grade,
    motherTongue: motherTongue ?? this.motherTongue,
    achievedOutcomes: achievedOutcomes ?? this.achievedOutcomes,
    developingOutcomes: developingOutcomes ?? this.developingOutcomes,
    needsSupportOutcomes: needsSupportOutcomes ?? this.needsSupportOutcomes,
    literacyProgress: literacyProgress ?? this.literacyProgress,
    numeracyProgress: numeracyProgress ?? this.numeracyProgress,
    recentEvidence: recentEvidence ?? this.recentEvidence,
    identifiedGapsJson: identifiedGapsJson ?? this.identifiedGapsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StudentData copyWithCompanion(StudentsCompanion data) {
    return StudentData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rollNumber: data.rollNumber.present
          ? data.rollNumber.value
          : this.rollNumber,
      grade: data.grade.present ? data.grade.value : this.grade,
      motherTongue: data.motherTongue.present
          ? data.motherTongue.value
          : this.motherTongue,
      achievedOutcomes: data.achievedOutcomes.present
          ? data.achievedOutcomes.value
          : this.achievedOutcomes,
      developingOutcomes: data.developingOutcomes.present
          ? data.developingOutcomes.value
          : this.developingOutcomes,
      needsSupportOutcomes: data.needsSupportOutcomes.present
          ? data.needsSupportOutcomes.value
          : this.needsSupportOutcomes,
      literacyProgress: data.literacyProgress.present
          ? data.literacyProgress.value
          : this.literacyProgress,
      numeracyProgress: data.numeracyProgress.present
          ? data.numeracyProgress.value
          : this.numeracyProgress,
      recentEvidence: data.recentEvidence.present
          ? data.recentEvidence.value
          : this.recentEvidence,
      identifiedGapsJson: data.identifiedGapsJson.present
          ? data.identifiedGapsJson.value
          : this.identifiedGapsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rollNumber: $rollNumber, ')
          ..write('grade: $grade, ')
          ..write('motherTongue: $motherTongue, ')
          ..write('achievedOutcomes: $achievedOutcomes, ')
          ..write('developingOutcomes: $developingOutcomes, ')
          ..write('needsSupportOutcomes: $needsSupportOutcomes, ')
          ..write('literacyProgress: $literacyProgress, ')
          ..write('numeracyProgress: $numeracyProgress, ')
          ..write('recentEvidence: $recentEvidence, ')
          ..write('identifiedGapsJson: $identifiedGapsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    rollNumber,
    grade,
    motherTongue,
    achievedOutcomes,
    developingOutcomes,
    needsSupportOutcomes,
    literacyProgress,
    numeracyProgress,
    recentEvidence,
    identifiedGapsJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentData &&
          other.id == this.id &&
          other.name == this.name &&
          other.rollNumber == this.rollNumber &&
          other.grade == this.grade &&
          other.motherTongue == this.motherTongue &&
          other.achievedOutcomes == this.achievedOutcomes &&
          other.developingOutcomes == this.developingOutcomes &&
          other.needsSupportOutcomes == this.needsSupportOutcomes &&
          other.literacyProgress == this.literacyProgress &&
          other.numeracyProgress == this.numeracyProgress &&
          other.recentEvidence == this.recentEvidence &&
          other.identifiedGapsJson == this.identifiedGapsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StudentsCompanion extends UpdateCompanion<StudentData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rollNumber;
  final Value<int> grade;
  final Value<String> motherTongue;
  final Value<int> achievedOutcomes;
  final Value<int> developingOutcomes;
  final Value<int> needsSupportOutcomes;
  final Value<double> literacyProgress;
  final Value<double> numeracyProgress;
  final Value<String> recentEvidence;
  final Value<String> identifiedGapsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StudentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rollNumber = const Value.absent(),
    this.grade = const Value.absent(),
    this.motherTongue = const Value.absent(),
    this.achievedOutcomes = const Value.absent(),
    this.developingOutcomes = const Value.absent(),
    this.needsSupportOutcomes = const Value.absent(),
    this.literacyProgress = const Value.absent(),
    this.numeracyProgress = const Value.absent(),
    this.recentEvidence = const Value.absent(),
    this.identifiedGapsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsCompanion.insert({
    required String id,
    required String name,
    required int rollNumber,
    required int grade,
    required String motherTongue,
    this.achievedOutcomes = const Value.absent(),
    this.developingOutcomes = const Value.absent(),
    this.needsSupportOutcomes = const Value.absent(),
    this.literacyProgress = const Value.absent(),
    this.numeracyProgress = const Value.absent(),
    required String recentEvidence,
    this.identifiedGapsJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       rollNumber = Value(rollNumber),
       grade = Value(grade),
       motherTongue = Value(motherTongue),
       recentEvidence = Value(recentEvidence),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StudentData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rollNumber,
    Expression<int>? grade,
    Expression<String>? motherTongue,
    Expression<int>? achievedOutcomes,
    Expression<int>? developingOutcomes,
    Expression<int>? needsSupportOutcomes,
    Expression<double>? literacyProgress,
    Expression<double>? numeracyProgress,
    Expression<String>? recentEvidence,
    Expression<String>? identifiedGapsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rollNumber != null) 'roll_number': rollNumber,
      if (grade != null) 'grade': grade,
      if (motherTongue != null) 'mother_tongue': motherTongue,
      if (achievedOutcomes != null) 'achieved_outcomes': achievedOutcomes,
      if (developingOutcomes != null) 'developing_outcomes': developingOutcomes,
      if (needsSupportOutcomes != null)
        'needs_support_outcomes': needsSupportOutcomes,
      if (literacyProgress != null) 'literacy_progress': literacyProgress,
      if (numeracyProgress != null) 'numeracy_progress': numeracyProgress,
      if (recentEvidence != null) 'recent_evidence': recentEvidence,
      if (identifiedGapsJson != null)
        'identified_gaps_json': identifiedGapsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rollNumber,
    Value<int>? grade,
    Value<String>? motherTongue,
    Value<int>? achievedOutcomes,
    Value<int>? developingOutcomes,
    Value<int>? needsSupportOutcomes,
    Value<double>? literacyProgress,
    Value<double>? numeracyProgress,
    Value<String>? recentEvidence,
    Value<String>? identifiedGapsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StudentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      grade: grade ?? this.grade,
      motherTongue: motherTongue ?? this.motherTongue,
      achievedOutcomes: achievedOutcomes ?? this.achievedOutcomes,
      developingOutcomes: developingOutcomes ?? this.developingOutcomes,
      needsSupportOutcomes: needsSupportOutcomes ?? this.needsSupportOutcomes,
      literacyProgress: literacyProgress ?? this.literacyProgress,
      numeracyProgress: numeracyProgress ?? this.numeracyProgress,
      recentEvidence: recentEvidence ?? this.recentEvidence,
      identifiedGapsJson: identifiedGapsJson ?? this.identifiedGapsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rollNumber.present) {
      map['roll_number'] = Variable<int>(rollNumber.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (motherTongue.present) {
      map['mother_tongue'] = Variable<String>(motherTongue.value);
    }
    if (achievedOutcomes.present) {
      map['achieved_outcomes'] = Variable<int>(achievedOutcomes.value);
    }
    if (developingOutcomes.present) {
      map['developing_outcomes'] = Variable<int>(developingOutcomes.value);
    }
    if (needsSupportOutcomes.present) {
      map['needs_support_outcomes'] = Variable<int>(needsSupportOutcomes.value);
    }
    if (literacyProgress.present) {
      map['literacy_progress'] = Variable<double>(literacyProgress.value);
    }
    if (numeracyProgress.present) {
      map['numeracy_progress'] = Variable<double>(numeracyProgress.value);
    }
    if (recentEvidence.present) {
      map['recent_evidence'] = Variable<String>(recentEvidence.value);
    }
    if (identifiedGapsJson.present) {
      map['identified_gaps_json'] = Variable<String>(identifiedGapsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rollNumber: $rollNumber, ')
          ..write('grade: $grade, ')
          ..write('motherTongue: $motherTongue, ')
          ..write('achievedOutcomes: $achievedOutcomes, ')
          ..write('developingOutcomes: $developingOutcomes, ')
          ..write('needsSupportOutcomes: $needsSupportOutcomes, ')
          ..write('literacyProgress: $literacyProgress, ')
          ..write('numeracyProgress: $numeracyProgress, ')
          ..write('recentEvidence: $recentEvidence, ')
          ..write('identifiedGapsJson: $identifiedGapsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssessmentQuestionsTable extends AssessmentQuestions
    with TableInfo<$AssessmentQuestionsTable, AssessmentQuestionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssessmentQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeCodeMeta = const VerificationMeta(
    'outcomeCode',
  );
  @override
  late final GeneratedColumn<String> outcomeCode = GeneratedColumn<String>(
    'outcome_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsJsonMeta = const VerificationMeta(
    'questionsJson',
  );
  @override
  late final GeneratedColumn<String> questionsJson = GeneratedColumn<String>(
    'questions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, outcomeCode, questionsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assessment_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssessmentQuestionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('outcome_code')) {
      context.handle(
        _outcomeCodeMeta,
        outcomeCode.isAcceptableOrUnknown(
          data['outcome_code']!,
          _outcomeCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outcomeCodeMeta);
    }
    if (data.containsKey('questions_json')) {
      context.handle(
        _questionsJsonMeta,
        questionsJson.isAcceptableOrUnknown(
          data['questions_json']!,
          _questionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssessmentQuestionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssessmentQuestionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      outcomeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_code'],
      )!,
      questionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}questions_json'],
      )!,
    );
  }

  @override
  $AssessmentQuestionsTable createAlias(String alias) {
    return $AssessmentQuestionsTable(attachedDatabase, alias);
  }
}

class AssessmentQuestionData extends DataClass
    implements Insertable<AssessmentQuestionData> {
  final String id;
  final String outcomeCode;
  final String questionsJson;
  const AssessmentQuestionData({
    required this.id,
    required this.outcomeCode,
    required this.questionsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['outcome_code'] = Variable<String>(outcomeCode);
    map['questions_json'] = Variable<String>(questionsJson);
    return map;
  }

  AssessmentQuestionsCompanion toCompanion(bool nullToAbsent) {
    return AssessmentQuestionsCompanion(
      id: Value(id),
      outcomeCode: Value(outcomeCode),
      questionsJson: Value(questionsJson),
    );
  }

  factory AssessmentQuestionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssessmentQuestionData(
      id: serializer.fromJson<String>(json['id']),
      outcomeCode: serializer.fromJson<String>(json['outcomeCode']),
      questionsJson: serializer.fromJson<String>(json['questionsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'outcomeCode': serializer.toJson<String>(outcomeCode),
      'questionsJson': serializer.toJson<String>(questionsJson),
    };
  }

  AssessmentQuestionData copyWith({
    String? id,
    String? outcomeCode,
    String? questionsJson,
  }) => AssessmentQuestionData(
    id: id ?? this.id,
    outcomeCode: outcomeCode ?? this.outcomeCode,
    questionsJson: questionsJson ?? this.questionsJson,
  );
  AssessmentQuestionData copyWithCompanion(AssessmentQuestionsCompanion data) {
    return AssessmentQuestionData(
      id: data.id.present ? data.id.value : this.id,
      outcomeCode: data.outcomeCode.present
          ? data.outcomeCode.value
          : this.outcomeCode,
      questionsJson: data.questionsJson.present
          ? data.questionsJson.value
          : this.questionsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssessmentQuestionData(')
          ..write('id: $id, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('questionsJson: $questionsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, outcomeCode, questionsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssessmentQuestionData &&
          other.id == this.id &&
          other.outcomeCode == this.outcomeCode &&
          other.questionsJson == this.questionsJson);
}

class AssessmentQuestionsCompanion
    extends UpdateCompanion<AssessmentQuestionData> {
  final Value<String> id;
  final Value<String> outcomeCode;
  final Value<String> questionsJson;
  final Value<int> rowid;
  const AssessmentQuestionsCompanion({
    this.id = const Value.absent(),
    this.outcomeCode = const Value.absent(),
    this.questionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssessmentQuestionsCompanion.insert({
    required String id,
    required String outcomeCode,
    required String questionsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       outcomeCode = Value(outcomeCode),
       questionsJson = Value(questionsJson);
  static Insertable<AssessmentQuestionData> custom({
    Expression<String>? id,
    Expression<String>? outcomeCode,
    Expression<String>? questionsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (outcomeCode != null) 'outcome_code': outcomeCode,
      if (questionsJson != null) 'questions_json': questionsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssessmentQuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? outcomeCode,
    Value<String>? questionsJson,
    Value<int>? rowid,
  }) {
    return AssessmentQuestionsCompanion(
      id: id ?? this.id,
      outcomeCode: outcomeCode ?? this.outcomeCode,
      questionsJson: questionsJson ?? this.questionsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (outcomeCode.present) {
      map['outcome_code'] = Variable<String>(outcomeCode.value);
    }
    if (questionsJson.present) {
      map['questions_json'] = Variable<String>(questionsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssessmentQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('questionsJson: $questionsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssessmentResultsTable extends AssessmentResults
    with TableInfo<$AssessmentResultsTable, AssessmentResultRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssessmentResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentNameMeta = const VerificationMeta(
    'studentName',
  );
  @override
  late final GeneratedColumn<String> studentName = GeneratedColumn<String>(
    'student_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeCodeMeta = const VerificationMeta(
    'outcomeCode',
  );
  @override
  late final GeneratedColumn<String> outcomeCode = GeneratedColumn<String>(
    'outcome_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeTitleMeta = const VerificationMeta(
    'outcomeTitle',
  );
  @override
  late final GeneratedColumn<String> outcomeTitle = GeneratedColumn<String>(
    'outcome_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalQuestionsMeta = const VerificationMeta(
    'totalQuestions',
  );
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
    'total_questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unfinishedSkillMeta = const VerificationMeta(
    'unfinishedSkill',
  );
  @override
  late final GeneratedColumn<String> unfinishedSkill = GeneratedColumn<String>(
    'unfinished_skill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendedRemediationMeta =
      const VerificationMeta('recommendedRemediation');
  @override
  late final GeneratedColumn<String> recommendedRemediation =
      GeneratedColumn<String>(
        'recommended_remediation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    studentName,
    outcomeCode,
    outcomeTitle,
    totalQuestions,
    correctCount,
    status,
    unfinishedSkill,
    recommendedRemediation,
    completedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assessment_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssessmentResultRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('student_name')) {
      context.handle(
        _studentNameMeta,
        studentName.isAcceptableOrUnknown(
          data['student_name']!,
          _studentNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentNameMeta);
    }
    if (data.containsKey('outcome_code')) {
      context.handle(
        _outcomeCodeMeta,
        outcomeCode.isAcceptableOrUnknown(
          data['outcome_code']!,
          _outcomeCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outcomeCodeMeta);
    }
    if (data.containsKey('outcome_title')) {
      context.handle(
        _outcomeTitleMeta,
        outcomeTitle.isAcceptableOrUnknown(
          data['outcome_title']!,
          _outcomeTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outcomeTitleMeta);
    }
    if (data.containsKey('total_questions')) {
      context.handle(
        _totalQuestionsMeta,
        totalQuestions.isAcceptableOrUnknown(
          data['total_questions']!,
          _totalQuestionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalQuestionsMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctCountMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('unfinished_skill')) {
      context.handle(
        _unfinishedSkillMeta,
        unfinishedSkill.isAcceptableOrUnknown(
          data['unfinished_skill']!,
          _unfinishedSkillMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unfinishedSkillMeta);
    }
    if (data.containsKey('recommended_remediation')) {
      context.handle(
        _recommendedRemediationMeta,
        recommendedRemediation.isAcceptableOrUnknown(
          data['recommended_remediation']!,
          _recommendedRemediationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendedRemediationMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssessmentResultRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssessmentResultRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      studentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_name'],
      )!,
      outcomeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_code'],
      )!,
      outcomeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_title'],
      )!,
      totalQuestions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_questions'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      unfinishedSkill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unfinished_skill'],
      )!,
      recommendedRemediation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_remediation'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $AssessmentResultsTable createAlias(String alias) {
    return $AssessmentResultsTable(attachedDatabase, alias);
  }
}

class AssessmentResultRecord extends DataClass
    implements Insertable<AssessmentResultRecord> {
  final String id;
  final String studentId;
  final String studentName;
  final String outcomeCode;
  final String outcomeTitle;
  final int totalQuestions;
  final int correctCount;
  final String status;
  final String unfinishedSkill;
  final String recommendedRemediation;
  final DateTime completedAt;
  final String syncStatus;
  const AssessmentResultRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.outcomeCode,
    required this.outcomeTitle,
    required this.totalQuestions,
    required this.correctCount,
    required this.status,
    required this.unfinishedSkill,
    required this.recommendedRemediation,
    required this.completedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['student_id'] = Variable<String>(studentId);
    map['student_name'] = Variable<String>(studentName);
    map['outcome_code'] = Variable<String>(outcomeCode);
    map['outcome_title'] = Variable<String>(outcomeTitle);
    map['total_questions'] = Variable<int>(totalQuestions);
    map['correct_count'] = Variable<int>(correctCount);
    map['status'] = Variable<String>(status);
    map['unfinished_skill'] = Variable<String>(unfinishedSkill);
    map['recommended_remediation'] = Variable<String>(recommendedRemediation);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  AssessmentResultsCompanion toCompanion(bool nullToAbsent) {
    return AssessmentResultsCompanion(
      id: Value(id),
      studentId: Value(studentId),
      studentName: Value(studentName),
      outcomeCode: Value(outcomeCode),
      outcomeTitle: Value(outcomeTitle),
      totalQuestions: Value(totalQuestions),
      correctCount: Value(correctCount),
      status: Value(status),
      unfinishedSkill: Value(unfinishedSkill),
      recommendedRemediation: Value(recommendedRemediation),
      completedAt: Value(completedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory AssessmentResultRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssessmentResultRecord(
      id: serializer.fromJson<String>(json['id']),
      studentId: serializer.fromJson<String>(json['studentId']),
      studentName: serializer.fromJson<String>(json['studentName']),
      outcomeCode: serializer.fromJson<String>(json['outcomeCode']),
      outcomeTitle: serializer.fromJson<String>(json['outcomeTitle']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      status: serializer.fromJson<String>(json['status']),
      unfinishedSkill: serializer.fromJson<String>(json['unfinishedSkill']),
      recommendedRemediation: serializer.fromJson<String>(
        json['recommendedRemediation'],
      ),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'studentId': serializer.toJson<String>(studentId),
      'studentName': serializer.toJson<String>(studentName),
      'outcomeCode': serializer.toJson<String>(outcomeCode),
      'outcomeTitle': serializer.toJson<String>(outcomeTitle),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'correctCount': serializer.toJson<int>(correctCount),
      'status': serializer.toJson<String>(status),
      'unfinishedSkill': serializer.toJson<String>(unfinishedSkill),
      'recommendedRemediation': serializer.toJson<String>(
        recommendedRemediation,
      ),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  AssessmentResultRecord copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? outcomeCode,
    String? outcomeTitle,
    int? totalQuestions,
    int? correctCount,
    String? status,
    String? unfinishedSkill,
    String? recommendedRemediation,
    DateTime? completedAt,
    String? syncStatus,
  }) => AssessmentResultRecord(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    studentName: studentName ?? this.studentName,
    outcomeCode: outcomeCode ?? this.outcomeCode,
    outcomeTitle: outcomeTitle ?? this.outcomeTitle,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    correctCount: correctCount ?? this.correctCount,
    status: status ?? this.status,
    unfinishedSkill: unfinishedSkill ?? this.unfinishedSkill,
    recommendedRemediation:
        recommendedRemediation ?? this.recommendedRemediation,
    completedAt: completedAt ?? this.completedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  AssessmentResultRecord copyWithCompanion(AssessmentResultsCompanion data) {
    return AssessmentResultRecord(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      studentName: data.studentName.present
          ? data.studentName.value
          : this.studentName,
      outcomeCode: data.outcomeCode.present
          ? data.outcomeCode.value
          : this.outcomeCode,
      outcomeTitle: data.outcomeTitle.present
          ? data.outcomeTitle.value
          : this.outcomeTitle,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      status: data.status.present ? data.status.value : this.status,
      unfinishedSkill: data.unfinishedSkill.present
          ? data.unfinishedSkill.value
          : this.unfinishedSkill,
      recommendedRemediation: data.recommendedRemediation.present
          ? data.recommendedRemediation.value
          : this.recommendedRemediation,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssessmentResultRecord(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('studentName: $studentName, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('outcomeTitle: $outcomeTitle, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctCount: $correctCount, ')
          ..write('status: $status, ')
          ..write('unfinishedSkill: $unfinishedSkill, ')
          ..write('recommendedRemediation: $recommendedRemediation, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentId,
    studentName,
    outcomeCode,
    outcomeTitle,
    totalQuestions,
    correctCount,
    status,
    unfinishedSkill,
    recommendedRemediation,
    completedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssessmentResultRecord &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.studentName == this.studentName &&
          other.outcomeCode == this.outcomeCode &&
          other.outcomeTitle == this.outcomeTitle &&
          other.totalQuestions == this.totalQuestions &&
          other.correctCount == this.correctCount &&
          other.status == this.status &&
          other.unfinishedSkill == this.unfinishedSkill &&
          other.recommendedRemediation == this.recommendedRemediation &&
          other.completedAt == this.completedAt &&
          other.syncStatus == this.syncStatus);
}

class AssessmentResultsCompanion
    extends UpdateCompanion<AssessmentResultRecord> {
  final Value<String> id;
  final Value<String> studentId;
  final Value<String> studentName;
  final Value<String> outcomeCode;
  final Value<String> outcomeTitle;
  final Value<int> totalQuestions;
  final Value<int> correctCount;
  final Value<String> status;
  final Value<String> unfinishedSkill;
  final Value<String> recommendedRemediation;
  final Value<DateTime> completedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const AssessmentResultsCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.studentName = const Value.absent(),
    this.outcomeCode = const Value.absent(),
    this.outcomeTitle = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.status = const Value.absent(),
    this.unfinishedSkill = const Value.absent(),
    this.recommendedRemediation = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssessmentResultsCompanion.insert({
    required String id,
    required String studentId,
    required String studentName,
    required String outcomeCode,
    required String outcomeTitle,
    required int totalQuestions,
    required int correctCount,
    required String status,
    required String unfinishedSkill,
    required String recommendedRemediation,
    required DateTime completedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       studentId = Value(studentId),
       studentName = Value(studentName),
       outcomeCode = Value(outcomeCode),
       outcomeTitle = Value(outcomeTitle),
       totalQuestions = Value(totalQuestions),
       correctCount = Value(correctCount),
       status = Value(status),
       unfinishedSkill = Value(unfinishedSkill),
       recommendedRemediation = Value(recommendedRemediation),
       completedAt = Value(completedAt);
  static Insertable<AssessmentResultRecord> custom({
    Expression<String>? id,
    Expression<String>? studentId,
    Expression<String>? studentName,
    Expression<String>? outcomeCode,
    Expression<String>? outcomeTitle,
    Expression<int>? totalQuestions,
    Expression<int>? correctCount,
    Expression<String>? status,
    Expression<String>? unfinishedSkill,
    Expression<String>? recommendedRemediation,
    Expression<DateTime>? completedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (studentName != null) 'student_name': studentName,
      if (outcomeCode != null) 'outcome_code': outcomeCode,
      if (outcomeTitle != null) 'outcome_title': outcomeTitle,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (correctCount != null) 'correct_count': correctCount,
      if (status != null) 'status': status,
      if (unfinishedSkill != null) 'unfinished_skill': unfinishedSkill,
      if (recommendedRemediation != null)
        'recommended_remediation': recommendedRemediation,
      if (completedAt != null) 'completed_at': completedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssessmentResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? studentId,
    Value<String>? studentName,
    Value<String>? outcomeCode,
    Value<String>? outcomeTitle,
    Value<int>? totalQuestions,
    Value<int>? correctCount,
    Value<String>? status,
    Value<String>? unfinishedSkill,
    Value<String>? recommendedRemediation,
    Value<DateTime>? completedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return AssessmentResultsCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      outcomeCode: outcomeCode ?? this.outcomeCode,
      outcomeTitle: outcomeTitle ?? this.outcomeTitle,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      status: status ?? this.status,
      unfinishedSkill: unfinishedSkill ?? this.unfinishedSkill,
      recommendedRemediation:
          recommendedRemediation ?? this.recommendedRemediation,
      completedAt: completedAt ?? this.completedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (studentName.present) {
      map['student_name'] = Variable<String>(studentName.value);
    }
    if (outcomeCode.present) {
      map['outcome_code'] = Variable<String>(outcomeCode.value);
    }
    if (outcomeTitle.present) {
      map['outcome_title'] = Variable<String>(outcomeTitle.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (unfinishedSkill.present) {
      map['unfinished_skill'] = Variable<String>(unfinishedSkill.value);
    }
    if (recommendedRemediation.present) {
      map['recommended_remediation'] = Variable<String>(
        recommendedRemediation.value,
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssessmentResultsCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('studentName: $studentName, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('outcomeTitle: $outcomeTitle, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctCount: $correctCount, ')
          ..write('status: $status, ')
          ..write('unfinishedSkill: $unfinishedSkill, ')
          ..write('recommendedRemediation: $recommendedRemediation, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningGapsTable extends LearningGaps
    with TableInfo<$LearningGapsTable, LearningGapData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningGapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeCodeMeta = const VerificationMeta(
    'outcomeCode',
  );
  @override
  late final GeneratedColumn<String> outcomeCode = GeneratedColumn<String>(
    'outcome_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skillMeta = const VerificationMeta('skill');
  @override
  late final GeneratedColumn<String> skill = GeneratedColumn<String>(
    'skill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootCauseMeta = const VerificationMeta(
    'rootCause',
  );
  @override
  late final GeneratedColumn<String> rootCause = GeneratedColumn<String>(
    'root_cause',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remediationUsedMeta = const VerificationMeta(
    'remediationUsed',
  );
  @override
  late final GeneratedColumn<String> remediationUsed = GeneratedColumn<String>(
    'remediation_used',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isResolvedMeta = const VerificationMeta(
    'isResolved',
  );
  @override
  late final GeneratedColumn<bool> isResolved = GeneratedColumn<bool>(
    'is_resolved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_resolved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    outcomeCode,
    skill,
    rootCause,
    remediationUsed,
    status,
    isResolved,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_gaps';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningGapData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('outcome_code')) {
      context.handle(
        _outcomeCodeMeta,
        outcomeCode.isAcceptableOrUnknown(
          data['outcome_code']!,
          _outcomeCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outcomeCodeMeta);
    }
    if (data.containsKey('skill')) {
      context.handle(
        _skillMeta,
        skill.isAcceptableOrUnknown(data['skill']!, _skillMeta),
      );
    } else if (isInserting) {
      context.missing(_skillMeta);
    }
    if (data.containsKey('root_cause')) {
      context.handle(
        _rootCauseMeta,
        rootCause.isAcceptableOrUnknown(data['root_cause']!, _rootCauseMeta),
      );
    } else if (isInserting) {
      context.missing(_rootCauseMeta);
    }
    if (data.containsKey('remediation_used')) {
      context.handle(
        _remediationUsedMeta,
        remediationUsed.isAcceptableOrUnknown(
          data['remediation_used']!,
          _remediationUsedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remediationUsedMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('is_resolved')) {
      context.handle(
        _isResolvedMeta,
        isResolved.isAcceptableOrUnknown(data['is_resolved']!, _isResolvedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningGapData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningGapData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      outcomeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_code'],
      )!,
      skill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill'],
      )!,
      rootCause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_cause'],
      )!,
      remediationUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remediation_used'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isResolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_resolved'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LearningGapsTable createAlias(String alias) {
    return $LearningGapsTable(attachedDatabase, alias);
  }
}

class LearningGapData extends DataClass implements Insertable<LearningGapData> {
  final String id;
  final String studentId;
  final String outcomeCode;
  final String skill;
  final String rootCause;
  final String remediationUsed;
  final String status;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LearningGapData({
    required this.id,
    required this.studentId,
    required this.outcomeCode,
    required this.skill,
    required this.rootCause,
    required this.remediationUsed,
    required this.status,
    required this.isResolved,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['student_id'] = Variable<String>(studentId);
    map['outcome_code'] = Variable<String>(outcomeCode);
    map['skill'] = Variable<String>(skill);
    map['root_cause'] = Variable<String>(rootCause);
    map['remediation_used'] = Variable<String>(remediationUsed);
    map['status'] = Variable<String>(status);
    map['is_resolved'] = Variable<bool>(isResolved);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LearningGapsCompanion toCompanion(bool nullToAbsent) {
    return LearningGapsCompanion(
      id: Value(id),
      studentId: Value(studentId),
      outcomeCode: Value(outcomeCode),
      skill: Value(skill),
      rootCause: Value(rootCause),
      remediationUsed: Value(remediationUsed),
      status: Value(status),
      isResolved: Value(isResolved),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LearningGapData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningGapData(
      id: serializer.fromJson<String>(json['id']),
      studentId: serializer.fromJson<String>(json['studentId']),
      outcomeCode: serializer.fromJson<String>(json['outcomeCode']),
      skill: serializer.fromJson<String>(json['skill']),
      rootCause: serializer.fromJson<String>(json['rootCause']),
      remediationUsed: serializer.fromJson<String>(json['remediationUsed']),
      status: serializer.fromJson<String>(json['status']),
      isResolved: serializer.fromJson<bool>(json['isResolved']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'studentId': serializer.toJson<String>(studentId),
      'outcomeCode': serializer.toJson<String>(outcomeCode),
      'skill': serializer.toJson<String>(skill),
      'rootCause': serializer.toJson<String>(rootCause),
      'remediationUsed': serializer.toJson<String>(remediationUsed),
      'status': serializer.toJson<String>(status),
      'isResolved': serializer.toJson<bool>(isResolved),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LearningGapData copyWith({
    String? id,
    String? studentId,
    String? outcomeCode,
    String? skill,
    String? rootCause,
    String? remediationUsed,
    String? status,
    bool? isResolved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LearningGapData(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    outcomeCode: outcomeCode ?? this.outcomeCode,
    skill: skill ?? this.skill,
    rootCause: rootCause ?? this.rootCause,
    remediationUsed: remediationUsed ?? this.remediationUsed,
    status: status ?? this.status,
    isResolved: isResolved ?? this.isResolved,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LearningGapData copyWithCompanion(LearningGapsCompanion data) {
    return LearningGapData(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      outcomeCode: data.outcomeCode.present
          ? data.outcomeCode.value
          : this.outcomeCode,
      skill: data.skill.present ? data.skill.value : this.skill,
      rootCause: data.rootCause.present ? data.rootCause.value : this.rootCause,
      remediationUsed: data.remediationUsed.present
          ? data.remediationUsed.value
          : this.remediationUsed,
      status: data.status.present ? data.status.value : this.status,
      isResolved: data.isResolved.present
          ? data.isResolved.value
          : this.isResolved,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningGapData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('skill: $skill, ')
          ..write('rootCause: $rootCause, ')
          ..write('remediationUsed: $remediationUsed, ')
          ..write('status: $status, ')
          ..write('isResolved: $isResolved, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentId,
    outcomeCode,
    skill,
    rootCause,
    remediationUsed,
    status,
    isResolved,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningGapData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.outcomeCode == this.outcomeCode &&
          other.skill == this.skill &&
          other.rootCause == this.rootCause &&
          other.remediationUsed == this.remediationUsed &&
          other.status == this.status &&
          other.isResolved == this.isResolved &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LearningGapsCompanion extends UpdateCompanion<LearningGapData> {
  final Value<String> id;
  final Value<String> studentId;
  final Value<String> outcomeCode;
  final Value<String> skill;
  final Value<String> rootCause;
  final Value<String> remediationUsed;
  final Value<String> status;
  final Value<bool> isResolved;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LearningGapsCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.outcomeCode = const Value.absent(),
    this.skill = const Value.absent(),
    this.rootCause = const Value.absent(),
    this.remediationUsed = const Value.absent(),
    this.status = const Value.absent(),
    this.isResolved = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningGapsCompanion.insert({
    required String id,
    required String studentId,
    required String outcomeCode,
    required String skill,
    required String rootCause,
    required String remediationUsed,
    required String status,
    this.isResolved = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       studentId = Value(studentId),
       outcomeCode = Value(outcomeCode),
       skill = Value(skill),
       rootCause = Value(rootCause),
       remediationUsed = Value(remediationUsed),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LearningGapData> custom({
    Expression<String>? id,
    Expression<String>? studentId,
    Expression<String>? outcomeCode,
    Expression<String>? skill,
    Expression<String>? rootCause,
    Expression<String>? remediationUsed,
    Expression<String>? status,
    Expression<bool>? isResolved,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (outcomeCode != null) 'outcome_code': outcomeCode,
      if (skill != null) 'skill': skill,
      if (rootCause != null) 'root_cause': rootCause,
      if (remediationUsed != null) 'remediation_used': remediationUsed,
      if (status != null) 'status': status,
      if (isResolved != null) 'is_resolved': isResolved,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningGapsCompanion copyWith({
    Value<String>? id,
    Value<String>? studentId,
    Value<String>? outcomeCode,
    Value<String>? skill,
    Value<String>? rootCause,
    Value<String>? remediationUsed,
    Value<String>? status,
    Value<bool>? isResolved,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LearningGapsCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      outcomeCode: outcomeCode ?? this.outcomeCode,
      skill: skill ?? this.skill,
      rootCause: rootCause ?? this.rootCause,
      remediationUsed: remediationUsed ?? this.remediationUsed,
      status: status ?? this.status,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (outcomeCode.present) {
      map['outcome_code'] = Variable<String>(outcomeCode.value);
    }
    if (skill.present) {
      map['skill'] = Variable<String>(skill.value);
    }
    if (rootCause.present) {
      map['root_cause'] = Variable<String>(rootCause.value);
    }
    if (remediationUsed.present) {
      map['remediation_used'] = Variable<String>(remediationUsed.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isResolved.present) {
      map['is_resolved'] = Variable<bool>(isResolved.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningGapsCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('skill: $skill, ')
          ..write('rootCause: $rootCause, ')
          ..write('remediationUsed: $remediationUsed, ')
          ..write('status: $status, ')
          ..write('isResolved: $isResolved, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemedialRecommendationsTable extends RemedialRecommendations
    with TableInfo<$RemedialRecommendationsTable, RemedialRecommendationData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemedialRecommendationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeCodeMeta = const VerificationMeta(
    'outcomeCode',
  );
  @override
  late final GeneratedColumn<String> outcomeCode = GeneratedColumn<String>(
    'outcome_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _culturalHookMeta = const VerificationMeta(
    'culturalHook',
  );
  @override
  late final GeneratedColumn<String> culturalHook = GeneratedColumn<String>(
    'cultural_hook',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    outcomeCode,
    title,
    subject,
    culturalHook,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remedial_recommendations';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemedialRecommendationData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('outcome_code')) {
      context.handle(
        _outcomeCodeMeta,
        outcomeCode.isAcceptableOrUnknown(
          data['outcome_code']!,
          _outcomeCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outcomeCodeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('cultural_hook')) {
      context.handle(
        _culturalHookMeta,
        culturalHook.isAcceptableOrUnknown(
          data['cultural_hook']!,
          _culturalHookMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_culturalHookMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemedialRecommendationData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemedialRecommendationData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      ),
      outcomeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_code'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      culturalHook: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cultural_hook'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $RemedialRecommendationsTable createAlias(String alias) {
    return $RemedialRecommendationsTable(attachedDatabase, alias);
  }
}

class RemedialRecommendationData extends DataClass
    implements Insertable<RemedialRecommendationData> {
  final String id;
  final String? studentId;
  final String outcomeCode;
  final String title;
  final String subject;
  final String culturalHook;
  final String reason;
  const RemedialRecommendationData({
    required this.id,
    this.studentId,
    required this.outcomeCode,
    required this.title,
    required this.subject,
    required this.culturalHook,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<String>(studentId);
    }
    map['outcome_code'] = Variable<String>(outcomeCode);
    map['title'] = Variable<String>(title);
    map['subject'] = Variable<String>(subject);
    map['cultural_hook'] = Variable<String>(culturalHook);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  RemedialRecommendationsCompanion toCompanion(bool nullToAbsent) {
    return RemedialRecommendationsCompanion(
      id: Value(id),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      outcomeCode: Value(outcomeCode),
      title: Value(title),
      subject: Value(subject),
      culturalHook: Value(culturalHook),
      reason: Value(reason),
    );
  }

  factory RemedialRecommendationData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemedialRecommendationData(
      id: serializer.fromJson<String>(json['id']),
      studentId: serializer.fromJson<String?>(json['studentId']),
      outcomeCode: serializer.fromJson<String>(json['outcomeCode']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String>(json['subject']),
      culturalHook: serializer.fromJson<String>(json['culturalHook']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'studentId': serializer.toJson<String?>(studentId),
      'outcomeCode': serializer.toJson<String>(outcomeCode),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String>(subject),
      'culturalHook': serializer.toJson<String>(culturalHook),
      'reason': serializer.toJson<String>(reason),
    };
  }

  RemedialRecommendationData copyWith({
    String? id,
    Value<String?> studentId = const Value.absent(),
    String? outcomeCode,
    String? title,
    String? subject,
    String? culturalHook,
    String? reason,
  }) => RemedialRecommendationData(
    id: id ?? this.id,
    studentId: studentId.present ? studentId.value : this.studentId,
    outcomeCode: outcomeCode ?? this.outcomeCode,
    title: title ?? this.title,
    subject: subject ?? this.subject,
    culturalHook: culturalHook ?? this.culturalHook,
    reason: reason ?? this.reason,
  );
  RemedialRecommendationData copyWithCompanion(
    RemedialRecommendationsCompanion data,
  ) {
    return RemedialRecommendationData(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      outcomeCode: data.outcomeCode.present
          ? data.outcomeCode.value
          : this.outcomeCode,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      culturalHook: data.culturalHook.present
          ? data.culturalHook.value
          : this.culturalHook,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemedialRecommendationData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('culturalHook: $culturalHook, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentId,
    outcomeCode,
    title,
    subject,
    culturalHook,
    reason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemedialRecommendationData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.outcomeCode == this.outcomeCode &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.culturalHook == this.culturalHook &&
          other.reason == this.reason);
}

class RemedialRecommendationsCompanion
    extends UpdateCompanion<RemedialRecommendationData> {
  final Value<String> id;
  final Value<String?> studentId;
  final Value<String> outcomeCode;
  final Value<String> title;
  final Value<String> subject;
  final Value<String> culturalHook;
  final Value<String> reason;
  final Value<int> rowid;
  const RemedialRecommendationsCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.outcomeCode = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.culturalHook = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemedialRecommendationsCompanion.insert({
    required String id,
    this.studentId = const Value.absent(),
    required String outcomeCode,
    required String title,
    required String subject,
    required String culturalHook,
    required String reason,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       outcomeCode = Value(outcomeCode),
       title = Value(title),
       subject = Value(subject),
       culturalHook = Value(culturalHook),
       reason = Value(reason);
  static Insertable<RemedialRecommendationData> custom({
    Expression<String>? id,
    Expression<String>? studentId,
    Expression<String>? outcomeCode,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<String>? culturalHook,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (outcomeCode != null) 'outcome_code': outcomeCode,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (culturalHook != null) 'cultural_hook': culturalHook,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemedialRecommendationsCompanion copyWith({
    Value<String>? id,
    Value<String?>? studentId,
    Value<String>? outcomeCode,
    Value<String>? title,
    Value<String>? subject,
    Value<String>? culturalHook,
    Value<String>? reason,
    Value<int>? rowid,
  }) {
    return RemedialRecommendationsCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      outcomeCode: outcomeCode ?? this.outcomeCode,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      culturalHook: culturalHook ?? this.culturalHook,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (outcomeCode.present) {
      map['outcome_code'] = Variable<String>(outcomeCode.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (culturalHook.present) {
      map['cultural_hook'] = Variable<String>(culturalHook.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemedialRecommendationsCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('culturalHook: $culturalHook, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedMaterialsTable extends SavedMaterials
    with TableInfo<$SavedMaterialsTable, SavedMaterialData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedMaterialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleHiMeta = const VerificationMeta(
    'titleHi',
  );
  @override
  late final GeneratedColumn<String> titleHi = GeneratedColumn<String>(
    'title_hi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeCodeMeta = const VerificationMeta(
    'outcomeCode',
  );
  @override
  late final GeneratedColumn<String> outcomeCode = GeneratedColumn<String>(
    'outcome_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentJsonMeta = const VerificationMeta(
    'contentJson',
  );
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
    'content_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    titleHi,
    grade,
    subject,
    outcomeCode,
    language,
    difficulty,
    contentJson,
    createdAt,
    isFavorite,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_materials';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedMaterialData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_hi')) {
      context.handle(
        _titleHiMeta,
        titleHi.isAcceptableOrUnknown(data['title_hi']!, _titleHiMeta),
      );
    } else if (isInserting) {
      context.missing(_titleHiMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('outcome_code')) {
      context.handle(
        _outcomeCodeMeta,
        outcomeCode.isAcceptableOrUnknown(
          data['outcome_code']!,
          _outcomeCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outcomeCodeMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('content_json')) {
      context.handle(
        _contentJsonMeta,
        contentJson.isAcceptableOrUnknown(
          data['content_json']!,
          _contentJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedMaterialData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedMaterialData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_hi'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      outcomeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_code'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      contentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
    );
  }

  @override
  $SavedMaterialsTable createAlias(String alias) {
    return $SavedMaterialsTable(attachedDatabase, alias);
  }
}

class SavedMaterialData extends DataClass
    implements Insertable<SavedMaterialData> {
  final String id;
  final String type;
  final String title;
  final String titleHi;
  final int grade;
  final String subject;
  final String outcomeCode;
  final String language;
  final String difficulty;
  final String contentJson;
  final DateTime createdAt;
  final bool isFavorite;
  const SavedMaterialData({
    required this.id,
    required this.type,
    required this.title,
    required this.titleHi,
    required this.grade,
    required this.subject,
    required this.outcomeCode,
    required this.language,
    required this.difficulty,
    required this.contentJson,
    required this.createdAt,
    required this.isFavorite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['title_hi'] = Variable<String>(titleHi);
    map['grade'] = Variable<int>(grade);
    map['subject'] = Variable<String>(subject);
    map['outcome_code'] = Variable<String>(outcomeCode);
    map['language'] = Variable<String>(language);
    map['difficulty'] = Variable<String>(difficulty);
    map['content_json'] = Variable<String>(contentJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  SavedMaterialsCompanion toCompanion(bool nullToAbsent) {
    return SavedMaterialsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      titleHi: Value(titleHi),
      grade: Value(grade),
      subject: Value(subject),
      outcomeCode: Value(outcomeCode),
      language: Value(language),
      difficulty: Value(difficulty),
      contentJson: Value(contentJson),
      createdAt: Value(createdAt),
      isFavorite: Value(isFavorite),
    );
  }

  factory SavedMaterialData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedMaterialData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      titleHi: serializer.fromJson<String>(json['titleHi']),
      grade: serializer.fromJson<int>(json['grade']),
      subject: serializer.fromJson<String>(json['subject']),
      outcomeCode: serializer.fromJson<String>(json['outcomeCode']),
      language: serializer.fromJson<String>(json['language']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'titleHi': serializer.toJson<String>(titleHi),
      'grade': serializer.toJson<int>(grade),
      'subject': serializer.toJson<String>(subject),
      'outcomeCode': serializer.toJson<String>(outcomeCode),
      'language': serializer.toJson<String>(language),
      'difficulty': serializer.toJson<String>(difficulty),
      'contentJson': serializer.toJson<String>(contentJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  SavedMaterialData copyWith({
    String? id,
    String? type,
    String? title,
    String? titleHi,
    int? grade,
    String? subject,
    String? outcomeCode,
    String? language,
    String? difficulty,
    String? contentJson,
    DateTime? createdAt,
    bool? isFavorite,
  }) => SavedMaterialData(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    titleHi: titleHi ?? this.titleHi,
    grade: grade ?? this.grade,
    subject: subject ?? this.subject,
    outcomeCode: outcomeCode ?? this.outcomeCode,
    language: language ?? this.language,
    difficulty: difficulty ?? this.difficulty,
    contentJson: contentJson ?? this.contentJson,
    createdAt: createdAt ?? this.createdAt,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  SavedMaterialData copyWithCompanion(SavedMaterialsCompanion data) {
    return SavedMaterialData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      titleHi: data.titleHi.present ? data.titleHi.value : this.titleHi,
      grade: data.grade.present ? data.grade.value : this.grade,
      subject: data.subject.present ? data.subject.value : this.subject,
      outcomeCode: data.outcomeCode.present
          ? data.outcomeCode.value
          : this.outcomeCode,
      language: data.language.present ? data.language.value : this.language,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      contentJson: data.contentJson.present
          ? data.contentJson.value
          : this.contentJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedMaterialData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('titleHi: $titleHi, ')
          ..write('grade: $grade, ')
          ..write('subject: $subject, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('language: $language, ')
          ..write('difficulty: $difficulty, ')
          ..write('contentJson: $contentJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    titleHi,
    grade,
    subject,
    outcomeCode,
    language,
    difficulty,
    contentJson,
    createdAt,
    isFavorite,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedMaterialData &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.titleHi == this.titleHi &&
          other.grade == this.grade &&
          other.subject == this.subject &&
          other.outcomeCode == this.outcomeCode &&
          other.language == this.language &&
          other.difficulty == this.difficulty &&
          other.contentJson == this.contentJson &&
          other.createdAt == this.createdAt &&
          other.isFavorite == this.isFavorite);
}

class SavedMaterialsCompanion extends UpdateCompanion<SavedMaterialData> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String> titleHi;
  final Value<int> grade;
  final Value<String> subject;
  final Value<String> outcomeCode;
  final Value<String> language;
  final Value<String> difficulty;
  final Value<String> contentJson;
  final Value<DateTime> createdAt;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const SavedMaterialsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.titleHi = const Value.absent(),
    this.grade = const Value.absent(),
    this.subject = const Value.absent(),
    this.outcomeCode = const Value.absent(),
    this.language = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedMaterialsCompanion.insert({
    required String id,
    required String type,
    required String title,
    required String titleHi,
    required int grade,
    required String subject,
    required String outcomeCode,
    required String language,
    required String difficulty,
    required String contentJson,
    required DateTime createdAt,
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       titleHi = Value(titleHi),
       grade = Value(grade),
       subject = Value(subject),
       outcomeCode = Value(outcomeCode),
       language = Value(language),
       difficulty = Value(difficulty),
       contentJson = Value(contentJson),
       createdAt = Value(createdAt);
  static Insertable<SavedMaterialData> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? titleHi,
    Expression<int>? grade,
    Expression<String>? subject,
    Expression<String>? outcomeCode,
    Expression<String>? language,
    Expression<String>? difficulty,
    Expression<String>? contentJson,
    Expression<DateTime>? createdAt,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (titleHi != null) 'title_hi': titleHi,
      if (grade != null) 'grade': grade,
      if (subject != null) 'subject': subject,
      if (outcomeCode != null) 'outcome_code': outcomeCode,
      if (language != null) 'language': language,
      if (difficulty != null) 'difficulty': difficulty,
      if (contentJson != null) 'content_json': contentJson,
      if (createdAt != null) 'created_at': createdAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedMaterialsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String>? titleHi,
    Value<int>? grade,
    Value<String>? subject,
    Value<String>? outcomeCode,
    Value<String>? language,
    Value<String>? difficulty,
    Value<String>? contentJson,
    Value<DateTime>? createdAt,
    Value<bool>? isFavorite,
    Value<int>? rowid,
  }) {
    return SavedMaterialsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      titleHi: titleHi ?? this.titleHi,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      outcomeCode: outcomeCode ?? this.outcomeCode,
      language: language ?? this.language,
      difficulty: difficulty ?? this.difficulty,
      contentJson: contentJson ?? this.contentJson,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (titleHi.present) {
      map['title_hi'] = Variable<String>(titleHi.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (outcomeCode.present) {
      map['outcome_code'] = Variable<String>(outcomeCode.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedMaterialsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('titleHi: $titleHi, ')
          ..write('grade: $grade, ')
          ..write('subject: $subject, ')
          ..write('outcomeCode: $outcomeCode, ')
          ..write('language: $language, ')
          ..write('difficulty: $difficulty, ')
          ..write('contentJson: $contentJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranslationHistoryTable extends TranslationHistory
    with TableInfo<$TranslationHistoryTable, TranslationHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTeacherMeta = const VerificationMeta(
    'isTeacher',
  );
  @override
  late final GeneratedColumn<bool> isTeacher = GeneratedColumn<bool>(
    'is_teacher',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_teacher" IN (0, 1))',
    ),
  );
  static const VerificationMeta _speakerNameMeta = const VerificationMeta(
    'speakerName',
  );
  @override
  late final GeneratedColumn<String> speakerName = GeneratedColumn<String>(
    'speaker_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTextMeta = const VerificationMeta(
    'originalText',
  );
  @override
  late final GeneratedColumn<String> originalText = GeneratedColumn<String>(
    'original_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translatedTextMeta = const VerificationMeta(
    'translatedText',
  );
  @override
  late final GeneratedColumn<String> translatedText = GeneratedColumn<String>(
    'translated_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetLanguageMeta = const VerificationMeta(
    'targetLanguage',
  );
  @override
  late final GeneratedColumn<String> targetLanguage = GeneratedColumn<String>(
    'target_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latencyMsMeta = const VerificationMeta(
    'latencyMs',
  );
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
    'latency_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOfflineNmtMeta = const VerificationMeta(
    'isOfflineNmt',
  );
  @override
  late final GeneratedColumn<bool> isOfflineNmt = GeneratedColumn<bool>(
    'is_offline_nmt',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_offline_nmt" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isTeacher,
    speakerName,
    originalText,
    translatedText,
    targetLanguage,
    latencyMs,
    isOfflineNmt,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translation_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<TranslationHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_teacher')) {
      context.handle(
        _isTeacherMeta,
        isTeacher.isAcceptableOrUnknown(data['is_teacher']!, _isTeacherMeta),
      );
    } else if (isInserting) {
      context.missing(_isTeacherMeta);
    }
    if (data.containsKey('speaker_name')) {
      context.handle(
        _speakerNameMeta,
        speakerName.isAcceptableOrUnknown(
          data['speaker_name']!,
          _speakerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_speakerNameMeta);
    }
    if (data.containsKey('original_text')) {
      context.handle(
        _originalTextMeta,
        originalText.isAcceptableOrUnknown(
          data['original_text']!,
          _originalTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalTextMeta);
    }
    if (data.containsKey('translated_text')) {
      context.handle(
        _translatedTextMeta,
        translatedText.isAcceptableOrUnknown(
          data['translated_text']!,
          _translatedTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translatedTextMeta);
    }
    if (data.containsKey('target_language')) {
      context.handle(
        _targetLanguageMeta,
        targetLanguage.isAcceptableOrUnknown(
          data['target_language']!,
          _targetLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetLanguageMeta);
    }
    if (data.containsKey('latency_ms')) {
      context.handle(
        _latencyMsMeta,
        latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta),
      );
    } else if (isInserting) {
      context.missing(_latencyMsMeta);
    }
    if (data.containsKey('is_offline_nmt')) {
      context.handle(
        _isOfflineNmtMeta,
        isOfflineNmt.isAcceptableOrUnknown(
          data['is_offline_nmt']!,
          _isOfflineNmtMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TranslationHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranslationHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isTeacher: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_teacher'],
      )!,
      speakerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}speaker_name'],
      )!,
      originalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_text'],
      )!,
      translatedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translated_text'],
      )!,
      targetLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_language'],
      )!,
      latencyMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_ms'],
      )!,
      isOfflineNmt: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_offline_nmt'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $TranslationHistoryTable createAlias(String alias) {
    return $TranslationHistoryTable(attachedDatabase, alias);
  }
}

class TranslationHistoryData extends DataClass
    implements Insertable<TranslationHistoryData> {
  final String id;
  final bool isTeacher;
  final String speakerName;
  final String originalText;
  final String translatedText;
  final String targetLanguage;
  final int latencyMs;
  final bool isOfflineNmt;
  final DateTime timestamp;
  const TranslationHistoryData({
    required this.id,
    required this.isTeacher,
    required this.speakerName,
    required this.originalText,
    required this.translatedText,
    required this.targetLanguage,
    required this.latencyMs,
    required this.isOfflineNmt,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_teacher'] = Variable<bool>(isTeacher);
    map['speaker_name'] = Variable<String>(speakerName);
    map['original_text'] = Variable<String>(originalText);
    map['translated_text'] = Variable<String>(translatedText);
    map['target_language'] = Variable<String>(targetLanguage);
    map['latency_ms'] = Variable<int>(latencyMs);
    map['is_offline_nmt'] = Variable<bool>(isOfflineNmt);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  TranslationHistoryCompanion toCompanion(bool nullToAbsent) {
    return TranslationHistoryCompanion(
      id: Value(id),
      isTeacher: Value(isTeacher),
      speakerName: Value(speakerName),
      originalText: Value(originalText),
      translatedText: Value(translatedText),
      targetLanguage: Value(targetLanguage),
      latencyMs: Value(latencyMs),
      isOfflineNmt: Value(isOfflineNmt),
      timestamp: Value(timestamp),
    );
  }

  factory TranslationHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranslationHistoryData(
      id: serializer.fromJson<String>(json['id']),
      isTeacher: serializer.fromJson<bool>(json['isTeacher']),
      speakerName: serializer.fromJson<String>(json['speakerName']),
      originalText: serializer.fromJson<String>(json['originalText']),
      translatedText: serializer.fromJson<String>(json['translatedText']),
      targetLanguage: serializer.fromJson<String>(json['targetLanguage']),
      latencyMs: serializer.fromJson<int>(json['latencyMs']),
      isOfflineNmt: serializer.fromJson<bool>(json['isOfflineNmt']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isTeacher': serializer.toJson<bool>(isTeacher),
      'speakerName': serializer.toJson<String>(speakerName),
      'originalText': serializer.toJson<String>(originalText),
      'translatedText': serializer.toJson<String>(translatedText),
      'targetLanguage': serializer.toJson<String>(targetLanguage),
      'latencyMs': serializer.toJson<int>(latencyMs),
      'isOfflineNmt': serializer.toJson<bool>(isOfflineNmt),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  TranslationHistoryData copyWith({
    String? id,
    bool? isTeacher,
    String? speakerName,
    String? originalText,
    String? translatedText,
    String? targetLanguage,
    int? latencyMs,
    bool? isOfflineNmt,
    DateTime? timestamp,
  }) => TranslationHistoryData(
    id: id ?? this.id,
    isTeacher: isTeacher ?? this.isTeacher,
    speakerName: speakerName ?? this.speakerName,
    originalText: originalText ?? this.originalText,
    translatedText: translatedText ?? this.translatedText,
    targetLanguage: targetLanguage ?? this.targetLanguage,
    latencyMs: latencyMs ?? this.latencyMs,
    isOfflineNmt: isOfflineNmt ?? this.isOfflineNmt,
    timestamp: timestamp ?? this.timestamp,
  );
  TranslationHistoryData copyWithCompanion(TranslationHistoryCompanion data) {
    return TranslationHistoryData(
      id: data.id.present ? data.id.value : this.id,
      isTeacher: data.isTeacher.present ? data.isTeacher.value : this.isTeacher,
      speakerName: data.speakerName.present
          ? data.speakerName.value
          : this.speakerName,
      originalText: data.originalText.present
          ? data.originalText.value
          : this.originalText,
      translatedText: data.translatedText.present
          ? data.translatedText.value
          : this.translatedText,
      targetLanguage: data.targetLanguage.present
          ? data.targetLanguage.value
          : this.targetLanguage,
      latencyMs: data.latencyMs.present ? data.latencyMs.value : this.latencyMs,
      isOfflineNmt: data.isOfflineNmt.present
          ? data.isOfflineNmt.value
          : this.isOfflineNmt,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranslationHistoryData(')
          ..write('id: $id, ')
          ..write('isTeacher: $isTeacher, ')
          ..write('speakerName: $speakerName, ')
          ..write('originalText: $originalText, ')
          ..write('translatedText: $translatedText, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('isOfflineNmt: $isOfflineNmt, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isTeacher,
    speakerName,
    originalText,
    translatedText,
    targetLanguage,
    latencyMs,
    isOfflineNmt,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranslationHistoryData &&
          other.id == this.id &&
          other.isTeacher == this.isTeacher &&
          other.speakerName == this.speakerName &&
          other.originalText == this.originalText &&
          other.translatedText == this.translatedText &&
          other.targetLanguage == this.targetLanguage &&
          other.latencyMs == this.latencyMs &&
          other.isOfflineNmt == this.isOfflineNmt &&
          other.timestamp == this.timestamp);
}

class TranslationHistoryCompanion
    extends UpdateCompanion<TranslationHistoryData> {
  final Value<String> id;
  final Value<bool> isTeacher;
  final Value<String> speakerName;
  final Value<String> originalText;
  final Value<String> translatedText;
  final Value<String> targetLanguage;
  final Value<int> latencyMs;
  final Value<bool> isOfflineNmt;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const TranslationHistoryCompanion({
    this.id = const Value.absent(),
    this.isTeacher = const Value.absent(),
    this.speakerName = const Value.absent(),
    this.originalText = const Value.absent(),
    this.translatedText = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.isOfflineNmt = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranslationHistoryCompanion.insert({
    required String id,
    required bool isTeacher,
    required String speakerName,
    required String originalText,
    required String translatedText,
    required String targetLanguage,
    required int latencyMs,
    this.isOfflineNmt = const Value.absent(),
    required DateTime timestamp,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       isTeacher = Value(isTeacher),
       speakerName = Value(speakerName),
       originalText = Value(originalText),
       translatedText = Value(translatedText),
       targetLanguage = Value(targetLanguage),
       latencyMs = Value(latencyMs),
       timestamp = Value(timestamp);
  static Insertable<TranslationHistoryData> custom({
    Expression<String>? id,
    Expression<bool>? isTeacher,
    Expression<String>? speakerName,
    Expression<String>? originalText,
    Expression<String>? translatedText,
    Expression<String>? targetLanguage,
    Expression<int>? latencyMs,
    Expression<bool>? isOfflineNmt,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isTeacher != null) 'is_teacher': isTeacher,
      if (speakerName != null) 'speaker_name': speakerName,
      if (originalText != null) 'original_text': originalText,
      if (translatedText != null) 'translated_text': translatedText,
      if (targetLanguage != null) 'target_language': targetLanguage,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (isOfflineNmt != null) 'is_offline_nmt': isOfflineNmt,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranslationHistoryCompanion copyWith({
    Value<String>? id,
    Value<bool>? isTeacher,
    Value<String>? speakerName,
    Value<String>? originalText,
    Value<String>? translatedText,
    Value<String>? targetLanguage,
    Value<int>? latencyMs,
    Value<bool>? isOfflineNmt,
    Value<DateTime>? timestamp,
    Value<int>? rowid,
  }) {
    return TranslationHistoryCompanion(
      id: id ?? this.id,
      isTeacher: isTeacher ?? this.isTeacher,
      speakerName: speakerName ?? this.speakerName,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      latencyMs: latencyMs ?? this.latencyMs,
      isOfflineNmt: isOfflineNmt ?? this.isOfflineNmt,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isTeacher.present) {
      map['is_teacher'] = Variable<bool>(isTeacher.value);
    }
    if (speakerName.present) {
      map['speaker_name'] = Variable<String>(speakerName.value);
    }
    if (originalText.present) {
      map['original_text'] = Variable<String>(originalText.value);
    }
    if (translatedText.present) {
      map['translated_text'] = Variable<String>(translatedText.value);
    }
    if (targetLanguage.present) {
      map['target_language'] = Variable<String>(targetLanguage.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (isOfflineNmt.present) {
      map['is_offline_nmt'] = Variable<bool>(isOfflineNmt.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationHistoryCompanion(')
          ..write('id: $id, ')
          ..write('isTeacher: $isTeacher, ')
          ..write('speakerName: $speakerName, ')
          ..write('originalText: $originalText, ')
          ..write('translatedText: $translatedText, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('isOfflineNmt: $isOfflineNmt, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranslationFeedbackTable extends TranslationFeedback
    with TableInfo<$TranslationFeedbackTable, TranslationFeedbackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationFeedbackTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalMeta = const VerificationMeta(
    'original',
  );
  @override
  late final GeneratedColumn<String> original = GeneratedColumn<String>(
    'original',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translatedMeta = const VerificationMeta(
    'translated',
  );
  @override
  late final GeneratedColumn<String> translated = GeneratedColumn<String>(
    'translated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issueTypeMeta = const VerificationMeta(
    'issueType',
  );
  @override
  late final GeneratedColumn<String> issueType = GeneratedColumn<String>(
    'issue_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    original,
    translated,
    issueType,
    comment,
    timestamp,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translation_feedback';
  @override
  VerificationContext validateIntegrity(
    Insertable<TranslationFeedbackData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('original')) {
      context.handle(
        _originalMeta,
        original.isAcceptableOrUnknown(data['original']!, _originalMeta),
      );
    } else if (isInserting) {
      context.missing(_originalMeta);
    }
    if (data.containsKey('translated')) {
      context.handle(
        _translatedMeta,
        translated.isAcceptableOrUnknown(data['translated']!, _translatedMeta),
      );
    } else if (isInserting) {
      context.missing(_translatedMeta);
    }
    if (data.containsKey('issue_type')) {
      context.handle(
        _issueTypeMeta,
        issueType.isAcceptableOrUnknown(data['issue_type']!, _issueTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_issueTypeMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TranslationFeedbackData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranslationFeedbackData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      original: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original'],
      )!,
      translated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translated'],
      )!,
      issueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_type'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TranslationFeedbackTable createAlias(String alias) {
    return $TranslationFeedbackTable(attachedDatabase, alias);
  }
}

class TranslationFeedbackData extends DataClass
    implements Insertable<TranslationFeedbackData> {
  final String id;
  final String original;
  final String translated;
  final String issueType;
  final String? comment;
  final DateTime timestamp;
  final String syncStatus;
  const TranslationFeedbackData({
    required this.id,
    required this.original,
    required this.translated,
    required this.issueType,
    this.comment,
    required this.timestamp,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['original'] = Variable<String>(original);
    map['translated'] = Variable<String>(translated);
    map['issue_type'] = Variable<String>(issueType);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  TranslationFeedbackCompanion toCompanion(bool nullToAbsent) {
    return TranslationFeedbackCompanion(
      id: Value(id),
      original: Value(original),
      translated: Value(translated),
      issueType: Value(issueType),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      timestamp: Value(timestamp),
      syncStatus: Value(syncStatus),
    );
  }

  factory TranslationFeedbackData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranslationFeedbackData(
      id: serializer.fromJson<String>(json['id']),
      original: serializer.fromJson<String>(json['original']),
      translated: serializer.fromJson<String>(json['translated']),
      issueType: serializer.fromJson<String>(json['issueType']),
      comment: serializer.fromJson<String?>(json['comment']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'original': serializer.toJson<String>(original),
      'translated': serializer.toJson<String>(translated),
      'issueType': serializer.toJson<String>(issueType),
      'comment': serializer.toJson<String?>(comment),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  TranslationFeedbackData copyWith({
    String? id,
    String? original,
    String? translated,
    String? issueType,
    Value<String?> comment = const Value.absent(),
    DateTime? timestamp,
    String? syncStatus,
  }) => TranslationFeedbackData(
    id: id ?? this.id,
    original: original ?? this.original,
    translated: translated ?? this.translated,
    issueType: issueType ?? this.issueType,
    comment: comment.present ? comment.value : this.comment,
    timestamp: timestamp ?? this.timestamp,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TranslationFeedbackData copyWithCompanion(TranslationFeedbackCompanion data) {
    return TranslationFeedbackData(
      id: data.id.present ? data.id.value : this.id,
      original: data.original.present ? data.original.value : this.original,
      translated: data.translated.present
          ? data.translated.value
          : this.translated,
      issueType: data.issueType.present ? data.issueType.value : this.issueType,
      comment: data.comment.present ? data.comment.value : this.comment,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranslationFeedbackData(')
          ..write('id: $id, ')
          ..write('original: $original, ')
          ..write('translated: $translated, ')
          ..write('issueType: $issueType, ')
          ..write('comment: $comment, ')
          ..write('timestamp: $timestamp, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    original,
    translated,
    issueType,
    comment,
    timestamp,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranslationFeedbackData &&
          other.id == this.id &&
          other.original == this.original &&
          other.translated == this.translated &&
          other.issueType == this.issueType &&
          other.comment == this.comment &&
          other.timestamp == this.timestamp &&
          other.syncStatus == this.syncStatus);
}

class TranslationFeedbackCompanion
    extends UpdateCompanion<TranslationFeedbackData> {
  final Value<String> id;
  final Value<String> original;
  final Value<String> translated;
  final Value<String> issueType;
  final Value<String?> comment;
  final Value<DateTime> timestamp;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const TranslationFeedbackCompanion({
    this.id = const Value.absent(),
    this.original = const Value.absent(),
    this.translated = const Value.absent(),
    this.issueType = const Value.absent(),
    this.comment = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranslationFeedbackCompanion.insert({
    required String id,
    required String original,
    required String translated,
    required String issueType,
    this.comment = const Value.absent(),
    required DateTime timestamp,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       original = Value(original),
       translated = Value(translated),
       issueType = Value(issueType),
       timestamp = Value(timestamp);
  static Insertable<TranslationFeedbackData> custom({
    Expression<String>? id,
    Expression<String>? original,
    Expression<String>? translated,
    Expression<String>? issueType,
    Expression<String>? comment,
    Expression<DateTime>? timestamp,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (original != null) 'original': original,
      if (translated != null) 'translated': translated,
      if (issueType != null) 'issue_type': issueType,
      if (comment != null) 'comment': comment,
      if (timestamp != null) 'timestamp': timestamp,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranslationFeedbackCompanion copyWith({
    Value<String>? id,
    Value<String>? original,
    Value<String>? translated,
    Value<String>? issueType,
    Value<String?>? comment,
    Value<DateTime>? timestamp,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return TranslationFeedbackCompanion(
      id: id ?? this.id,
      original: original ?? this.original,
      translated: translated ?? this.translated,
      issueType: issueType ?? this.issueType,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (original.present) {
      map['original'] = Variable<String>(original.value);
    }
    if (translated.present) {
      map['translated'] = Variable<String>(translated.value);
    }
    if (issueType.present) {
      map['issue_type'] = Variable<String>(issueType.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationFeedbackCompanion(')
          ..write('id: $id, ')
          ..write('original: $original, ')
          ..write('translated: $translated, ')
          ..write('issueType: $issueType, ')
          ..write('comment: $comment, ')
          ..write('timestamp: $timestamp, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuickPhrasesTable extends QuickPhrases
    with TableInfo<$QuickPhrasesTable, QuickPhraseData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuickPhrasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hindiMeta = const VerificationMeta('hindi');
  @override
  late final GeneratedColumn<String> hindi = GeneratedColumn<String>(
    'hindi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hoMeta = const VerificationMeta('ho');
  @override
  late final GeneratedColumn<String> ho = GeneratedColumn<String>(
    'ho',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mundariMeta = const VerificationMeta(
    'mundari',
  );
  @override
  late final GeneratedColumn<String> mundari = GeneratedColumn<String>(
    'mundari',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _santaliMeta = const VerificationMeta(
    'santali',
  );
  @override
  late final GeneratedColumn<String> santali = GeneratedColumn<String>(
    'santali',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    hindi,
    ho,
    mundari,
    santali,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quick_phrases';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuickPhraseData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('hindi')) {
      context.handle(
        _hindiMeta,
        hindi.isAcceptableOrUnknown(data['hindi']!, _hindiMeta),
      );
    } else if (isInserting) {
      context.missing(_hindiMeta);
    }
    if (data.containsKey('ho')) {
      context.handle(_hoMeta, ho.isAcceptableOrUnknown(data['ho']!, _hoMeta));
    } else if (isInserting) {
      context.missing(_hoMeta);
    }
    if (data.containsKey('mundari')) {
      context.handle(
        _mundariMeta,
        mundari.isAcceptableOrUnknown(data['mundari']!, _mundariMeta),
      );
    } else if (isInserting) {
      context.missing(_mundariMeta);
    }
    if (data.containsKey('santali')) {
      context.handle(
        _santaliMeta,
        santali.isAcceptableOrUnknown(data['santali']!, _santaliMeta),
      );
    } else if (isInserting) {
      context.missing(_santaliMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuickPhraseData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuickPhraseData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      hindi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hindi'],
      )!,
      ho: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ho'],
      )!,
      mundari: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mundari'],
      )!,
      santali: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}santali'],
      )!,
    );
  }

  @override
  $QuickPhrasesTable createAlias(String alias) {
    return $QuickPhrasesTable(attachedDatabase, alias);
  }
}

class QuickPhraseData extends DataClass implements Insertable<QuickPhraseData> {
  final String id;
  final String category;
  final String hindi;
  final String ho;
  final String mundari;
  final String santali;
  const QuickPhraseData({
    required this.id,
    required this.category,
    required this.hindi,
    required this.ho,
    required this.mundari,
    required this.santali,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['hindi'] = Variable<String>(hindi);
    map['ho'] = Variable<String>(ho);
    map['mundari'] = Variable<String>(mundari);
    map['santali'] = Variable<String>(santali);
    return map;
  }

  QuickPhrasesCompanion toCompanion(bool nullToAbsent) {
    return QuickPhrasesCompanion(
      id: Value(id),
      category: Value(category),
      hindi: Value(hindi),
      ho: Value(ho),
      mundari: Value(mundari),
      santali: Value(santali),
    );
  }

  factory QuickPhraseData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuickPhraseData(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      hindi: serializer.fromJson<String>(json['hindi']),
      ho: serializer.fromJson<String>(json['ho']),
      mundari: serializer.fromJson<String>(json['mundari']),
      santali: serializer.fromJson<String>(json['santali']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'hindi': serializer.toJson<String>(hindi),
      'ho': serializer.toJson<String>(ho),
      'mundari': serializer.toJson<String>(mundari),
      'santali': serializer.toJson<String>(santali),
    };
  }

  QuickPhraseData copyWith({
    String? id,
    String? category,
    String? hindi,
    String? ho,
    String? mundari,
    String? santali,
  }) => QuickPhraseData(
    id: id ?? this.id,
    category: category ?? this.category,
    hindi: hindi ?? this.hindi,
    ho: ho ?? this.ho,
    mundari: mundari ?? this.mundari,
    santali: santali ?? this.santali,
  );
  QuickPhraseData copyWithCompanion(QuickPhrasesCompanion data) {
    return QuickPhraseData(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      hindi: data.hindi.present ? data.hindi.value : this.hindi,
      ho: data.ho.present ? data.ho.value : this.ho,
      mundari: data.mundari.present ? data.mundari.value : this.mundari,
      santali: data.santali.present ? data.santali.value : this.santali,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuickPhraseData(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('hindi: $hindi, ')
          ..write('ho: $ho, ')
          ..write('mundari: $mundari, ')
          ..write('santali: $santali')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, category, hindi, ho, mundari, santali);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuickPhraseData &&
          other.id == this.id &&
          other.category == this.category &&
          other.hindi == this.hindi &&
          other.ho == this.ho &&
          other.mundari == this.mundari &&
          other.santali == this.santali);
}

class QuickPhrasesCompanion extends UpdateCompanion<QuickPhraseData> {
  final Value<String> id;
  final Value<String> category;
  final Value<String> hindi;
  final Value<String> ho;
  final Value<String> mundari;
  final Value<String> santali;
  final Value<int> rowid;
  const QuickPhrasesCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.hindi = const Value.absent(),
    this.ho = const Value.absent(),
    this.mundari = const Value.absent(),
    this.santali = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuickPhrasesCompanion.insert({
    required String id,
    required String category,
    required String hindi,
    required String ho,
    required String mundari,
    required String santali,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       hindi = Value(hindi),
       ho = Value(ho),
       mundari = Value(mundari),
       santali = Value(santali);
  static Insertable<QuickPhraseData> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? hindi,
    Expression<String>? ho,
    Expression<String>? mundari,
    Expression<String>? santali,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (hindi != null) 'hindi': hindi,
      if (ho != null) 'ho': ho,
      if (mundari != null) 'mundari': mundari,
      if (santali != null) 'santali': santali,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuickPhrasesCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<String>? hindi,
    Value<String>? ho,
    Value<String>? mundari,
    Value<String>? santali,
    Value<int>? rowid,
  }) {
    return QuickPhrasesCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      hindi: hindi ?? this.hindi,
      ho: ho ?? this.ho,
      mundari: mundari ?? this.mundari,
      santali: santali ?? this.santali,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (hindi.present) {
      map['hindi'] = Variable<String>(hindi.value);
    }
    if (ho.present) {
      map['ho'] = Variable<String>(ho.value);
    }
    if (mundari.present) {
      map['mundari'] = Variable<String>(mundari.value);
    }
    if (santali.present) {
      map['santali'] = Variable<String>(santali.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuickPhrasesCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('hindi: $hindi, ')
          ..write('ho: $ho, ')
          ..write('mundari: $mundari, ')
          ..write('santali: $santali, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LanguagePacksTable extends LanguagePacks
    with TableInfo<$LanguagePacksTable, LanguagePackRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LanguagePacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMbMeta = const VerificationMeta('sizeMb');
  @override
  late final GeneratedColumn<int> sizeMb = GeneratedColumn<int>(
    'size_mb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    language,
    sizeMb,
    version,
    status,
    progress,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'language_packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LanguagePackRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('size_mb')) {
      context.handle(
        _sizeMbMeta,
        sizeMb.isAcceptableOrUnknown(data['size_mb']!, _sizeMbMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMbMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LanguagePackRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LanguagePackRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      sizeMb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_mb'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
    );
  }

  @override
  $LanguagePacksTable createAlias(String alias) {
    return $LanguagePacksTable(attachedDatabase, alias);
  }
}

class LanguagePackRecord extends DataClass
    implements Insertable<LanguagePackRecord> {
  final String id;
  final String language;
  final int sizeMb;
  final String version;
  final String status;
  final double progress;
  const LanguagePackRecord({
    required this.id,
    required this.language,
    required this.sizeMb,
    required this.version,
    required this.status,
    required this.progress,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language'] = Variable<String>(language);
    map['size_mb'] = Variable<int>(sizeMb);
    map['version'] = Variable<String>(version);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    return map;
  }

  LanguagePacksCompanion toCompanion(bool nullToAbsent) {
    return LanguagePacksCompanion(
      id: Value(id),
      language: Value(language),
      sizeMb: Value(sizeMb),
      version: Value(version),
      status: Value(status),
      progress: Value(progress),
    );
  }

  factory LanguagePackRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LanguagePackRecord(
      id: serializer.fromJson<String>(json['id']),
      language: serializer.fromJson<String>(json['language']),
      sizeMb: serializer.fromJson<int>(json['sizeMb']),
      version: serializer.fromJson<String>(json['version']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'language': serializer.toJson<String>(language),
      'sizeMb': serializer.toJson<int>(sizeMb),
      'version': serializer.toJson<String>(version),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
    };
  }

  LanguagePackRecord copyWith({
    String? id,
    String? language,
    int? sizeMb,
    String? version,
    String? status,
    double? progress,
  }) => LanguagePackRecord(
    id: id ?? this.id,
    language: language ?? this.language,
    sizeMb: sizeMb ?? this.sizeMb,
    version: version ?? this.version,
    status: status ?? this.status,
    progress: progress ?? this.progress,
  );
  LanguagePackRecord copyWithCompanion(LanguagePacksCompanion data) {
    return LanguagePackRecord(
      id: data.id.present ? data.id.value : this.id,
      language: data.language.present ? data.language.value : this.language,
      sizeMb: data.sizeMb.present ? data.sizeMb.value : this.sizeMb,
      version: data.version.present ? data.version.value : this.version,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LanguagePackRecord(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('sizeMb: $sizeMb, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('progress: $progress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, language, sizeMb, version, status, progress);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LanguagePackRecord &&
          other.id == this.id &&
          other.language == this.language &&
          other.sizeMb == this.sizeMb &&
          other.version == this.version &&
          other.status == this.status &&
          other.progress == this.progress);
}

class LanguagePacksCompanion extends UpdateCompanion<LanguagePackRecord> {
  final Value<String> id;
  final Value<String> language;
  final Value<int> sizeMb;
  final Value<String> version;
  final Value<String> status;
  final Value<double> progress;
  final Value<int> rowid;
  const LanguagePacksCompanion({
    this.id = const Value.absent(),
    this.language = const Value.absent(),
    this.sizeMb = const Value.absent(),
    this.version = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LanguagePacksCompanion.insert({
    required String id,
    required String language,
    required int sizeMb,
    required String version,
    required String status,
    this.progress = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       language = Value(language),
       sizeMb = Value(sizeMb),
       version = Value(version),
       status = Value(status);
  static Insertable<LanguagePackRecord> custom({
    Expression<String>? id,
    Expression<String>? language,
    Expression<int>? sizeMb,
    Expression<String>? version,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (language != null) 'language': language,
      if (sizeMb != null) 'size_mb': sizeMb,
      if (version != null) 'version': version,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LanguagePacksCompanion copyWith({
    Value<String>? id,
    Value<String>? language,
    Value<int>? sizeMb,
    Value<String>? version,
    Value<String>? status,
    Value<double>? progress,
    Value<int>? rowid,
  }) {
    return LanguagePacksCompanion(
      id: id ?? this.id,
      language: language ?? this.language,
      sizeMb: sizeMb ?? this.sizeMb,
      version: version ?? this.version,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (sizeMb.present) {
      map['size_mb'] = Variable<int>(sizeMb.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LanguagePacksCompanion(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('sizeMb: $sizeMb, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentPacksTable extends ContentPacks
    with TableInfo<$ContentPacksTable, ContentPackRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentPacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMbMeta = const VerificationMeta('sizeMb');
  @override
  late final GeneratedColumn<int> sizeMb = GeneratedColumn<int>(
    'size_mb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isInstalledMeta = const VerificationMeta(
    'isInstalled',
  );
  @override
  late final GeneratedColumn<bool> isInstalled = GeneratedColumn<bool>(
    'is_installed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_installed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    sizeMb,
    isInstalled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentPackRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('size_mb')) {
      context.handle(
        _sizeMbMeta,
        sizeMb.isAcceptableOrUnknown(data['size_mb']!, _sizeMbMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMbMeta);
    }
    if (data.containsKey('is_installed')) {
      context.handle(
        _isInstalledMeta,
        isInstalled.isAcceptableOrUnknown(
          data['is_installed']!,
          _isInstalledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContentPackRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentPackRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      sizeMb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_mb'],
      )!,
      isInstalled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_installed'],
      )!,
    );
  }

  @override
  $ContentPacksTable createAlias(String alias) {
    return $ContentPacksTable(attachedDatabase, alias);
  }
}

class ContentPackRecord extends DataClass
    implements Insertable<ContentPackRecord> {
  final String id;
  final String title;
  final String description;
  final int sizeMb;
  final bool isInstalled;
  const ContentPackRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.sizeMb,
    required this.isInstalled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['size_mb'] = Variable<int>(sizeMb);
    map['is_installed'] = Variable<bool>(isInstalled);
    return map;
  }

  ContentPacksCompanion toCompanion(bool nullToAbsent) {
    return ContentPacksCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      sizeMb: Value(sizeMb),
      isInstalled: Value(isInstalled),
    );
  }

  factory ContentPackRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentPackRecord(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      sizeMb: serializer.fromJson<int>(json['sizeMb']),
      isInstalled: serializer.fromJson<bool>(json['isInstalled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'sizeMb': serializer.toJson<int>(sizeMb),
      'isInstalled': serializer.toJson<bool>(isInstalled),
    };
  }

  ContentPackRecord copyWith({
    String? id,
    String? title,
    String? description,
    int? sizeMb,
    bool? isInstalled,
  }) => ContentPackRecord(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    sizeMb: sizeMb ?? this.sizeMb,
    isInstalled: isInstalled ?? this.isInstalled,
  );
  ContentPackRecord copyWithCompanion(ContentPacksCompanion data) {
    return ContentPackRecord(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      sizeMb: data.sizeMb.present ? data.sizeMb.value : this.sizeMb,
      isInstalled: data.isInstalled.present
          ? data.isInstalled.value
          : this.isInstalled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentPackRecord(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('sizeMb: $sizeMb, ')
          ..write('isInstalled: $isInstalled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, sizeMb, isInstalled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentPackRecord &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.sizeMb == this.sizeMb &&
          other.isInstalled == this.isInstalled);
}

class ContentPacksCompanion extends UpdateCompanion<ContentPackRecord> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<int> sizeMb;
  final Value<bool> isInstalled;
  final Value<int> rowid;
  const ContentPacksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.sizeMb = const Value.absent(),
    this.isInstalled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentPacksCompanion.insert({
    required String id,
    required String title,
    required String description,
    required int sizeMb,
    this.isInstalled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       description = Value(description),
       sizeMb = Value(sizeMb);
  static Insertable<ContentPackRecord> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? sizeMb,
    Expression<bool>? isInstalled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (sizeMb != null) 'size_mb': sizeMb,
      if (isInstalled != null) 'is_installed': isInstalled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentPacksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<int>? sizeMb,
    Value<bool>? isInstalled,
    Value<int>? rowid,
  }) {
    return ContentPacksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sizeMb: sizeMb ?? this.sizeMb,
      isInstalled: isInstalled ?? this.isInstalled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sizeMb.present) {
      map['size_mb'] = Variable<int>(sizeMb.value);
    }
    if (isInstalled.present) {
      map['is_installed'] = Variable<bool>(isInstalled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentPacksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('sizeMb: $sizeMb, ')
          ..write('isInstalled: $isInstalled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    payload,
    createdAt,
    updatedAt,
    retryCount,
    lastAttemptAt,
    status,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String status;
  final String? errorMessage;
  const SyncQueueData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    required this.retryCount,
    this.lastAttemptAt,
    required this.status,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      retryCount: Value(retryCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  SyncQueueData copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? retryCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    String? status,
    Value<String?> errorMessage = const Value.absent(),
  }) => SyncQueueData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    retryCount: retryCount ?? this.retryCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    payload,
    createdAt,
    updatedAt,
    retryCount,
    lastAttemptAt,
    status,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.retryCount == this.retryCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> retryCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.retryCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? retryCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? retryCount,
    Value<DateTime?>? lastAttemptAt,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TeachersTable teachers = $TeachersTable(this);
  late final $ClassroomsTable classrooms = $ClassroomsTable(this);
  late final $NipunOutcomesTable nipunOutcomes = $NipunOutcomesTable(this);
  late final $LessonsTable lessons = $LessonsTable(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $LessonDeliveryProgressTable lessonDeliveryProgress =
      $LessonDeliveryProgressTable(this);
  late final $LocalContextsTable localContexts = $LocalContextsTable(this);
  late final $StudentsTable students = $StudentsTable(this);
  late final $AssessmentQuestionsTable assessmentQuestions =
      $AssessmentQuestionsTable(this);
  late final $AssessmentResultsTable assessmentResults =
      $AssessmentResultsTable(this);
  late final $LearningGapsTable learningGaps = $LearningGapsTable(this);
  late final $RemedialRecommendationsTable remedialRecommendations =
      $RemedialRecommendationsTable(this);
  late final $SavedMaterialsTable savedMaterials = $SavedMaterialsTable(this);
  late final $TranslationHistoryTable translationHistory =
      $TranslationHistoryTable(this);
  late final $TranslationFeedbackTable translationFeedback =
      $TranslationFeedbackTable(this);
  late final $QuickPhrasesTable quickPhrases = $QuickPhrasesTable(this);
  late final $LanguagePacksTable languagePacks = $LanguagePacksTable(this);
  late final $ContentPacksTable contentPacks = $ContentPacksTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final TeacherDao teacherDao = TeacherDao(this as AppDatabase);
  late final CurriculumDao curriculumDao = CurriculumDao(this as AppDatabase);
  late final LessonDao lessonDao = LessonDao(this as AppDatabase);
  late final StudentDao studentDao = StudentDao(this as AppDatabase);
  late final AssessmentDao assessmentDao = AssessmentDao(this as AppDatabase);
  late final ResourceDao resourceDao = ResourceDao(this as AppDatabase);
  late final TranslationDao translationDao = TranslationDao(
    this as AppDatabase,
  );
  late final OfflineDao offlineDao = OfflineDao(this as AppDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    teachers,
    classrooms,
    nipunOutcomes,
    lessons,
    activities,
    lessonDeliveryProgress,
    localContexts,
    students,
    assessmentQuestions,
    assessmentResults,
    learningGaps,
    remedialRecommendations,
    savedMaterials,
    translationHistory,
    translationFeedback,
    quickPhrases,
    languagePacks,
    contentPacks,
    syncQueue,
  ];
}

typedef $$TeachersTableCreateCompanionBuilder = TeachersCompanion Function({
  required String id,
  required String name,
  required String school,
  required String district,
  required String state,
  required String classesTaughtJson,
  required String teachingLanguage,
  required String supportedLanguagesJson,
  required String activeSessionLanguage,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TeachersTableUpdateCompanionBuilder = TeachersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> school,
  Value<String> district,
  Value<String> state,
  Value<String> classesTaughtJson,
  Value<String> teachingLanguage,
  Value<String> supportedLanguagesJson,
  Value<String> activeSessionLanguage,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TeachersTableFilterComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get school => $composableBuilder(
    column: $table.school,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classesTaughtJson => $composableBuilder(
    column: $table.classesTaughtJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teachingLanguage => $composableBuilder(
    column: $table.teachingLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supportedLanguagesJson => $composableBuilder(
    column: $table.supportedLanguagesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeSessionLanguage => $composableBuilder(
    column: $table.activeSessionLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TeachersTableOrderingComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get school => $composableBuilder(
    column: $table.school,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classesTaughtJson => $composableBuilder(
    column: $table.classesTaughtJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teachingLanguage => $composableBuilder(
    column: $table.teachingLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supportedLanguagesJson => $composableBuilder(
    column: $table.supportedLanguagesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeSessionLanguage => $composableBuilder(
    column: $table.activeSessionLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeachersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get school =>
      $composableBuilder(column: $table.school, builder: (column) => column);

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get classesTaughtJson => $composableBuilder(
    column: $table.classesTaughtJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teachingLanguage => $composableBuilder(
    column: $table.teachingLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supportedLanguagesJson => $composableBuilder(
    column: $table.supportedLanguagesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeSessionLanguage => $composableBuilder(
    column: $table.activeSessionLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TeachersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeachersTable,
          TeacherData,
          $$TeachersTableFilterComposer,
          $$TeachersTableOrderingComposer,
          $$TeachersTableAnnotationComposer,
          $$TeachersTableCreateCompanionBuilder,
          $$TeachersTableUpdateCompanionBuilder,
          (
            TeacherData,
            BaseReferences<_$AppDatabase, $TeachersTable, TeacherData>,
          ),
          TeacherData,
          PrefetchHooks Function()
        > {
  $$TeachersTableTableManager(_$AppDatabase db, $TeachersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeachersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeachersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeachersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> school = const Value.absent(),
                Value<String> district = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> classesTaughtJson = const Value.absent(),
                Value<String> teachingLanguage = const Value.absent(),
                Value<String> supportedLanguagesJson = const Value.absent(),
                Value<String> activeSessionLanguage = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeachersCompanion(
                id: id,
                name: name,
                school: school,
                district: district,
                state: state,
                classesTaughtJson: classesTaughtJson,
                teachingLanguage: teachingLanguage,
                supportedLanguagesJson: supportedLanguagesJson,
                activeSessionLanguage: activeSessionLanguage,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String school,
                required String district,
                required String state,
                required String classesTaughtJson,
                required String teachingLanguage,
                required String supportedLanguagesJson,
                required String activeSessionLanguage,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TeachersCompanion.insert(
                id: id,
                name: name,
                school: school,
                district: district,
                state: state,
                classesTaughtJson: classesTaughtJson,
                teachingLanguage: teachingLanguage,
                supportedLanguagesJson: supportedLanguagesJson,
                activeSessionLanguage: activeSessionLanguage,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TeachersTable, TeacherData>(table),
                  BaseReferences<_$AppDatabase, $TeachersTable, TeacherData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TeachersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeachersTable,
      TeacherData,
      $$TeachersTableFilterComposer,
      $$TeachersTableOrderingComposer,
      $$TeachersTableAnnotationComposer,
      $$TeachersTableCreateCompanionBuilder,
      $$TeachersTableUpdateCompanionBuilder,
      (TeacherData, BaseReferences<_$AppDatabase, $TeachersTable, TeacherData>),
      TeacherData,
      PrefetchHooks Function()
    >;
typedef $$ClassroomsTableCreateCompanionBuilder = ClassroomsCompanion Function({
  required String id,
  required int grade,
  required String name,
  Value<String> section,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$ClassroomsTableUpdateCompanionBuilder = ClassroomsCompanion Function({
  Value<String> id,
  Value<int> grade,
  Value<String> name,
  Value<String> section,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$ClassroomsTableFilterComposer
    extends Composer<_$AppDatabase, $ClassroomsTable> {
  $$ClassroomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClassroomsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassroomsTable> {
  $$ClassroomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClassroomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassroomsTable> {
  $$ClassroomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$ClassroomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassroomsTable,
          ClassroomData,
          $$ClassroomsTableFilterComposer,
          $$ClassroomsTableOrderingComposer,
          $$ClassroomsTableAnnotationComposer,
          $$ClassroomsTableCreateCompanionBuilder,
          $$ClassroomsTableUpdateCompanionBuilder,
          (
            ClassroomData,
            BaseReferences<_$AppDatabase, $ClassroomsTable, ClassroomData>,
          ),
          ClassroomData,
          PrefetchHooks Function()
        > {
  $$ClassroomsTableTableManager(_$AppDatabase db, $ClassroomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassroomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassroomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassroomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> grade = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassroomsCompanion(
                id: id,
                grade: grade,
                name: name,
                section: section,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int grade,
                required String name,
                Value<String> section = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassroomsCompanion.insert(
                id: id,
                grade: grade,
                name: name,
                section: section,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClassroomsTable, ClassroomData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ClassroomsTable,
                    ClassroomData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClassroomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassroomsTable,
      ClassroomData,
      $$ClassroomsTableFilterComposer,
      $$ClassroomsTableOrderingComposer,
      $$ClassroomsTableAnnotationComposer,
      $$ClassroomsTableCreateCompanionBuilder,
      $$ClassroomsTableUpdateCompanionBuilder,
      (
        ClassroomData,
        BaseReferences<_$AppDatabase, $ClassroomsTable, ClassroomData>,
      ),
      ClassroomData,
      PrefetchHooks Function()
    >;
typedef $$NipunOutcomesTableCreateCompanionBuilder =
    NipunOutcomesCompanion Function({
      required String id,
      required String code,
      required int grade,
      required String domain,
      required String competency,
      required String titleEn,
      required String titleHi,
      required String targetDescription,
      required String defaultStatus,
      required String unfinishedSkill,
      Value<int> rowid,
    });
typedef $$NipunOutcomesTableUpdateCompanionBuilder =
    NipunOutcomesCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<int> grade,
      Value<String> domain,
      Value<String> competency,
      Value<String> titleEn,
      Value<String> titleHi,
      Value<String> targetDescription,
      Value<String> defaultStatus,
      Value<String> unfinishedSkill,
      Value<int> rowid,
    });

class $$NipunOutcomesTableFilterComposer
    extends Composer<_$AppDatabase, $NipunOutcomesTable> {
  $$NipunOutcomesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get competency => $composableBuilder(
    column: $table.competency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDescription => $composableBuilder(
    column: $table.targetDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultStatus => $composableBuilder(
    column: $table.defaultStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unfinishedSkill => $composableBuilder(
    column: $table.unfinishedSkill,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NipunOutcomesTableOrderingComposer
    extends Composer<_$AppDatabase, $NipunOutcomesTable> {
  $$NipunOutcomesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get competency => $composableBuilder(
    column: $table.competency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDescription => $composableBuilder(
    column: $table.targetDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultStatus => $composableBuilder(
    column: $table.defaultStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unfinishedSkill => $composableBuilder(
    column: $table.unfinishedSkill,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NipunOutcomesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NipunOutcomesTable> {
  $$NipunOutcomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get competency => $composableBuilder(
    column: $table.competency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titleEn =>
      $composableBuilder(column: $table.titleEn, builder: (column) => column);

  GeneratedColumn<String> get titleHi =>
      $composableBuilder(column: $table.titleHi, builder: (column) => column);

  GeneratedColumn<String> get targetDescription => $composableBuilder(
    column: $table.targetDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultStatus => $composableBuilder(
    column: $table.defaultStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unfinishedSkill => $composableBuilder(
    column: $table.unfinishedSkill,
    builder: (column) => column,
  );
}

class $$NipunOutcomesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NipunOutcomesTable,
          NipunOutcomeData,
          $$NipunOutcomesTableFilterComposer,
          $$NipunOutcomesTableOrderingComposer,
          $$NipunOutcomesTableAnnotationComposer,
          $$NipunOutcomesTableCreateCompanionBuilder,
          $$NipunOutcomesTableUpdateCompanionBuilder,
          (
            NipunOutcomeData,
            BaseReferences<
              _$AppDatabase,
              $NipunOutcomesTable,
              NipunOutcomeData
            >,
          ),
          NipunOutcomeData,
          PrefetchHooks Function()
        > {
  $$NipunOutcomesTableTableManager(_$AppDatabase db, $NipunOutcomesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NipunOutcomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NipunOutcomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NipunOutcomesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<int> grade = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> competency = const Value.absent(),
                Value<String> titleEn = const Value.absent(),
                Value<String> titleHi = const Value.absent(),
                Value<String> targetDescription = const Value.absent(),
                Value<String> defaultStatus = const Value.absent(),
                Value<String> unfinishedSkill = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NipunOutcomesCompanion(
                id: id,
                code: code,
                grade: grade,
                domain: domain,
                competency: competency,
                titleEn: titleEn,
                titleHi: titleHi,
                targetDescription: targetDescription,
                defaultStatus: defaultStatus,
                unfinishedSkill: unfinishedSkill,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required int grade,
                required String domain,
                required String competency,
                required String titleEn,
                required String titleHi,
                required String targetDescription,
                required String defaultStatus,
                required String unfinishedSkill,
                Value<int> rowid = const Value.absent(),
              }) => NipunOutcomesCompanion.insert(
                id: id,
                code: code,
                grade: grade,
                domain: domain,
                competency: competency,
                titleEn: titleEn,
                titleHi: titleHi,
                targetDescription: targetDescription,
                defaultStatus: defaultStatus,
                unfinishedSkill: unfinishedSkill,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NipunOutcomesTable, NipunOutcomeData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NipunOutcomesTable,
                    NipunOutcomeData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NipunOutcomesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NipunOutcomesTable,
      NipunOutcomeData,
      $$NipunOutcomesTableFilterComposer,
      $$NipunOutcomesTableOrderingComposer,
      $$NipunOutcomesTableAnnotationComposer,
      $$NipunOutcomesTableCreateCompanionBuilder,
      $$NipunOutcomesTableUpdateCompanionBuilder,
      (
        NipunOutcomeData,
        BaseReferences<_$AppDatabase, $NipunOutcomesTable, NipunOutcomeData>,
      ),
      NipunOutcomeData,
      PrefetchHooks Function()
    >;
typedef $$LessonsTableCreateCompanionBuilder = LessonsCompanion Function({
  required String id,
  required String title,
  required String titleHi,
  required String outcomeCode,
  required String outcomeTitle,
  required int grade,
  required String subject,
  required int durationMinutes,
  required String learningObjective,
  required String prerequisiteKnowledge,
  required String teacherMoves,
  required String activityOverview,
  required String assessmentStrategy,
  required String remediationOption,
  required String tribalVocabularyJson,
  required String requiredMaterialsJson,
  required String stepsJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> syncStatus,
  Value<int> rowid,
});
typedef $$LessonsTableUpdateCompanionBuilder = LessonsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> titleHi,
  Value<String> outcomeCode,
  Value<String> outcomeTitle,
  Value<int> grade,
  Value<String> subject,
  Value<int> durationMinutes,
  Value<String> learningObjective,
  Value<String> prerequisiteKnowledge,
  Value<String> teacherMoves,
  Value<String> activityOverview,
  Value<String> assessmentStrategy,
  Value<String> remediationOption,
  Value<String> tribalVocabularyJson,
  Value<String> requiredMaterialsJson,
  Value<String> stepsJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> syncStatus,
  Value<int> rowid,
});

class $$LessonsTableFilterComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeTitle => $composableBuilder(
    column: $table.outcomeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get learningObjective => $composableBuilder(
    column: $table.learningObjective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prerequisiteKnowledge => $composableBuilder(
    column: $table.prerequisiteKnowledge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacherMoves => $composableBuilder(
    column: $table.teacherMoves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityOverview => $composableBuilder(
    column: $table.activityOverview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assessmentStrategy => $composableBuilder(
    column: $table.assessmentStrategy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remediationOption => $composableBuilder(
    column: $table.remediationOption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tribalVocabularyJson => $composableBuilder(
    column: $table.tribalVocabularyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requiredMaterialsJson => $composableBuilder(
    column: $table.requiredMaterialsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepsJson => $composableBuilder(
    column: $table.stepsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeTitle => $composableBuilder(
    column: $table.outcomeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get learningObjective => $composableBuilder(
    column: $table.learningObjective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prerequisiteKnowledge => $composableBuilder(
    column: $table.prerequisiteKnowledge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacherMoves => $composableBuilder(
    column: $table.teacherMoves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityOverview => $composableBuilder(
    column: $table.activityOverview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assessmentStrategy => $composableBuilder(
    column: $table.assessmentStrategy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remediationOption => $composableBuilder(
    column: $table.remediationOption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tribalVocabularyJson => $composableBuilder(
    column: $table.tribalVocabularyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requiredMaterialsJson => $composableBuilder(
    column: $table.requiredMaterialsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepsJson => $composableBuilder(
    column: $table.stepsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get titleHi =>
      $composableBuilder(column: $table.titleHi, builder: (column) => column);

  GeneratedColumn<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcomeTitle => $composableBuilder(
    column: $table.outcomeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get learningObjective => $composableBuilder(
    column: $table.learningObjective,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prerequisiteKnowledge => $composableBuilder(
    column: $table.prerequisiteKnowledge,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teacherMoves => $composableBuilder(
    column: $table.teacherMoves,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityOverview => $composableBuilder(
    column: $table.activityOverview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assessmentStrategy => $composableBuilder(
    column: $table.assessmentStrategy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remediationOption => $composableBuilder(
    column: $table.remediationOption,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tribalVocabularyJson => $composableBuilder(
    column: $table.tribalVocabularyJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requiredMaterialsJson => $composableBuilder(
    column: $table.requiredMaterialsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stepsJson =>
      $composableBuilder(column: $table.stepsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$LessonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonsTable,
          LessonData,
          $$LessonsTableFilterComposer,
          $$LessonsTableOrderingComposer,
          $$LessonsTableAnnotationComposer,
          $$LessonsTableCreateCompanionBuilder,
          $$LessonsTableUpdateCompanionBuilder,
          (
            LessonData,
            BaseReferences<_$AppDatabase, $LessonsTable, LessonData>,
          ),
          LessonData,
          PrefetchHooks Function()
        > {
  $$LessonsTableTableManager(_$AppDatabase db, $LessonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> titleHi = const Value.absent(),
                Value<String> outcomeCode = const Value.absent(),
                Value<String> outcomeTitle = const Value.absent(),
                Value<int> grade = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<String> learningObjective = const Value.absent(),
                Value<String> prerequisiteKnowledge = const Value.absent(),
                Value<String> teacherMoves = const Value.absent(),
                Value<String> activityOverview = const Value.absent(),
                Value<String> assessmentStrategy = const Value.absent(),
                Value<String> remediationOption = const Value.absent(),
                Value<String> tribalVocabularyJson = const Value.absent(),
                Value<String> requiredMaterialsJson = const Value.absent(),
                Value<String> stepsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonsCompanion(
                id: id,
                title: title,
                titleHi: titleHi,
                outcomeCode: outcomeCode,
                outcomeTitle: outcomeTitle,
                grade: grade,
                subject: subject,
                durationMinutes: durationMinutes,
                learningObjective: learningObjective,
                prerequisiteKnowledge: prerequisiteKnowledge,
                teacherMoves: teacherMoves,
                activityOverview: activityOverview,
                assessmentStrategy: assessmentStrategy,
                remediationOption: remediationOption,
                tribalVocabularyJson: tribalVocabularyJson,
                requiredMaterialsJson: requiredMaterialsJson,
                stepsJson: stepsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String titleHi,
                required String outcomeCode,
                required String outcomeTitle,
                required int grade,
                required String subject,
                required int durationMinutes,
                required String learningObjective,
                required String prerequisiteKnowledge,
                required String teacherMoves,
                required String activityOverview,
                required String assessmentStrategy,
                required String remediationOption,
                required String tribalVocabularyJson,
                required String requiredMaterialsJson,
                required String stepsJson,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonsCompanion.insert(
                id: id,
                title: title,
                titleHi: titleHi,
                outcomeCode: outcomeCode,
                outcomeTitle: outcomeTitle,
                grade: grade,
                subject: subject,
                durationMinutes: durationMinutes,
                learningObjective: learningObjective,
                prerequisiteKnowledge: prerequisiteKnowledge,
                teacherMoves: teacherMoves,
                activityOverview: activityOverview,
                assessmentStrategy: assessmentStrategy,
                remediationOption: remediationOption,
                tribalVocabularyJson: tribalVocabularyJson,
                requiredMaterialsJson: requiredMaterialsJson,
                stepsJson: stepsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LessonsTable, LessonData>(table),
                  BaseReferences<_$AppDatabase, $LessonsTable, LessonData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonsTable,
      LessonData,
      $$LessonsTableFilterComposer,
      $$LessonsTableOrderingComposer,
      $$LessonsTableAnnotationComposer,
      $$LessonsTableCreateCompanionBuilder,
      $$LessonsTableUpdateCompanionBuilder,
      (LessonData, BaseReferences<_$AppDatabase, $LessonsTable, LessonData>),
      LessonData,
      PrefetchHooks Function()
    >;
typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  required String id,
  required String title,
  required String titleHi,
  required int grade,
  required String subject,
  required String strandOrStage,
  required String language,
  required int durationMinutes,
  required String difficulty,
  required String materials,
  required String teacherStepsJson,
  required String studentStepsJson,
  required String questionsJson,
  required String expectedResponse,
  required String audioPromptHindi,
  required String audioPromptTribal,
  Value<bool> isSaved,
  Value<int> rowid,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> titleHi,
  Value<int> grade,
  Value<String> subject,
  Value<String> strandOrStage,
  Value<String> language,
  Value<int> durationMinutes,
  Value<String> difficulty,
  Value<String> materials,
  Value<String> teacherStepsJson,
  Value<String> studentStepsJson,
  Value<String> questionsJson,
  Value<String> expectedResponse,
  Value<String> audioPromptHindi,
  Value<String> audioPromptTribal,
  Value<bool> isSaved,
  Value<int> rowid,
});

class $$ActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strandOrStage => $composableBuilder(
    column: $table.strandOrStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get materials => $composableBuilder(
    column: $table.materials,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacherStepsJson => $composableBuilder(
    column: $table.teacherStepsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentStepsJson => $composableBuilder(
    column: $table.studentStepsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionsJson => $composableBuilder(
    column: $table.questionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedResponse => $composableBuilder(
    column: $table.expectedResponse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPromptHindi => $composableBuilder(
    column: $table.audioPromptHindi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPromptTribal => $composableBuilder(
    column: $table.audioPromptTribal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSaved => $composableBuilder(
    column: $table.isSaved,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strandOrStage => $composableBuilder(
    column: $table.strandOrStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get materials => $composableBuilder(
    column: $table.materials,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacherStepsJson => $composableBuilder(
    column: $table.teacherStepsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentStepsJson => $composableBuilder(
    column: $table.studentStepsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionsJson => $composableBuilder(
    column: $table.questionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedResponse => $composableBuilder(
    column: $table.expectedResponse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPromptHindi => $composableBuilder(
    column: $table.audioPromptHindi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPromptTribal => $composableBuilder(
    column: $table.audioPromptTribal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSaved => $composableBuilder(
    column: $table.isSaved,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get titleHi =>
      $composableBuilder(column: $table.titleHi, builder: (column) => column);

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get strandOrStage => $composableBuilder(
    column: $table.strandOrStage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get materials =>
      $composableBuilder(column: $table.materials, builder: (column) => column);

  GeneratedColumn<String> get teacherStepsJson => $composableBuilder(
    column: $table.teacherStepsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get studentStepsJson => $composableBuilder(
    column: $table.studentStepsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionsJson => $composableBuilder(
    column: $table.questionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expectedResponse => $composableBuilder(
    column: $table.expectedResponse,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioPromptHindi => $composableBuilder(
    column: $table.audioPromptHindi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioPromptTribal => $composableBuilder(
    column: $table.audioPromptTribal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSaved =>
      $composableBuilder(column: $table.isSaved, builder: (column) => column);
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitiesTable,
          ActivityData,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (
            ActivityData,
            BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityData>,
          ),
          ActivityData,
          PrefetchHooks Function()
        > {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> titleHi = const Value.absent(),
                Value<int> grade = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> strandOrStage = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> materials = const Value.absent(),
                Value<String> teacherStepsJson = const Value.absent(),
                Value<String> studentStepsJson = const Value.absent(),
                Value<String> questionsJson = const Value.absent(),
                Value<String> expectedResponse = const Value.absent(),
                Value<String> audioPromptHindi = const Value.absent(),
                Value<String> audioPromptTribal = const Value.absent(),
                Value<bool> isSaved = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion(
                id: id,
                title: title,
                titleHi: titleHi,
                grade: grade,
                subject: subject,
                strandOrStage: strandOrStage,
                language: language,
                durationMinutes: durationMinutes,
                difficulty: difficulty,
                materials: materials,
                teacherStepsJson: teacherStepsJson,
                studentStepsJson: studentStepsJson,
                questionsJson: questionsJson,
                expectedResponse: expectedResponse,
                audioPromptHindi: audioPromptHindi,
                audioPromptTribal: audioPromptTribal,
                isSaved: isSaved,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String titleHi,
                required int grade,
                required String subject,
                required String strandOrStage,
                required String language,
                required int durationMinutes,
                required String difficulty,
                required String materials,
                required String teacherStepsJson,
                required String studentStepsJson,
                required String questionsJson,
                required String expectedResponse,
                required String audioPromptHindi,
                required String audioPromptTribal,
                Value<bool> isSaved = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion.insert(
                id: id,
                title: title,
                titleHi: titleHi,
                grade: grade,
                subject: subject,
                strandOrStage: strandOrStage,
                language: language,
                durationMinutes: durationMinutes,
                difficulty: difficulty,
                materials: materials,
                teacherStepsJson: teacherStepsJson,
                studentStepsJson: studentStepsJson,
                questionsJson: questionsJson,
                expectedResponse: expectedResponse,
                audioPromptHindi: audioPromptHindi,
                audioPromptTribal: audioPromptTribal,
                isSaved: isSaved,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivitiesTable, ActivityData>(table),
                  BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitiesTable,
      ActivityData,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (
        ActivityData,
        BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityData>,
      ),
      ActivityData,
      PrefetchHooks Function()
    >;
typedef $$LessonDeliveryProgressTableCreateCompanionBuilder =
    LessonDeliveryProgressCompanion Function({
      required String lessonId,
      required int currentStep,
      Value<bool> isCompleted,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$LessonDeliveryProgressTableUpdateCompanionBuilder =
    LessonDeliveryProgressCompanion Function({
      Value<String> lessonId,
      Value<int> currentStep,
      Value<bool> isCompleted,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$LessonDeliveryProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LessonDeliveryProgressTable> {
  $$LessonDeliveryProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonDeliveryProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonDeliveryProgressTable> {
  $$LessonDeliveryProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonDeliveryProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonDeliveryProgressTable> {
  $$LessonDeliveryProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$LessonDeliveryProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonDeliveryProgressTable,
          LessonDeliveryProgressData,
          $$LessonDeliveryProgressTableFilterComposer,
          $$LessonDeliveryProgressTableOrderingComposer,
          $$LessonDeliveryProgressTableAnnotationComposer,
          $$LessonDeliveryProgressTableCreateCompanionBuilder,
          $$LessonDeliveryProgressTableUpdateCompanionBuilder,
          (
            LessonDeliveryProgressData,
            BaseReferences<
              _$AppDatabase,
              $LessonDeliveryProgressTable,
              LessonDeliveryProgressData
            >,
          ),
          LessonDeliveryProgressData,
          PrefetchHooks Function()
        > {
  $$LessonDeliveryProgressTableTableManager(
    _$AppDatabase db,
    $LessonDeliveryProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonDeliveryProgressTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LessonDeliveryProgressTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LessonDeliveryProgressTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<int> currentStep = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonDeliveryProgressCompanion(
                lessonId: lessonId,
                currentStep: currentStep,
                isCompleted: isCompleted,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                required int currentStep,
                Value<bool> isCompleted = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonDeliveryProgressCompanion.insert(
                lessonId: lessonId,
                currentStep: currentStep,
                isCompleted: isCompleted,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LessonDeliveryProgressTable,
                    LessonDeliveryProgressData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LessonDeliveryProgressTable,
                    LessonDeliveryProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonDeliveryProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonDeliveryProgressTable,
      LessonDeliveryProgressData,
      $$LessonDeliveryProgressTableFilterComposer,
      $$LessonDeliveryProgressTableOrderingComposer,
      $$LessonDeliveryProgressTableAnnotationComposer,
      $$LessonDeliveryProgressTableCreateCompanionBuilder,
      $$LessonDeliveryProgressTableUpdateCompanionBuilder,
      (
        LessonDeliveryProgressData,
        BaseReferences<
          _$AppDatabase,
          $LessonDeliveryProgressTable,
          LessonDeliveryProgressData
        >,
      ),
      LessonDeliveryProgressData,
      PrefetchHooks Function()
    >;
typedef $$LocalContextsTableCreateCompanionBuilder =
    LocalContextsCompanion Function({
      required String id,
      required String category,
      required String title,
      required String titleHi,
      required String description,
      required String culturalRelevance,
      required String tribalTerm,
      required String language,
      Value<int> rowid,
    });
typedef $$LocalContextsTableUpdateCompanionBuilder =
    LocalContextsCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<String> title,
      Value<String> titleHi,
      Value<String> description,
      Value<String> culturalRelevance,
      Value<String> tribalTerm,
      Value<String> language,
      Value<int> rowid,
    });

class $$LocalContextsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalContextsTable> {
  $$LocalContextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get culturalRelevance => $composableBuilder(
    column: $table.culturalRelevance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tribalTerm => $composableBuilder(
    column: $table.tribalTerm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalContextsTable> {
  $$LocalContextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get culturalRelevance => $composableBuilder(
    column: $table.culturalRelevance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tribalTerm => $composableBuilder(
    column: $table.tribalTerm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalContextsTable> {
  $$LocalContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get titleHi =>
      $composableBuilder(column: $table.titleHi, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get culturalRelevance => $composableBuilder(
    column: $table.culturalRelevance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tribalTerm => $composableBuilder(
    column: $table.tribalTerm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);
}

class $$LocalContextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalContextsTable,
          LocalContextData,
          $$LocalContextsTableFilterComposer,
          $$LocalContextsTableOrderingComposer,
          $$LocalContextsTableAnnotationComposer,
          $$LocalContextsTableCreateCompanionBuilder,
          $$LocalContextsTableUpdateCompanionBuilder,
          (
            LocalContextData,
            BaseReferences<
              _$AppDatabase,
              $LocalContextsTable,
              LocalContextData
            >,
          ),
          LocalContextData,
          PrefetchHooks Function()
        > {
  $$LocalContextsTableTableManager(_$AppDatabase db, $LocalContextsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalContextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalContextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> titleHi = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> culturalRelevance = const Value.absent(),
                Value<String> tribalTerm = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalContextsCompanion(
                id: id,
                category: category,
                title: title,
                titleHi: titleHi,
                description: description,
                culturalRelevance: culturalRelevance,
                tribalTerm: tribalTerm,
                language: language,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required String title,
                required String titleHi,
                required String description,
                required String culturalRelevance,
                required String tribalTerm,
                required String language,
                Value<int> rowid = const Value.absent(),
              }) => LocalContextsCompanion.insert(
                id: id,
                category: category,
                title: title,
                titleHi: titleHi,
                description: description,
                culturalRelevance: culturalRelevance,
                tribalTerm: tribalTerm,
                language: language,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalContextsTable, LocalContextData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalContextsTable,
                    LocalContextData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalContextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalContextsTable,
      LocalContextData,
      $$LocalContextsTableFilterComposer,
      $$LocalContextsTableOrderingComposer,
      $$LocalContextsTableAnnotationComposer,
      $$LocalContextsTableCreateCompanionBuilder,
      $$LocalContextsTableUpdateCompanionBuilder,
      (
        LocalContextData,
        BaseReferences<_$AppDatabase, $LocalContextsTable, LocalContextData>,
      ),
      LocalContextData,
      PrefetchHooks Function()
    >;
typedef $$StudentsTableCreateCompanionBuilder = StudentsCompanion Function({
  required String id,
  required String name,
  required int rollNumber,
  required int grade,
  required String motherTongue,
  Value<int> achievedOutcomes,
  Value<int> developingOutcomes,
  Value<int> needsSupportOutcomes,
  Value<double> literacyProgress,
  Value<double> numeracyProgress,
  required String recentEvidence,
  Value<String> identifiedGapsJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$StudentsTableUpdateCompanionBuilder = StudentsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> rollNumber,
  Value<int> grade,
  Value<String> motherTongue,
  Value<int> achievedOutcomes,
  Value<int> developingOutcomes,
  Value<int> needsSupportOutcomes,
  Value<double> literacyProgress,
  Value<double> numeracyProgress,
  Value<String> recentEvidence,
  Value<String> identifiedGapsJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$StudentsTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rollNumber => $composableBuilder(
    column: $table.rollNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motherTongue => $composableBuilder(
    column: $table.motherTongue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get achievedOutcomes => $composableBuilder(
    column: $table.achievedOutcomes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get developingOutcomes => $composableBuilder(
    column: $table.developingOutcomes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get needsSupportOutcomes => $composableBuilder(
    column: $table.needsSupportOutcomes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get literacyProgress => $composableBuilder(
    column: $table.literacyProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get numeracyProgress => $composableBuilder(
    column: $table.numeracyProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recentEvidence => $composableBuilder(
    column: $table.recentEvidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identifiedGapsJson => $composableBuilder(
    column: $table.identifiedGapsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rollNumber => $composableBuilder(
    column: $table.rollNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motherTongue => $composableBuilder(
    column: $table.motherTongue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get achievedOutcomes => $composableBuilder(
    column: $table.achievedOutcomes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get developingOutcomes => $composableBuilder(
    column: $table.developingOutcomes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get needsSupportOutcomes => $composableBuilder(
    column: $table.needsSupportOutcomes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get literacyProgress => $composableBuilder(
    column: $table.literacyProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get numeracyProgress => $composableBuilder(
    column: $table.numeracyProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recentEvidence => $composableBuilder(
    column: $table.recentEvidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identifiedGapsJson => $composableBuilder(
    column: $table.identifiedGapsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get rollNumber => $composableBuilder(
    column: $table.rollNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get motherTongue => $composableBuilder(
    column: $table.motherTongue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get achievedOutcomes => $composableBuilder(
    column: $table.achievedOutcomes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get developingOutcomes => $composableBuilder(
    column: $table.developingOutcomes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get needsSupportOutcomes => $composableBuilder(
    column: $table.needsSupportOutcomes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get literacyProgress => $composableBuilder(
    column: $table.literacyProgress,
    builder: (column) => column,
  );

  GeneratedColumn<double> get numeracyProgress => $composableBuilder(
    column: $table.numeracyProgress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recentEvidence => $composableBuilder(
    column: $table.recentEvidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identifiedGapsJson => $composableBuilder(
    column: $table.identifiedGapsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StudentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentsTable,
          StudentData,
          $$StudentsTableFilterComposer,
          $$StudentsTableOrderingComposer,
          $$StudentsTableAnnotationComposer,
          $$StudentsTableCreateCompanionBuilder,
          $$StudentsTableUpdateCompanionBuilder,
          (
            StudentData,
            BaseReferences<_$AppDatabase, $StudentsTable, StudentData>,
          ),
          StudentData,
          PrefetchHooks Function()
        > {
  $$StudentsTableTableManager(_$AppDatabase db, $StudentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rollNumber = const Value.absent(),
                Value<int> grade = const Value.absent(),
                Value<String> motherTongue = const Value.absent(),
                Value<int> achievedOutcomes = const Value.absent(),
                Value<int> developingOutcomes = const Value.absent(),
                Value<int> needsSupportOutcomes = const Value.absent(),
                Value<double> literacyProgress = const Value.absent(),
                Value<double> numeracyProgress = const Value.absent(),
                Value<String> recentEvidence = const Value.absent(),
                Value<String> identifiedGapsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion(
                id: id,
                name: name,
                rollNumber: rollNumber,
                grade: grade,
                motherTongue: motherTongue,
                achievedOutcomes: achievedOutcomes,
                developingOutcomes: developingOutcomes,
                needsSupportOutcomes: needsSupportOutcomes,
                literacyProgress: literacyProgress,
                numeracyProgress: numeracyProgress,
                recentEvidence: recentEvidence,
                identifiedGapsJson: identifiedGapsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int rollNumber,
                required int grade,
                required String motherTongue,
                Value<int> achievedOutcomes = const Value.absent(),
                Value<int> developingOutcomes = const Value.absent(),
                Value<int> needsSupportOutcomes = const Value.absent(),
                Value<double> literacyProgress = const Value.absent(),
                Value<double> numeracyProgress = const Value.absent(),
                required String recentEvidence,
                Value<String> identifiedGapsJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion.insert(
                id: id,
                name: name,
                rollNumber: rollNumber,
                grade: grade,
                motherTongue: motherTongue,
                achievedOutcomes: achievedOutcomes,
                developingOutcomes: developingOutcomes,
                needsSupportOutcomes: needsSupportOutcomes,
                literacyProgress: literacyProgress,
                numeracyProgress: numeracyProgress,
                recentEvidence: recentEvidence,
                identifiedGapsJson: identifiedGapsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StudentsTable, StudentData>(table),
                  BaseReferences<_$AppDatabase, $StudentsTable, StudentData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentsTable,
      StudentData,
      $$StudentsTableFilterComposer,
      $$StudentsTableOrderingComposer,
      $$StudentsTableAnnotationComposer,
      $$StudentsTableCreateCompanionBuilder,
      $$StudentsTableUpdateCompanionBuilder,
      (StudentData, BaseReferences<_$AppDatabase, $StudentsTable, StudentData>),
      StudentData,
      PrefetchHooks Function()
    >;
typedef $$AssessmentQuestionsTableCreateCompanionBuilder =
    AssessmentQuestionsCompanion Function({
      required String id,
      required String outcomeCode,
      required String questionsJson,
      Value<int> rowid,
    });
typedef $$AssessmentQuestionsTableUpdateCompanionBuilder =
    AssessmentQuestionsCompanion Function({
      Value<String> id,
      Value<String> outcomeCode,
      Value<String> questionsJson,
      Value<int> rowid,
    });

class $$AssessmentQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $AssessmentQuestionsTable> {
  $$AssessmentQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionsJson => $composableBuilder(
    column: $table.questionsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssessmentQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssessmentQuestionsTable> {
  $$AssessmentQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionsJson => $composableBuilder(
    column: $table.questionsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssessmentQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssessmentQuestionsTable> {
  $$AssessmentQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionsJson => $composableBuilder(
    column: $table.questionsJson,
    builder: (column) => column,
  );
}

class $$AssessmentQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssessmentQuestionsTable,
          AssessmentQuestionData,
          $$AssessmentQuestionsTableFilterComposer,
          $$AssessmentQuestionsTableOrderingComposer,
          $$AssessmentQuestionsTableAnnotationComposer,
          $$AssessmentQuestionsTableCreateCompanionBuilder,
          $$AssessmentQuestionsTableUpdateCompanionBuilder,
          (
            AssessmentQuestionData,
            BaseReferences<
              _$AppDatabase,
              $AssessmentQuestionsTable,
              AssessmentQuestionData
            >,
          ),
          AssessmentQuestionData,
          PrefetchHooks Function()
        > {
  $$AssessmentQuestionsTableTableManager(
    _$AppDatabase db,
    $AssessmentQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssessmentQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssessmentQuestionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AssessmentQuestionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> outcomeCode = const Value.absent(),
                Value<String> questionsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssessmentQuestionsCompanion(
                id: id,
                outcomeCode: outcomeCode,
                questionsJson: questionsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String outcomeCode,
                required String questionsJson,
                Value<int> rowid = const Value.absent(),
              }) => AssessmentQuestionsCompanion.insert(
                id: id,
                outcomeCode: outcomeCode,
                questionsJson: questionsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AssessmentQuestionsTable,
                    AssessmentQuestionData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AssessmentQuestionsTable,
                    AssessmentQuestionData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssessmentQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssessmentQuestionsTable,
      AssessmentQuestionData,
      $$AssessmentQuestionsTableFilterComposer,
      $$AssessmentQuestionsTableOrderingComposer,
      $$AssessmentQuestionsTableAnnotationComposer,
      $$AssessmentQuestionsTableCreateCompanionBuilder,
      $$AssessmentQuestionsTableUpdateCompanionBuilder,
      (
        AssessmentQuestionData,
        BaseReferences<
          _$AppDatabase,
          $AssessmentQuestionsTable,
          AssessmentQuestionData
        >,
      ),
      AssessmentQuestionData,
      PrefetchHooks Function()
    >;
typedef $$AssessmentResultsTableCreateCompanionBuilder =
    AssessmentResultsCompanion Function({
      required String id,
      required String studentId,
      required String studentName,
      required String outcomeCode,
      required String outcomeTitle,
      required int totalQuestions,
      required int correctCount,
      required String status,
      required String unfinishedSkill,
      required String recommendedRemediation,
      required DateTime completedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$AssessmentResultsTableUpdateCompanionBuilder =
    AssessmentResultsCompanion Function({
      Value<String> id,
      Value<String> studentId,
      Value<String> studentName,
      Value<String> outcomeCode,
      Value<String> outcomeTitle,
      Value<int> totalQuestions,
      Value<int> correctCount,
      Value<String> status,
      Value<String> unfinishedSkill,
      Value<String> recommendedRemediation,
      Value<DateTime> completedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$AssessmentResultsTableFilterComposer
    extends Composer<_$AppDatabase, $AssessmentResultsTable> {
  $$AssessmentResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentName => $composableBuilder(
    column: $table.studentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeTitle => $composableBuilder(
    column: $table.outcomeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unfinishedSkill => $composableBuilder(
    column: $table.unfinishedSkill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedRemediation => $composableBuilder(
    column: $table.recommendedRemediation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssessmentResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssessmentResultsTable> {
  $$AssessmentResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentName => $composableBuilder(
    column: $table.studentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeTitle => $composableBuilder(
    column: $table.outcomeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unfinishedSkill => $composableBuilder(
    column: $table.unfinishedSkill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedRemediation => $composableBuilder(
    column: $table.recommendedRemediation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssessmentResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssessmentResultsTable> {
  $$AssessmentResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get studentName => $composableBuilder(
    column: $table.studentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcomeTitle => $composableBuilder(
    column: $table.outcomeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get unfinishedSkill => $composableBuilder(
    column: $table.unfinishedSkill,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendedRemediation => $composableBuilder(
    column: $table.recommendedRemediation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$AssessmentResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssessmentResultsTable,
          AssessmentResultRecord,
          $$AssessmentResultsTableFilterComposer,
          $$AssessmentResultsTableOrderingComposer,
          $$AssessmentResultsTableAnnotationComposer,
          $$AssessmentResultsTableCreateCompanionBuilder,
          $$AssessmentResultsTableUpdateCompanionBuilder,
          (
            AssessmentResultRecord,
            BaseReferences<
              _$AppDatabase,
              $AssessmentResultsTable,
              AssessmentResultRecord
            >,
          ),
          AssessmentResultRecord,
          PrefetchHooks Function()
        > {
  $$AssessmentResultsTableTableManager(
    _$AppDatabase db,
    $AssessmentResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssessmentResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssessmentResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssessmentResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> studentName = const Value.absent(),
                Value<String> outcomeCode = const Value.absent(),
                Value<String> outcomeTitle = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> unfinishedSkill = const Value.absent(),
                Value<String> recommendedRemediation = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssessmentResultsCompanion(
                id: id,
                studentId: studentId,
                studentName: studentName,
                outcomeCode: outcomeCode,
                outcomeTitle: outcomeTitle,
                totalQuestions: totalQuestions,
                correctCount: correctCount,
                status: status,
                unfinishedSkill: unfinishedSkill,
                recommendedRemediation: recommendedRemediation,
                completedAt: completedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String studentId,
                required String studentName,
                required String outcomeCode,
                required String outcomeTitle,
                required int totalQuestions,
                required int correctCount,
                required String status,
                required String unfinishedSkill,
                required String recommendedRemediation,
                required DateTime completedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssessmentResultsCompanion.insert(
                id: id,
                studentId: studentId,
                studentName: studentName,
                outcomeCode: outcomeCode,
                outcomeTitle: outcomeTitle,
                totalQuestions: totalQuestions,
                correctCount: correctCount,
                status: status,
                unfinishedSkill: unfinishedSkill,
                recommendedRemediation: recommendedRemediation,
                completedAt: completedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssessmentResultsTable, AssessmentResultRecord>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $AssessmentResultsTable,
                    AssessmentResultRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssessmentResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssessmentResultsTable,
      AssessmentResultRecord,
      $$AssessmentResultsTableFilterComposer,
      $$AssessmentResultsTableOrderingComposer,
      $$AssessmentResultsTableAnnotationComposer,
      $$AssessmentResultsTableCreateCompanionBuilder,
      $$AssessmentResultsTableUpdateCompanionBuilder,
      (
        AssessmentResultRecord,
        BaseReferences<
          _$AppDatabase,
          $AssessmentResultsTable,
          AssessmentResultRecord
        >,
      ),
      AssessmentResultRecord,
      PrefetchHooks Function()
    >;
typedef $$LearningGapsTableCreateCompanionBuilder =
    LearningGapsCompanion Function({
      required String id,
      required String studentId,
      required String outcomeCode,
      required String skill,
      required String rootCause,
      required String remediationUsed,
      required String status,
      Value<bool> isResolved,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LearningGapsTableUpdateCompanionBuilder =
    LearningGapsCompanion Function({
      Value<String> id,
      Value<String> studentId,
      Value<String> outcomeCode,
      Value<String> skill,
      Value<String> rootCause,
      Value<String> remediationUsed,
      Value<String> status,
      Value<bool> isResolved,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LearningGapsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningGapsTable> {
  $$LearningGapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootCause => $composableBuilder(
    column: $table.rootCause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remediationUsed => $composableBuilder(
    column: $table.remediationUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningGapsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningGapsTable> {
  $$LearningGapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootCause => $composableBuilder(
    column: $table.rootCause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remediationUsed => $composableBuilder(
    column: $table.remediationUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningGapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningGapsTable> {
  $$LearningGapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skill =>
      $composableBuilder(column: $table.skill, builder: (column) => column);

  GeneratedColumn<String> get rootCause =>
      $composableBuilder(column: $table.rootCause, builder: (column) => column);

  GeneratedColumn<String> get remediationUsed => $composableBuilder(
    column: $table.remediationUsed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LearningGapsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningGapsTable,
          LearningGapData,
          $$LearningGapsTableFilterComposer,
          $$LearningGapsTableOrderingComposer,
          $$LearningGapsTableAnnotationComposer,
          $$LearningGapsTableCreateCompanionBuilder,
          $$LearningGapsTableUpdateCompanionBuilder,
          (
            LearningGapData,
            BaseReferences<_$AppDatabase, $LearningGapsTable, LearningGapData>,
          ),
          LearningGapData,
          PrefetchHooks Function()
        > {
  $$LearningGapsTableTableManager(_$AppDatabase db, $LearningGapsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningGapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningGapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningGapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> outcomeCode = const Value.absent(),
                Value<String> skill = const Value.absent(),
                Value<String> rootCause = const Value.absent(),
                Value<String> remediationUsed = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isResolved = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningGapsCompanion(
                id: id,
                studentId: studentId,
                outcomeCode: outcomeCode,
                skill: skill,
                rootCause: rootCause,
                remediationUsed: remediationUsed,
                status: status,
                isResolved: isResolved,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String studentId,
                required String outcomeCode,
                required String skill,
                required String rootCause,
                required String remediationUsed,
                required String status,
                Value<bool> isResolved = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LearningGapsCompanion.insert(
                id: id,
                studentId: studentId,
                outcomeCode: outcomeCode,
                skill: skill,
                rootCause: rootCause,
                remediationUsed: remediationUsed,
                status: status,
                isResolved: isResolved,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LearningGapsTable, LearningGapData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LearningGapsTable,
                    LearningGapData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningGapsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningGapsTable,
      LearningGapData,
      $$LearningGapsTableFilterComposer,
      $$LearningGapsTableOrderingComposer,
      $$LearningGapsTableAnnotationComposer,
      $$LearningGapsTableCreateCompanionBuilder,
      $$LearningGapsTableUpdateCompanionBuilder,
      (
        LearningGapData,
        BaseReferences<_$AppDatabase, $LearningGapsTable, LearningGapData>,
      ),
      LearningGapData,
      PrefetchHooks Function()
    >;
typedef $$RemedialRecommendationsTableCreateCompanionBuilder =
    RemedialRecommendationsCompanion Function({
      required String id,
      Value<String?> studentId,
      required String outcomeCode,
      required String title,
      required String subject,
      required String culturalHook,
      required String reason,
      Value<int> rowid,
    });
typedef $$RemedialRecommendationsTableUpdateCompanionBuilder =
    RemedialRecommendationsCompanion Function({
      Value<String> id,
      Value<String?> studentId,
      Value<String> outcomeCode,
      Value<String> title,
      Value<String> subject,
      Value<String> culturalHook,
      Value<String> reason,
      Value<int> rowid,
    });

class $$RemedialRecommendationsTableFilterComposer
    extends Composer<_$AppDatabase, $RemedialRecommendationsTable> {
  $$RemedialRecommendationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get culturalHook => $composableBuilder(
    column: $table.culturalHook,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemedialRecommendationsTableOrderingComposer
    extends Composer<_$AppDatabase, $RemedialRecommendationsTable> {
  $$RemedialRecommendationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get culturalHook => $composableBuilder(
    column: $table.culturalHook,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemedialRecommendationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemedialRecommendationsTable> {
  $$RemedialRecommendationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get culturalHook => $composableBuilder(
    column: $table.culturalHook,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);
}

class $$RemedialRecommendationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemedialRecommendationsTable,
          RemedialRecommendationData,
          $$RemedialRecommendationsTableFilterComposer,
          $$RemedialRecommendationsTableOrderingComposer,
          $$RemedialRecommendationsTableAnnotationComposer,
          $$RemedialRecommendationsTableCreateCompanionBuilder,
          $$RemedialRecommendationsTableUpdateCompanionBuilder,
          (
            RemedialRecommendationData,
            BaseReferences<
              _$AppDatabase,
              $RemedialRecommendationsTable,
              RemedialRecommendationData
            >,
          ),
          RemedialRecommendationData,
          PrefetchHooks Function()
        > {
  $$RemedialRecommendationsTableTableManager(
    _$AppDatabase db,
    $RemedialRecommendationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemedialRecommendationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RemedialRecommendationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RemedialRecommendationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> studentId = const Value.absent(),
                Value<String> outcomeCode = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> culturalHook = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemedialRecommendationsCompanion(
                id: id,
                studentId: studentId,
                outcomeCode: outcomeCode,
                title: title,
                subject: subject,
                culturalHook: culturalHook,
                reason: reason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> studentId = const Value.absent(),
                required String outcomeCode,
                required String title,
                required String subject,
                required String culturalHook,
                required String reason,
                Value<int> rowid = const Value.absent(),
              }) => RemedialRecommendationsCompanion.insert(
                id: id,
                studentId: studentId,
                outcomeCode: outcomeCode,
                title: title,
                subject: subject,
                culturalHook: culturalHook,
                reason: reason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RemedialRecommendationsTable,
                    RemedialRecommendationData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RemedialRecommendationsTable,
                    RemedialRecommendationData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemedialRecommendationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemedialRecommendationsTable,
      RemedialRecommendationData,
      $$RemedialRecommendationsTableFilterComposer,
      $$RemedialRecommendationsTableOrderingComposer,
      $$RemedialRecommendationsTableAnnotationComposer,
      $$RemedialRecommendationsTableCreateCompanionBuilder,
      $$RemedialRecommendationsTableUpdateCompanionBuilder,
      (
        RemedialRecommendationData,
        BaseReferences<
          _$AppDatabase,
          $RemedialRecommendationsTable,
          RemedialRecommendationData
        >,
      ),
      RemedialRecommendationData,
      PrefetchHooks Function()
    >;
typedef $$SavedMaterialsTableCreateCompanionBuilder =
    SavedMaterialsCompanion Function({
      required String id,
      required String type,
      required String title,
      required String titleHi,
      required int grade,
      required String subject,
      required String outcomeCode,
      required String language,
      required String difficulty,
      required String contentJson,
      required DateTime createdAt,
      Value<bool> isFavorite,
      Value<int> rowid,
    });
typedef $$SavedMaterialsTableUpdateCompanionBuilder =
    SavedMaterialsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> title,
      Value<String> titleHi,
      Value<int> grade,
      Value<String> subject,
      Value<String> outcomeCode,
      Value<String> language,
      Value<String> difficulty,
      Value<String> contentJson,
      Value<DateTime> createdAt,
      Value<bool> isFavorite,
      Value<int> rowid,
    });

class $$SavedMaterialsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedMaterialsTable> {
  $$SavedMaterialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedMaterialsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedMaterialsTable> {
  $$SavedMaterialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleHi => $composableBuilder(
    column: $table.titleHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedMaterialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedMaterialsTable> {
  $$SavedMaterialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get titleHi =>
      $composableBuilder(column: $table.titleHi, builder: (column) => column);

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get outcomeCode => $composableBuilder(
    column: $table.outcomeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );
}

class $$SavedMaterialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedMaterialsTable,
          SavedMaterialData,
          $$SavedMaterialsTableFilterComposer,
          $$SavedMaterialsTableOrderingComposer,
          $$SavedMaterialsTableAnnotationComposer,
          $$SavedMaterialsTableCreateCompanionBuilder,
          $$SavedMaterialsTableUpdateCompanionBuilder,
          (
            SavedMaterialData,
            BaseReferences<
              _$AppDatabase,
              $SavedMaterialsTable,
              SavedMaterialData
            >,
          ),
          SavedMaterialData,
          PrefetchHooks Function()
        > {
  $$SavedMaterialsTableTableManager(
    _$AppDatabase db,
    $SavedMaterialsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedMaterialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedMaterialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedMaterialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> titleHi = const Value.absent(),
                Value<int> grade = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> outcomeCode = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> contentJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedMaterialsCompanion(
                id: id,
                type: type,
                title: title,
                titleHi: titleHi,
                grade: grade,
                subject: subject,
                outcomeCode: outcomeCode,
                language: language,
                difficulty: difficulty,
                contentJson: contentJson,
                createdAt: createdAt,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String title,
                required String titleHi,
                required int grade,
                required String subject,
                required String outcomeCode,
                required String language,
                required String difficulty,
                required String contentJson,
                required DateTime createdAt,
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedMaterialsCompanion.insert(
                id: id,
                type: type,
                title: title,
                titleHi: titleHi,
                grade: grade,
                subject: subject,
                outcomeCode: outcomeCode,
                language: language,
                difficulty: difficulty,
                contentJson: contentJson,
                createdAt: createdAt,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedMaterialsTable, SavedMaterialData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SavedMaterialsTable,
                    SavedMaterialData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedMaterialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedMaterialsTable,
      SavedMaterialData,
      $$SavedMaterialsTableFilterComposer,
      $$SavedMaterialsTableOrderingComposer,
      $$SavedMaterialsTableAnnotationComposer,
      $$SavedMaterialsTableCreateCompanionBuilder,
      $$SavedMaterialsTableUpdateCompanionBuilder,
      (
        SavedMaterialData,
        BaseReferences<_$AppDatabase, $SavedMaterialsTable, SavedMaterialData>,
      ),
      SavedMaterialData,
      PrefetchHooks Function()
    >;
typedef $$TranslationHistoryTableCreateCompanionBuilder =
    TranslationHistoryCompanion Function({
      required String id,
      required bool isTeacher,
      required String speakerName,
      required String originalText,
      required String translatedText,
      required String targetLanguage,
      required int latencyMs,
      Value<bool> isOfflineNmt,
      required DateTime timestamp,
      Value<int> rowid,
    });
typedef $$TranslationHistoryTableUpdateCompanionBuilder =
    TranslationHistoryCompanion Function({
      Value<String> id,
      Value<bool> isTeacher,
      Value<String> speakerName,
      Value<String> originalText,
      Value<String> translatedText,
      Value<String> targetLanguage,
      Value<int> latencyMs,
      Value<bool> isOfflineNmt,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });

class $$TranslationHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $TranslationHistoryTable> {
  $$TranslationHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTeacher => $composableBuilder(
    column: $table.isTeacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get speakerName => $composableBuilder(
    column: $table.speakerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translatedText => $composableBuilder(
    column: $table.translatedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOfflineNmt => $composableBuilder(
    column: $table.isOfflineNmt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TranslationHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $TranslationHistoryTable> {
  $$TranslationHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTeacher => $composableBuilder(
    column: $table.isTeacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get speakerName => $composableBuilder(
    column: $table.speakerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translatedText => $composableBuilder(
    column: $table.translatedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOfflineNmt => $composableBuilder(
    column: $table.isOfflineNmt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranslationHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranslationHistoryTable> {
  $$TranslationHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isTeacher =>
      $composableBuilder(column: $table.isTeacher, builder: (column) => column);

  GeneratedColumn<String> get speakerName => $composableBuilder(
    column: $table.speakerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get translatedText => $composableBuilder(
    column: $table.translatedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latencyMs =>
      $composableBuilder(column: $table.latencyMs, builder: (column) => column);

  GeneratedColumn<bool> get isOfflineNmt => $composableBuilder(
    column: $table.isOfflineNmt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$TranslationHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranslationHistoryTable,
          TranslationHistoryData,
          $$TranslationHistoryTableFilterComposer,
          $$TranslationHistoryTableOrderingComposer,
          $$TranslationHistoryTableAnnotationComposer,
          $$TranslationHistoryTableCreateCompanionBuilder,
          $$TranslationHistoryTableUpdateCompanionBuilder,
          (
            TranslationHistoryData,
            BaseReferences<
              _$AppDatabase,
              $TranslationHistoryTable,
              TranslationHistoryData
            >,
          ),
          TranslationHistoryData,
          PrefetchHooks Function()
        > {
  $$TranslationHistoryTableTableManager(
    _$AppDatabase db,
    $TranslationHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslationHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isTeacher = const Value.absent(),
                Value<String> speakerName = const Value.absent(),
                Value<String> originalText = const Value.absent(),
                Value<String> translatedText = const Value.absent(),
                Value<String> targetLanguage = const Value.absent(),
                Value<int> latencyMs = const Value.absent(),
                Value<bool> isOfflineNmt = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranslationHistoryCompanion(
                id: id,
                isTeacher: isTeacher,
                speakerName: speakerName,
                originalText: originalText,
                translatedText: translatedText,
                targetLanguage: targetLanguage,
                latencyMs: latencyMs,
                isOfflineNmt: isOfflineNmt,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required bool isTeacher,
                required String speakerName,
                required String originalText,
                required String translatedText,
                required String targetLanguage,
                required int latencyMs,
                Value<bool> isOfflineNmt = const Value.absent(),
                required DateTime timestamp,
                Value<int> rowid = const Value.absent(),
              }) => TranslationHistoryCompanion.insert(
                id: id,
                isTeacher: isTeacher,
                speakerName: speakerName,
                originalText: originalText,
                translatedText: translatedText,
                targetLanguage: targetLanguage,
                latencyMs: latencyMs,
                isOfflineNmt: isOfflineNmt,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TranslationHistoryTable, TranslationHistoryData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $TranslationHistoryTable,
                    TranslationHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TranslationHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranslationHistoryTable,
      TranslationHistoryData,
      $$TranslationHistoryTableFilterComposer,
      $$TranslationHistoryTableOrderingComposer,
      $$TranslationHistoryTableAnnotationComposer,
      $$TranslationHistoryTableCreateCompanionBuilder,
      $$TranslationHistoryTableUpdateCompanionBuilder,
      (
        TranslationHistoryData,
        BaseReferences<
          _$AppDatabase,
          $TranslationHistoryTable,
          TranslationHistoryData
        >,
      ),
      TranslationHistoryData,
      PrefetchHooks Function()
    >;
typedef $$TranslationFeedbackTableCreateCompanionBuilder =
    TranslationFeedbackCompanion Function({
      required String id,
      required String original,
      required String translated,
      required String issueType,
      Value<String?> comment,
      required DateTime timestamp,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$TranslationFeedbackTableUpdateCompanionBuilder =
    TranslationFeedbackCompanion Function({
      Value<String> id,
      Value<String> original,
      Value<String> translated,
      Value<String> issueType,
      Value<String?> comment,
      Value<DateTime> timestamp,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$TranslationFeedbackTableFilterComposer
    extends Composer<_$AppDatabase, $TranslationFeedbackTable> {
  $$TranslationFeedbackTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get original => $composableBuilder(
    column: $table.original,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translated => $composableBuilder(
    column: $table.translated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueType => $composableBuilder(
    column: $table.issueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TranslationFeedbackTableOrderingComposer
    extends Composer<_$AppDatabase, $TranslationFeedbackTable> {
  $$TranslationFeedbackTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get original => $composableBuilder(
    column: $table.original,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translated => $composableBuilder(
    column: $table.translated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueType => $composableBuilder(
    column: $table.issueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranslationFeedbackTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranslationFeedbackTable> {
  $$TranslationFeedbackTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get original =>
      $composableBuilder(column: $table.original, builder: (column) => column);

  GeneratedColumn<String> get translated => $composableBuilder(
    column: $table.translated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issueType =>
      $composableBuilder(column: $table.issueType, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TranslationFeedbackTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranslationFeedbackTable,
          TranslationFeedbackData,
          $$TranslationFeedbackTableFilterComposer,
          $$TranslationFeedbackTableOrderingComposer,
          $$TranslationFeedbackTableAnnotationComposer,
          $$TranslationFeedbackTableCreateCompanionBuilder,
          $$TranslationFeedbackTableUpdateCompanionBuilder,
          (
            TranslationFeedbackData,
            BaseReferences<
              _$AppDatabase,
              $TranslationFeedbackTable,
              TranslationFeedbackData
            >,
          ),
          TranslationFeedbackData,
          PrefetchHooks Function()
        > {
  $$TranslationFeedbackTableTableManager(
    _$AppDatabase db,
    $TranslationFeedbackTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationFeedbackTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationFeedbackTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TranslationFeedbackTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> original = const Value.absent(),
                Value<String> translated = const Value.absent(),
                Value<String> issueType = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranslationFeedbackCompanion(
                id: id,
                original: original,
                translated: translated,
                issueType: issueType,
                comment: comment,
                timestamp: timestamp,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String original,
                required String translated,
                required String issueType,
                Value<String?> comment = const Value.absent(),
                required DateTime timestamp,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranslationFeedbackCompanion.insert(
                id: id,
                original: original,
                translated: translated,
                issueType: issueType,
                comment: comment,
                timestamp: timestamp,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TranslationFeedbackTable,
                    TranslationFeedbackData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TranslationFeedbackTable,
                    TranslationFeedbackData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TranslationFeedbackTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranslationFeedbackTable,
      TranslationFeedbackData,
      $$TranslationFeedbackTableFilterComposer,
      $$TranslationFeedbackTableOrderingComposer,
      $$TranslationFeedbackTableAnnotationComposer,
      $$TranslationFeedbackTableCreateCompanionBuilder,
      $$TranslationFeedbackTableUpdateCompanionBuilder,
      (
        TranslationFeedbackData,
        BaseReferences<
          _$AppDatabase,
          $TranslationFeedbackTable,
          TranslationFeedbackData
        >,
      ),
      TranslationFeedbackData,
      PrefetchHooks Function()
    >;
typedef $$QuickPhrasesTableCreateCompanionBuilder =
    QuickPhrasesCompanion Function({
      required String id,
      required String category,
      required String hindi,
      required String ho,
      required String mundari,
      required String santali,
      Value<int> rowid,
    });
typedef $$QuickPhrasesTableUpdateCompanionBuilder =
    QuickPhrasesCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<String> hindi,
      Value<String> ho,
      Value<String> mundari,
      Value<String> santali,
      Value<int> rowid,
    });

class $$QuickPhrasesTableFilterComposer
    extends Composer<_$AppDatabase, $QuickPhrasesTable> {
  $$QuickPhrasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hindi => $composableBuilder(
    column: $table.hindi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ho => $composableBuilder(
    column: $table.ho,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mundari => $composableBuilder(
    column: $table.mundari,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get santali => $composableBuilder(
    column: $table.santali,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuickPhrasesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuickPhrasesTable> {
  $$QuickPhrasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hindi => $composableBuilder(
    column: $table.hindi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ho => $composableBuilder(
    column: $table.ho,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mundari => $composableBuilder(
    column: $table.mundari,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get santali => $composableBuilder(
    column: $table.santali,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuickPhrasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuickPhrasesTable> {
  $$QuickPhrasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get hindi =>
      $composableBuilder(column: $table.hindi, builder: (column) => column);

  GeneratedColumn<String> get ho =>
      $composableBuilder(column: $table.ho, builder: (column) => column);

  GeneratedColumn<String> get mundari =>
      $composableBuilder(column: $table.mundari, builder: (column) => column);

  GeneratedColumn<String> get santali =>
      $composableBuilder(column: $table.santali, builder: (column) => column);
}

class $$QuickPhrasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuickPhrasesTable,
          QuickPhraseData,
          $$QuickPhrasesTableFilterComposer,
          $$QuickPhrasesTableOrderingComposer,
          $$QuickPhrasesTableAnnotationComposer,
          $$QuickPhrasesTableCreateCompanionBuilder,
          $$QuickPhrasesTableUpdateCompanionBuilder,
          (
            QuickPhraseData,
            BaseReferences<_$AppDatabase, $QuickPhrasesTable, QuickPhraseData>,
          ),
          QuickPhraseData,
          PrefetchHooks Function()
        > {
  $$QuickPhrasesTableTableManager(_$AppDatabase db, $QuickPhrasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuickPhrasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuickPhrasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuickPhrasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> hindi = const Value.absent(),
                Value<String> ho = const Value.absent(),
                Value<String> mundari = const Value.absent(),
                Value<String> santali = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuickPhrasesCompanion(
                id: id,
                category: category,
                hindi: hindi,
                ho: ho,
                mundari: mundari,
                santali: santali,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required String hindi,
                required String ho,
                required String mundari,
                required String santali,
                Value<int> rowid = const Value.absent(),
              }) => QuickPhrasesCompanion.insert(
                id: id,
                category: category,
                hindi: hindi,
                ho: ho,
                mundari: mundari,
                santali: santali,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuickPhrasesTable, QuickPhraseData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $QuickPhrasesTable,
                    QuickPhraseData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuickPhrasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuickPhrasesTable,
      QuickPhraseData,
      $$QuickPhrasesTableFilterComposer,
      $$QuickPhrasesTableOrderingComposer,
      $$QuickPhrasesTableAnnotationComposer,
      $$QuickPhrasesTableCreateCompanionBuilder,
      $$QuickPhrasesTableUpdateCompanionBuilder,
      (
        QuickPhraseData,
        BaseReferences<_$AppDatabase, $QuickPhrasesTable, QuickPhraseData>,
      ),
      QuickPhraseData,
      PrefetchHooks Function()
    >;
typedef $$LanguagePacksTableCreateCompanionBuilder =
    LanguagePacksCompanion Function({
      required String id,
      required String language,
      required int sizeMb,
      required String version,
      required String status,
      Value<double> progress,
      Value<int> rowid,
    });
typedef $$LanguagePacksTableUpdateCompanionBuilder =
    LanguagePacksCompanion Function({
      Value<String> id,
      Value<String> language,
      Value<int> sizeMb,
      Value<String> version,
      Value<String> status,
      Value<double> progress,
      Value<int> rowid,
    });

class $$LanguagePacksTableFilterComposer
    extends Composer<_$AppDatabase, $LanguagePacksTable> {
  $$LanguagePacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeMb => $composableBuilder(
    column: $table.sizeMb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LanguagePacksTableOrderingComposer
    extends Composer<_$AppDatabase, $LanguagePacksTable> {
  $$LanguagePacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeMb => $composableBuilder(
    column: $table.sizeMb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LanguagePacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LanguagePacksTable> {
  $$LanguagePacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get sizeMb =>
      $composableBuilder(column: $table.sizeMb, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);
}

class $$LanguagePacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LanguagePacksTable,
          LanguagePackRecord,
          $$LanguagePacksTableFilterComposer,
          $$LanguagePacksTableOrderingComposer,
          $$LanguagePacksTableAnnotationComposer,
          $$LanguagePacksTableCreateCompanionBuilder,
          $$LanguagePacksTableUpdateCompanionBuilder,
          (
            LanguagePackRecord,
            BaseReferences<
              _$AppDatabase,
              $LanguagePacksTable,
              LanguagePackRecord
            >,
          ),
          LanguagePackRecord,
          PrefetchHooks Function()
        > {
  $$LanguagePacksTableTableManager(_$AppDatabase db, $LanguagePacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LanguagePacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LanguagePacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LanguagePacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> sizeMb = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LanguagePacksCompanion(
                id: id,
                language: language,
                sizeMb: sizeMb,
                version: version,
                status: status,
                progress: progress,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String language,
                required int sizeMb,
                required String version,
                required String status,
                Value<double> progress = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LanguagePacksCompanion.insert(
                id: id,
                language: language,
                sizeMb: sizeMb,
                version: version,
                status: status,
                progress: progress,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LanguagePacksTable, LanguagePackRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LanguagePacksTable,
                    LanguagePackRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LanguagePacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LanguagePacksTable,
      LanguagePackRecord,
      $$LanguagePacksTableFilterComposer,
      $$LanguagePacksTableOrderingComposer,
      $$LanguagePacksTableAnnotationComposer,
      $$LanguagePacksTableCreateCompanionBuilder,
      $$LanguagePacksTableUpdateCompanionBuilder,
      (
        LanguagePackRecord,
        BaseReferences<_$AppDatabase, $LanguagePacksTable, LanguagePackRecord>,
      ),
      LanguagePackRecord,
      PrefetchHooks Function()
    >;
typedef $$ContentPacksTableCreateCompanionBuilder =
    ContentPacksCompanion Function({
      required String id,
      required String title,
      required String description,
      required int sizeMb,
      Value<bool> isInstalled,
      Value<int> rowid,
    });
typedef $$ContentPacksTableUpdateCompanionBuilder =
    ContentPacksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> description,
      Value<int> sizeMb,
      Value<bool> isInstalled,
      Value<int> rowid,
    });

class $$ContentPacksTableFilterComposer
    extends Composer<_$AppDatabase, $ContentPacksTable> {
  $$ContentPacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeMb => $composableBuilder(
    column: $table.sizeMb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInstalled => $composableBuilder(
    column: $table.isInstalled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentPacksTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentPacksTable> {
  $$ContentPacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeMb => $composableBuilder(
    column: $table.sizeMb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInstalled => $composableBuilder(
    column: $table.isInstalled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentPacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentPacksTable> {
  $$ContentPacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeMb =>
      $composableBuilder(column: $table.sizeMb, builder: (column) => column);

  GeneratedColumn<bool> get isInstalled => $composableBuilder(
    column: $table.isInstalled,
    builder: (column) => column,
  );
}

class $$ContentPacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentPacksTable,
          ContentPackRecord,
          $$ContentPacksTableFilterComposer,
          $$ContentPacksTableOrderingComposer,
          $$ContentPacksTableAnnotationComposer,
          $$ContentPacksTableCreateCompanionBuilder,
          $$ContentPacksTableUpdateCompanionBuilder,
          (
            ContentPackRecord,
            BaseReferences<
              _$AppDatabase,
              $ContentPacksTable,
              ContentPackRecord
            >,
          ),
          ContentPackRecord,
          PrefetchHooks Function()
        > {
  $$ContentPacksTableTableManager(_$AppDatabase db, $ContentPacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentPacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentPacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentPacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> sizeMb = const Value.absent(),
                Value<bool> isInstalled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentPacksCompanion(
                id: id,
                title: title,
                description: description,
                sizeMb: sizeMb,
                isInstalled: isInstalled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String description,
                required int sizeMb,
                Value<bool> isInstalled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentPacksCompanion.insert(
                id: id,
                title: title,
                description: description,
                sizeMb: sizeMb,
                isInstalled: isInstalled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContentPacksTable, ContentPackRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ContentPacksTable,
                    ContentPackRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentPacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentPacksTable,
      ContentPackRecord,
      $$ContentPacksTableFilterComposer,
      $$ContentPacksTableOrderingComposer,
      $$ContentPacksTableAnnotationComposer,
      $$ContentPacksTableCreateCompanionBuilder,
      $$ContentPacksTableUpdateCompanionBuilder,
      (
        ContentPackRecord,
        BaseReferences<_$AppDatabase, $ContentPacksTable, ContentPackRecord>,
      ),
      ContentPackRecord,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String id,
  required String entityType,
  required String entityId,
  required String operation,
  required String payload,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> retryCount,
  Value<DateTime?> lastAttemptAt,
  Value<String> status,
  Value<String?> errorMessage,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> retryCount,
  Value<DateTime?> lastAttemptAt,
  Value<String> status,
  Value<String?> errorMessage,
  Value<int> rowid,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                retryCount: retryCount,
                lastAttemptAt: lastAttemptAt,
                status: status,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String operation,
                required String payload,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                retryCount: retryCount,
                lastAttemptAt: lastAttemptAt,
                status: status,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, SyncQueueData>(table),
                  BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db, _db.teachers);
  $$ClassroomsTableTableManager get classrooms =>
      $$ClassroomsTableTableManager(_db, _db.classrooms);
  $$NipunOutcomesTableTableManager get nipunOutcomes =>
      $$NipunOutcomesTableTableManager(_db, _db.nipunOutcomes);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db, _db.lessons);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$LessonDeliveryProgressTableTableManager get lessonDeliveryProgress =>
      $$LessonDeliveryProgressTableTableManager(
        _db,
        _db.lessonDeliveryProgress,
      );
  $$LocalContextsTableTableManager get localContexts =>
      $$LocalContextsTableTableManager(_db, _db.localContexts);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db, _db.students);
  $$AssessmentQuestionsTableTableManager get assessmentQuestions =>
      $$AssessmentQuestionsTableTableManager(_db, _db.assessmentQuestions);
  $$AssessmentResultsTableTableManager get assessmentResults =>
      $$AssessmentResultsTableTableManager(_db, _db.assessmentResults);
  $$LearningGapsTableTableManager get learningGaps =>
      $$LearningGapsTableTableManager(_db, _db.learningGaps);
  $$RemedialRecommendationsTableTableManager get remedialRecommendations =>
      $$RemedialRecommendationsTableTableManager(
        _db,
        _db.remedialRecommendations,
      );
  $$SavedMaterialsTableTableManager get savedMaterials =>
      $$SavedMaterialsTableTableManager(_db, _db.savedMaterials);
  $$TranslationHistoryTableTableManager get translationHistory =>
      $$TranslationHistoryTableTableManager(_db, _db.translationHistory);
  $$TranslationFeedbackTableTableManager get translationFeedback =>
      $$TranslationFeedbackTableTableManager(_db, _db.translationFeedback);
  $$QuickPhrasesTableTableManager get quickPhrases =>
      $$QuickPhrasesTableTableManager(_db, _db.quickPhrases);
  $$LanguagePacksTableTableManager get languagePacks =>
      $$LanguagePacksTableTableManager(_db, _db.languagePacks);
  $$ContentPacksTableTableManager get contentPacks =>
      $$ContentPacksTableTableManager(_db, _db.contentPacks);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
