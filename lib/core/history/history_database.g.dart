// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_database.dart';

// ignore_for_file: type=lint
class $HistoryRecordsTable extends HistoryRecords with TableInfo<$HistoryRecordsTable, HistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountMeta = const VerificationMeta('account');
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>('account', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<HistoryWorkKind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<HistoryWorkKind>($HistoryRecordsTable.$converterkind);
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<int> workId = GeneratedColumn<int>('work_id', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>('title', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorIdMeta = const VerificationMeta('authorId');
  @override
  late final GeneratedColumn<int> authorId = GeneratedColumn<int>('author_id', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _authorNameMeta = const VerificationMeta('authorName');
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xRestrictMeta = const VerificationMeta('xRestrict');
  @override
  late final GeneratedColumn<int> xRestrict = GeneratedColumn<int>('x_restrict', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _aiGeneratedMeta = const VerificationMeta('aiGenerated');
  @override
  late final GeneratedColumn<bool> aiGenerated = GeneratedColumn<bool>(
    'ai_generated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("ai_generated" IN (0, 1))'),
  );
  static const VerificationMeta _viewedAtMeta = const VerificationMeta('viewedAt');
  @override
  late final GeneratedColumn<int> viewedAt = GeneratedColumn<int>('viewed_at', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>('width', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>('height', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pageCountMeta = const VerificationMeta('pageCount');
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>('page_count', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _textLengthMeta = const VerificationMeta('textLength');
  @override
  late final GeneratedColumn<int> textLength = GeneratedColumn<int>('text_length', aliasedName, true, type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
    account,
    kind,
    workId,
    title,
    authorId,
    authorName,
    thumbnailUrl,
    xRestrict,
    aiGenerated,
    viewedAt,
    width,
    height,
    pageCount,
    textLength,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_records';
  @override
  VerificationContext validateIntegrity(Insertable<HistoryRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account')) {
      context.handle(_accountMeta, account.isAcceptableOrUnknown(data['account']!, _accountMeta));
    } else if (isInserting) {
      context.missing(_accountMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(_workIdMeta, workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta));
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(_authorIdMeta, authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta));
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('author_name')) {
      context.handle(_authorNameMeta, authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta));
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(_thumbnailUrlMeta, thumbnailUrl.isAcceptableOrUnknown(data['thumbnail_url']!, _thumbnailUrlMeta));
    } else if (isInserting) {
      context.missing(_thumbnailUrlMeta);
    }
    if (data.containsKey('x_restrict')) {
      context.handle(_xRestrictMeta, xRestrict.isAcceptableOrUnknown(data['x_restrict']!, _xRestrictMeta));
    } else if (isInserting) {
      context.missing(_xRestrictMeta);
    }
    if (data.containsKey('ai_generated')) {
      context.handle(_aiGeneratedMeta, aiGenerated.isAcceptableOrUnknown(data['ai_generated']!, _aiGeneratedMeta));
    } else if (isInserting) {
      context.missing(_aiGeneratedMeta);
    }
    if (data.containsKey('viewed_at')) {
      context.handle(_viewedAtMeta, viewedAt.isAcceptableOrUnknown(data['viewed_at']!, _viewedAtMeta));
    } else if (isInserting) {
      context.missing(_viewedAtMeta);
    }
    if (data.containsKey('width')) {
      context.handle(_widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta, height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('page_count')) {
      context.handle(_pageCountMeta, pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta));
    }
    if (data.containsKey('text_length')) {
      context.handle(_textLengthMeta, textLength.isAcceptableOrUnknown(data['text_length']!, _textLengthMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {account, kind, workId};
  @override
  HistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryRow(
      account: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}account'])!,
      kind: $HistoryRecordsTable.$converterkind.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      workId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}work_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      authorId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}author_id'])!,
      authorName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}author_name'])!,
      thumbnailUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url'])!,
      xRestrict: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}x_restrict'])!,
      aiGenerated: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}ai_generated'])!,
      viewedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}viewed_at'])!,
      width: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}height']),
      pageCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}page_count']),
      textLength: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}text_length']),
    );
  }

  @override
  $HistoryRecordsTable createAlias(String alias) {
    return $HistoryRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<HistoryWorkKind, String, String> $converterkind = const EnumNameConverter<HistoryWorkKind>(HistoryWorkKind.values);
}

class HistoryRow extends DataClass implements Insertable<HistoryRow> {
  /// The account's ID in the account book.
  final String account;
  final HistoryWorkKind kind;
  final int workId;
  final String title;
  final int authorId;
  final String authorName;
  final String thumbnailUrl;
  final int xRestrict;
  final bool aiGenerated;
  final int viewedAt;
  final int? width;
  final int? height;
  final int? pageCount;
  final int? textLength;
  const HistoryRow({
    required this.account,
    required this.kind,
    required this.workId,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.thumbnailUrl,
    required this.xRestrict,
    required this.aiGenerated,
    required this.viewedAt,
    this.width,
    this.height,
    this.pageCount,
    this.textLength,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account'] = Variable<String>(account);
    {
      map['kind'] = Variable<String>($HistoryRecordsTable.$converterkind.toSql(kind));
    }
    map['work_id'] = Variable<int>(workId);
    map['title'] = Variable<String>(title);
    map['author_id'] = Variable<int>(authorId);
    map['author_name'] = Variable<String>(authorName);
    map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    map['x_restrict'] = Variable<int>(xRestrict);
    map['ai_generated'] = Variable<bool>(aiGenerated);
    map['viewed_at'] = Variable<int>(viewedAt);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    if (!nullToAbsent || textLength != null) {
      map['text_length'] = Variable<int>(textLength);
    }
    return map;
  }

  HistoryRecordsCompanion toCompanion(bool nullToAbsent) {
    return HistoryRecordsCompanion(
      account: Value(account),
      kind: Value(kind),
      workId: Value(workId),
      title: Value(title),
      authorId: Value(authorId),
      authorName: Value(authorName),
      thumbnailUrl: Value(thumbnailUrl),
      xRestrict: Value(xRestrict),
      aiGenerated: Value(aiGenerated),
      viewedAt: Value(viewedAt),
      width: width == null && nullToAbsent ? const Value.absent() : Value(width),
      height: height == null && nullToAbsent ? const Value.absent() : Value(height),
      pageCount: pageCount == null && nullToAbsent ? const Value.absent() : Value(pageCount),
      textLength: textLength == null && nullToAbsent ? const Value.absent() : Value(textLength),
    );
  }

  factory HistoryRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryRow(
      account: serializer.fromJson<String>(json['account']),
      kind: $HistoryRecordsTable.$converterkind.fromJson(serializer.fromJson<String>(json['kind'])),
      workId: serializer.fromJson<int>(json['workId']),
      title: serializer.fromJson<String>(json['title']),
      authorId: serializer.fromJson<int>(json['authorId']),
      authorName: serializer.fromJson<String>(json['authorName']),
      thumbnailUrl: serializer.fromJson<String>(json['thumbnailUrl']),
      xRestrict: serializer.fromJson<int>(json['xRestrict']),
      aiGenerated: serializer.fromJson<bool>(json['aiGenerated']),
      viewedAt: serializer.fromJson<int>(json['viewedAt']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
      textLength: serializer.fromJson<int?>(json['textLength']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'account': serializer.toJson<String>(account),
      'kind': serializer.toJson<String>($HistoryRecordsTable.$converterkind.toJson(kind)),
      'workId': serializer.toJson<int>(workId),
      'title': serializer.toJson<String>(title),
      'authorId': serializer.toJson<int>(authorId),
      'authorName': serializer.toJson<String>(authorName),
      'thumbnailUrl': serializer.toJson<String>(thumbnailUrl),
      'xRestrict': serializer.toJson<int>(xRestrict),
      'aiGenerated': serializer.toJson<bool>(aiGenerated),
      'viewedAt': serializer.toJson<int>(viewedAt),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'pageCount': serializer.toJson<int?>(pageCount),
      'textLength': serializer.toJson<int?>(textLength),
    };
  }

  HistoryRow copyWith({
    String? account,
    HistoryWorkKind? kind,
    int? workId,
    String? title,
    int? authorId,
    String? authorName,
    String? thumbnailUrl,
    int? xRestrict,
    bool? aiGenerated,
    int? viewedAt,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> pageCount = const Value.absent(),
    Value<int?> textLength = const Value.absent(),
  }) => HistoryRow(
    account: account ?? this.account,
    kind: kind ?? this.kind,
    workId: workId ?? this.workId,
    title: title ?? this.title,
    authorId: authorId ?? this.authorId,
    authorName: authorName ?? this.authorName,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    xRestrict: xRestrict ?? this.xRestrict,
    aiGenerated: aiGenerated ?? this.aiGenerated,
    viewedAt: viewedAt ?? this.viewedAt,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
    textLength: textLength.present ? textLength.value : this.textLength,
  );
  HistoryRow copyWithCompanion(HistoryRecordsCompanion data) {
    return HistoryRow(
      account: data.account.present ? data.account.value : this.account,
      kind: data.kind.present ? data.kind.value : this.kind,
      workId: data.workId.present ? data.workId.value : this.workId,
      title: data.title.present ? data.title.value : this.title,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      authorName: data.authorName.present ? data.authorName.value : this.authorName,
      thumbnailUrl: data.thumbnailUrl.present ? data.thumbnailUrl.value : this.thumbnailUrl,
      xRestrict: data.xRestrict.present ? data.xRestrict.value : this.xRestrict,
      aiGenerated: data.aiGenerated.present ? data.aiGenerated.value : this.aiGenerated,
      viewedAt: data.viewedAt.present ? data.viewedAt.value : this.viewedAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      textLength: data.textLength.present ? data.textLength.value : this.textLength,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryRow(')
          ..write('account: $account, ')
          ..write('kind: $kind, ')
          ..write('workId: $workId, ')
          ..write('title: $title, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('xRestrict: $xRestrict, ')
          ..write('aiGenerated: $aiGenerated, ')
          ..write('viewedAt: $viewedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('pageCount: $pageCount, ')
          ..write('textLength: $textLength')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(account, kind, workId, title, authorId, authorName, thumbnailUrl, xRestrict, aiGenerated, viewedAt, width, height, pageCount, textLength);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryRow &&
          other.account == this.account &&
          other.kind == this.kind &&
          other.workId == this.workId &&
          other.title == this.title &&
          other.authorId == this.authorId &&
          other.authorName == this.authorName &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.xRestrict == this.xRestrict &&
          other.aiGenerated == this.aiGenerated &&
          other.viewedAt == this.viewedAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.pageCount == this.pageCount &&
          other.textLength == this.textLength);
}

class HistoryRecordsCompanion extends UpdateCompanion<HistoryRow> {
  final Value<String> account;
  final Value<HistoryWorkKind> kind;
  final Value<int> workId;
  final Value<String> title;
  final Value<int> authorId;
  final Value<String> authorName;
  final Value<String> thumbnailUrl;
  final Value<int> xRestrict;
  final Value<bool> aiGenerated;
  final Value<int> viewedAt;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> pageCount;
  final Value<int?> textLength;
  final Value<int> rowid;
  const HistoryRecordsCompanion({
    this.account = const Value.absent(),
    this.kind = const Value.absent(),
    this.workId = const Value.absent(),
    this.title = const Value.absent(),
    this.authorId = const Value.absent(),
    this.authorName = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.xRestrict = const Value.absent(),
    this.aiGenerated = const Value.absent(),
    this.viewedAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.textLength = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryRecordsCompanion.insert({
    required String account,
    required HistoryWorkKind kind,
    required int workId,
    required String title,
    required int authorId,
    required String authorName,
    required String thumbnailUrl,
    required int xRestrict,
    required bool aiGenerated,
    required int viewedAt,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.textLength = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : account = Value(account),
       kind = Value(kind),
       workId = Value(workId),
       title = Value(title),
       authorId = Value(authorId),
       authorName = Value(authorName),
       thumbnailUrl = Value(thumbnailUrl),
       xRestrict = Value(xRestrict),
       aiGenerated = Value(aiGenerated),
       viewedAt = Value(viewedAt);
  static Insertable<HistoryRow> custom({
    Expression<String>? account,
    Expression<String>? kind,
    Expression<int>? workId,
    Expression<String>? title,
    Expression<int>? authorId,
    Expression<String>? authorName,
    Expression<String>? thumbnailUrl,
    Expression<int>? xRestrict,
    Expression<bool>? aiGenerated,
    Expression<int>? viewedAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? pageCount,
    Expression<int>? textLength,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (account != null) 'account': account,
      if (kind != null) 'kind': kind,
      if (workId != null) 'work_id': workId,
      if (title != null) 'title': title,
      if (authorId != null) 'author_id': authorId,
      if (authorName != null) 'author_name': authorName,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (xRestrict != null) 'x_restrict': xRestrict,
      if (aiGenerated != null) 'ai_generated': aiGenerated,
      if (viewedAt != null) 'viewed_at': viewedAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (pageCount != null) 'page_count': pageCount,
      if (textLength != null) 'text_length': textLength,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryRecordsCompanion copyWith({
    Value<String>? account,
    Value<HistoryWorkKind>? kind,
    Value<int>? workId,
    Value<String>? title,
    Value<int>? authorId,
    Value<String>? authorName,
    Value<String>? thumbnailUrl,
    Value<int>? xRestrict,
    Value<bool>? aiGenerated,
    Value<int>? viewedAt,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? pageCount,
    Value<int?>? textLength,
    Value<int>? rowid,
  }) {
    return HistoryRecordsCompanion(
      account: account ?? this.account,
      kind: kind ?? this.kind,
      workId: workId ?? this.workId,
      title: title ?? this.title,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      xRestrict: xRestrict ?? this.xRestrict,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      viewedAt: viewedAt ?? this.viewedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      pageCount: pageCount ?? this.pageCount,
      textLength: textLength ?? this.textLength,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($HistoryRecordsTable.$converterkind.toSql(kind.value));
    }
    if (workId.present) {
      map['work_id'] = Variable<int>(workId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<int>(authorId.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (xRestrict.present) {
      map['x_restrict'] = Variable<int>(xRestrict.value);
    }
    if (aiGenerated.present) {
      map['ai_generated'] = Variable<bool>(aiGenerated.value);
    }
    if (viewedAt.present) {
      map['viewed_at'] = Variable<int>(viewedAt.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (textLength.present) {
      map['text_length'] = Variable<int>(textLength.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryRecordsCompanion(')
          ..write('account: $account, ')
          ..write('kind: $kind, ')
          ..write('workId: $workId, ')
          ..write('title: $title, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('xRestrict: $xRestrict, ')
          ..write('aiGenerated: $aiGenerated, ')
          ..write('viewedAt: $viewedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('pageCount: $pageCount, ')
          ..write('textLength: $textLength, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$HistoryDatabase extends GeneratedDatabase {
  _$HistoryDatabase(QueryExecutor e) : super(e);
  $HistoryDatabaseManager get managers => $HistoryDatabaseManager(this);
  late final $HistoryRecordsTable historyRecords = $HistoryRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [historyRecords];
}

typedef $$HistoryRecordsTableCreateCompanionBuilder =
    HistoryRecordsCompanion Function({
      required String account,
      required HistoryWorkKind kind,
      required int workId,
      required String title,
      required int authorId,
      required String authorName,
      required String thumbnailUrl,
      required int xRestrict,
      required bool aiGenerated,
      required int viewedAt,
      Value<int?> width,
      Value<int?> height,
      Value<int?> pageCount,
      Value<int?> textLength,
      Value<int> rowid,
    });
typedef $$HistoryRecordsTableUpdateCompanionBuilder =
    HistoryRecordsCompanion Function({
      Value<String> account,
      Value<HistoryWorkKind> kind,
      Value<int> workId,
      Value<String> title,
      Value<int> authorId,
      Value<String> authorName,
      Value<String> thumbnailUrl,
      Value<int> xRestrict,
      Value<bool> aiGenerated,
      Value<int> viewedAt,
      Value<int?> width,
      Value<int?> height,
      Value<int?> pageCount,
      Value<int?> textLength,
      Value<int> rowid,
    });

class $$HistoryRecordsTableFilterComposer extends Composer<_$HistoryDatabase, $HistoryRecordsTable> {
  $$HistoryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get account => $composableBuilder(column: $table.account, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<HistoryWorkKind, HistoryWorkKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get workId => $composableBuilder(column: $table.workId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get authorId => $composableBuilder(column: $table.authorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get authorName => $composableBuilder(column: $table.authorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xRestrict => $composableBuilder(column: $table.xRestrict, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get aiGenerated => $composableBuilder(column: $table.aiGenerated, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get viewedAt => $composableBuilder(column: $table.viewedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageCount => $composableBuilder(column: $table.pageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get textLength => $composableBuilder(column: $table.textLength, builder: (column) => ColumnFilters(column));
}

class $$HistoryRecordsTableOrderingComposer extends Composer<_$HistoryDatabase, $HistoryRecordsTable> {
  $$HistoryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get account => $composableBuilder(column: $table.account, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get workId => $composableBuilder(column: $table.workId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get authorId => $composableBuilder(column: $table.authorId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get authorName => $composableBuilder(column: $table.authorName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(column: $table.thumbnailUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xRestrict => $composableBuilder(column: $table.xRestrict, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get aiGenerated => $composableBuilder(column: $table.aiGenerated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get viewedAt => $composableBuilder(column: $table.viewedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageCount => $composableBuilder(column: $table.pageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get textLength => $composableBuilder(column: $table.textLength, builder: (column) => ColumnOrderings(column));
}

class $$HistoryRecordsTableAnnotationComposer extends Composer<_$HistoryDatabase, $HistoryRecordsTable> {
  $$HistoryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get account => $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HistoryWorkKind, String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get workId => $composableBuilder(column: $table.workId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get authorId => $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(column: $table.authorName, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(column: $table.thumbnailUrl, builder: (column) => column);

  GeneratedColumn<int> get xRestrict => $composableBuilder(column: $table.xRestrict, builder: (column) => column);

  GeneratedColumn<bool> get aiGenerated => $composableBuilder(column: $table.aiGenerated, builder: (column) => column);

  GeneratedColumn<int> get viewedAt => $composableBuilder(column: $table.viewedAt, builder: (column) => column);

  GeneratedColumn<int> get width => $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height => $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get pageCount => $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<int> get textLength => $composableBuilder(column: $table.textLength, builder: (column) => column);
}

class $$HistoryRecordsTableTableManager
    extends
        RootTableManager<
          _$HistoryDatabase,
          $HistoryRecordsTable,
          HistoryRow,
          $$HistoryRecordsTableFilterComposer,
          $$HistoryRecordsTableOrderingComposer,
          $$HistoryRecordsTableAnnotationComposer,
          $$HistoryRecordsTableCreateCompanionBuilder,
          $$HistoryRecordsTableUpdateCompanionBuilder,
          (HistoryRow, BaseReferences<_$HistoryDatabase, $HistoryRecordsTable, HistoryRow>),
          HistoryRow,
          PrefetchHooks Function()
        > {
  $$HistoryRecordsTableTableManager(_$HistoryDatabase db, $HistoryRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HistoryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HistoryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HistoryRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> account = const Value.absent(),
                Value<HistoryWorkKind> kind = const Value.absent(),
                Value<int> workId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> authorId = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<String> thumbnailUrl = const Value.absent(),
                Value<int> xRestrict = const Value.absent(),
                Value<bool> aiGenerated = const Value.absent(),
                Value<int> viewedAt = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<int?> textLength = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryRecordsCompanion(
                account: account,
                kind: kind,
                workId: workId,
                title: title,
                authorId: authorId,
                authorName: authorName,
                thumbnailUrl: thumbnailUrl,
                xRestrict: xRestrict,
                aiGenerated: aiGenerated,
                viewedAt: viewedAt,
                width: width,
                height: height,
                pageCount: pageCount,
                textLength: textLength,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String account,
                required HistoryWorkKind kind,
                required int workId,
                required String title,
                required int authorId,
                required String authorName,
                required String thumbnailUrl,
                required int xRestrict,
                required bool aiGenerated,
                required int viewedAt,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<int?> textLength = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryRecordsCompanion.insert(
                account: account,
                kind: kind,
                workId: workId,
                title: title,
                authorId: authorId,
                authorName: authorName,
                thumbnailUrl: thumbnailUrl,
                xRestrict: xRestrict,
                aiGenerated: aiGenerated,
                viewedAt: viewedAt,
                width: width,
                height: height,
                pageCount: pageCount,
                textLength: textLength,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$HistoryRecordsTable, HistoryRow>(table), BaseReferences<_$HistoryDatabase, $HistoryRecordsTable, HistoryRow>(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$HistoryDatabase,
      $HistoryRecordsTable,
      HistoryRow,
      $$HistoryRecordsTableFilterComposer,
      $$HistoryRecordsTableOrderingComposer,
      $$HistoryRecordsTableAnnotationComposer,
      $$HistoryRecordsTableCreateCompanionBuilder,
      $$HistoryRecordsTableUpdateCompanionBuilder,
      (HistoryRow, BaseReferences<_$HistoryDatabase, $HistoryRecordsTable, HistoryRow>),
      HistoryRow,
      PrefetchHooks Function()
    >;

class $HistoryDatabaseManager {
  final _$HistoryDatabase _db;
  $HistoryDatabaseManager(this._db);
  $$HistoryRecordsTableTableManager get historyRecords => $$HistoryRecordsTableTableManager(_db, _db.historyRecords);
}
