// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WordStatesTable extends WordStates
    with TableInfo<$WordStatesTable, WordStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stabilityMeta =
      const VerificationMeta('stability');
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
      'stability', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
      'due_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastReviewAtMeta =
      const VerificationMeta('lastReviewAt');
  @override
  late final GeneratedColumn<int> lastReviewAt = GeneratedColumn<int>(
      'last_review_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
      'lapses', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [wordId, stability, difficulty, dueAt, lastReviewAt, reps, lapses];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_states';
  @override
  VerificationContext validateIntegrity(Insertable<WordStateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('stability')) {
      context.handle(_stabilityMeta,
          stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta));
    } else if (isInserting) {
      context.missing(_stabilityMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
          _dueAtMeta, dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta));
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('last_review_at')) {
      context.handle(
          _lastReviewAtMeta,
          lastReviewAt.isAcceptableOrUnknown(
              data['last_review_at']!, _lastReviewAtMeta));
    } else if (isInserting) {
      context.missing(_lastReviewAtMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('lapses')) {
      context.handle(_lapsesMeta,
          lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  WordStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordStateRow(
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      stability: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stability'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}difficulty'])!,
      dueAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due_at'])!,
      lastReviewAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_review_at'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      lapses: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lapses'])!,
    );
  }

  @override
  $WordStatesTable createAlias(String alias) {
    return $WordStatesTable(attachedDatabase, alias);
  }
}

class WordStateRow extends DataClass implements Insertable<WordStateRow> {
  /// = `content/words/<id>.yaml`
  final String wordId;

  /// پایداریِ FSRS، به روز.
  final double stability;

  /// ۱٫۰ تا ۱۰٫۰
  final double difficulty;
  final int dueAt;
  final int lastReviewAt;
  final int reps;
  final int lapses;
  const WordStateRow(
      {required this.wordId,
      required this.stability,
      required this.difficulty,
      required this.dueAt,
      required this.lastReviewAt,
      required this.reps,
      required this.lapses});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['due_at'] = Variable<int>(dueAt);
    map['last_review_at'] = Variable<int>(lastReviewAt);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    return map;
  }

  WordStatesCompanion toCompanion(bool nullToAbsent) {
    return WordStatesCompanion(
      wordId: Value(wordId),
      stability: Value(stability),
      difficulty: Value(difficulty),
      dueAt: Value(dueAt),
      lastReviewAt: Value(lastReviewAt),
      reps: Value(reps),
      lapses: Value(lapses),
    );
  }

  factory WordStateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordStateRow(
      wordId: serializer.fromJson<String>(json['wordId']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      dueAt: serializer.fromJson<int>(json['dueAt']),
      lastReviewAt: serializer.fromJson<int>(json['lastReviewAt']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'dueAt': serializer.toJson<int>(dueAt),
      'lastReviewAt': serializer.toJson<int>(lastReviewAt),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
    };
  }

  WordStateRow copyWith(
          {String? wordId,
          double? stability,
          double? difficulty,
          int? dueAt,
          int? lastReviewAt,
          int? reps,
          int? lapses}) =>
      WordStateRow(
        wordId: wordId ?? this.wordId,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        dueAt: dueAt ?? this.dueAt,
        lastReviewAt: lastReviewAt ?? this.lastReviewAt,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
      );
  WordStateRow copyWithCompanion(WordStatesCompanion data) {
    return WordStateRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      lastReviewAt: data.lastReviewAt.present
          ? data.lastReviewAt.value
          : this.lastReviewAt,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordStateRow(')
          ..write('wordId: $wordId, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewAt: $lastReviewAt, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      wordId, stability, difficulty, dueAt, lastReviewAt, reps, lapses);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordStateRow &&
          other.wordId == this.wordId &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.dueAt == this.dueAt &&
          other.lastReviewAt == this.lastReviewAt &&
          other.reps == this.reps &&
          other.lapses == this.lapses);
}

class WordStatesCompanion extends UpdateCompanion<WordStateRow> {
  final Value<String> wordId;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<int> dueAt;
  final Value<int> lastReviewAt;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int> rowid;
  const WordStatesCompanion({
    this.wordId = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastReviewAt = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordStatesCompanion.insert({
    required String wordId,
    required double stability,
    required double difficulty,
    required int dueAt,
    required int lastReviewAt,
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : wordId = Value(wordId),
        stability = Value(stability),
        difficulty = Value(difficulty),
        dueAt = Value(dueAt),
        lastReviewAt = Value(lastReviewAt);
  static Insertable<WordStateRow> custom({
    Expression<String>? wordId,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<int>? dueAt,
    Expression<int>? lastReviewAt,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (dueAt != null) 'due_at': dueAt,
      if (lastReviewAt != null) 'last_review_at': lastReviewAt,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordStatesCompanion copyWith(
      {Value<String>? wordId,
      Value<double>? stability,
      Value<double>? difficulty,
      Value<int>? dueAt,
      Value<int>? lastReviewAt,
      Value<int>? reps,
      Value<int>? lapses,
      Value<int>? rowid}) {
    return WordStatesCompanion(
      wordId: wordId ?? this.wordId,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      dueAt: dueAt ?? this.dueAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (lastReviewAt.present) {
      map['last_review_at'] = Variable<int>(lastReviewAt.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordStatesCompanion(')
          ..write('wordId: $wordId, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewAt: $lastReviewAt, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
      'word_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES word_states (word_id)'));
  static const VerificationMeta _reviewedAtMeta =
      const VerificationMeta('reviewedAt');
  @override
  late final GeneratedColumn<int> reviewedAt = GeneratedColumn<int>(
      'reviewed_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _elapsedDaysMeta =
      const VerificationMeta('elapsedDays');
  @override
  late final GeneratedColumn<double> elapsedDays = GeneratedColumn<double>(
      'elapsed_days', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _answerMsMeta =
      const VerificationMeta('answerMs');
  @override
  late final GeneratedColumn<int> answerMs = GeneratedColumn<int>(
      'answer_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _exerciseMeta =
      const VerificationMeta('exercise');
  @override
  late final GeneratedColumn<String> exercise = GeneratedColumn<String>(
      'exercise', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, wordId, reviewedAt, rating, elapsedDays, answerMs, exercise];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewLogRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
          _reviewedAtMeta,
          reviewedAt.isAcceptableOrUnknown(
              data['reviewed_at']!, _reviewedAtMeta));
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('elapsed_days')) {
      context.handle(
          _elapsedDaysMeta,
          elapsedDays.isAcceptableOrUnknown(
              data['elapsed_days']!, _elapsedDaysMeta));
    } else if (isInserting) {
      context.missing(_elapsedDaysMeta);
    }
    if (data.containsKey('answer_ms')) {
      context.handle(_answerMsMeta,
          answerMs.isAcceptableOrUnknown(data['answer_ms']!, _answerMsMeta));
    } else if (isInserting) {
      context.missing(_answerMsMeta);
    }
    if (data.containsKey('exercise')) {
      context.handle(_exerciseMeta,
          exercise.isAcceptableOrUnknown(data['exercise']!, _exerciseMeta));
    } else if (isInserting) {
      context.missing(_exerciseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLogRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_id'])!,
      reviewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reviewed_at'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating'])!,
      elapsedDays: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}elapsed_days'])!,
      answerMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}answer_ms'])!,
      exercise: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise'])!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLogRow extends DataClass implements Insertable<ReviewLogRow> {
  final int id;
  final String wordId;
  final int reviewedAt;

  /// ۱..۴ — دوباره، سخت، خوب، آسان.
  final int rating;
  final double elapsedDays;
  final int answerMs;

  /// گزینش، بیت‌یاب، …
  final String exercise;
  const ReviewLogRow(
      {required this.id,
      required this.wordId,
      required this.reviewedAt,
      required this.rating,
      required this.elapsedDays,
      required this.answerMs,
      required this.exercise});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<String>(wordId);
    map['reviewed_at'] = Variable<int>(reviewedAt);
    map['rating'] = Variable<int>(rating);
    map['elapsed_days'] = Variable<double>(elapsedDays);
    map['answer_ms'] = Variable<int>(answerMs);
    map['exercise'] = Variable<String>(exercise);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      reviewedAt: Value(reviewedAt),
      rating: Value(rating),
      elapsedDays: Value(elapsedDays),
      answerMs: Value(answerMs),
      exercise: Value(exercise),
    );
  }

  factory ReviewLogRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLogRow(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<String>(json['wordId']),
      reviewedAt: serializer.fromJson<int>(json['reviewedAt']),
      rating: serializer.fromJson<int>(json['rating']),
      elapsedDays: serializer.fromJson<double>(json['elapsedDays']),
      answerMs: serializer.fromJson<int>(json['answerMs']),
      exercise: serializer.fromJson<String>(json['exercise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<String>(wordId),
      'reviewedAt': serializer.toJson<int>(reviewedAt),
      'rating': serializer.toJson<int>(rating),
      'elapsedDays': serializer.toJson<double>(elapsedDays),
      'answerMs': serializer.toJson<int>(answerMs),
      'exercise': serializer.toJson<String>(exercise),
    };
  }

  ReviewLogRow copyWith(
          {int? id,
          String? wordId,
          int? reviewedAt,
          int? rating,
          double? elapsedDays,
          int? answerMs,
          String? exercise}) =>
      ReviewLogRow(
        id: id ?? this.id,
        wordId: wordId ?? this.wordId,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        rating: rating ?? this.rating,
        elapsedDays: elapsedDays ?? this.elapsedDays,
        answerMs: answerMs ?? this.answerMs,
        exercise: exercise ?? this.exercise,
      );
  ReviewLogRow copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLogRow(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      reviewedAt:
          data.reviewedAt.present ? data.reviewedAt.value : this.reviewedAt,
      rating: data.rating.present ? data.rating.value : this.rating,
      elapsedDays:
          data.elapsedDays.present ? data.elapsedDays.value : this.elapsedDays,
      answerMs: data.answerMs.present ? data.answerMs.value : this.answerMs,
      exercise: data.exercise.present ? data.exercise.value : this.exercise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogRow(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rating: $rating, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('answerMs: $answerMs, ')
          ..write('exercise: $exercise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, wordId, reviewedAt, rating, elapsedDays, answerMs, exercise);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLogRow &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.reviewedAt == this.reviewedAt &&
          other.rating == this.rating &&
          other.elapsedDays == this.elapsedDays &&
          other.answerMs == this.answerMs &&
          other.exercise == this.exercise);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLogRow> {
  final Value<int> id;
  final Value<String> wordId;
  final Value<int> reviewedAt;
  final Value<int> rating;
  final Value<double> elapsedDays;
  final Value<int> answerMs;
  final Value<String> exercise;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rating = const Value.absent(),
    this.elapsedDays = const Value.absent(),
    this.answerMs = const Value.absent(),
    this.exercise = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required String wordId,
    required int reviewedAt,
    required int rating,
    required double elapsedDays,
    required int answerMs,
    required String exercise,
  })  : wordId = Value(wordId),
        reviewedAt = Value(reviewedAt),
        rating = Value(rating),
        elapsedDays = Value(elapsedDays),
        answerMs = Value(answerMs),
        exercise = Value(exercise);
  static Insertable<ReviewLogRow> custom({
    Expression<int>? id,
    Expression<String>? wordId,
    Expression<int>? reviewedAt,
    Expression<int>? rating,
    Expression<double>? elapsedDays,
    Expression<int>? answerMs,
    Expression<String>? exercise,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rating != null) 'rating': rating,
      if (elapsedDays != null) 'elapsed_days': elapsedDays,
      if (answerMs != null) 'answer_ms': answerMs,
      if (exercise != null) 'exercise': exercise,
    });
  }

  ReviewLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? wordId,
      Value<int>? reviewedAt,
      Value<int>? rating,
      Value<double>? elapsedDays,
      Value<int>? answerMs,
      Value<String>? exercise}) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rating: rating ?? this.rating,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      answerMs: answerMs ?? this.answerMs,
      exercise: exercise ?? this.exercise,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<int>(reviewedAt.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (elapsedDays.present) {
      map['elapsed_days'] = Variable<double>(elapsedDays.value);
    }
    if (answerMs.present) {
      map['answer_ms'] = Variable<int>(answerMs.value);
    }
    if (exercise.present) {
      map['exercise'] = Variable<String>(exercise.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rating: $rating, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('answerMs: $answerMs, ')
          ..write('exercise: $exercise')
          ..write(')'))
        .toString();
  }
}

class $StationProgressesTable extends StationProgresses
    with TableInfo<$StationProgressesTable, StationProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StationProgressesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stationIdMeta =
      const VerificationMeta('stationId');
  @override
  late final GeneratedColumn<String> stationId = GeneratedColumn<String>(
      'station_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bestRatioMeta =
      const VerificationMeta('bestRatio');
  @override
  late final GeneratedColumn<double> bestRatio = GeneratedColumn<double>(
      'best_ratio', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [stationId, completedAt, bestRatio];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'station_progresses';
  @override
  VerificationContext validateIntegrity(Insertable<StationProgressRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('station_id')) {
      context.handle(_stationIdMeta,
          stationId.isAcceptableOrUnknown(data['station_id']!, _stationIdMeta));
    } else if (isInserting) {
      context.missing(_stationIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('best_ratio')) {
      context.handle(_bestRatioMeta,
          bestRatio.isAcceptableOrUnknown(data['best_ratio']!, _bestRatioMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stationId};
  @override
  StationProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StationProgressRow(
      stationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}station_id'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
      bestRatio: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}best_ratio'])!,
    );
  }

  @override
  $StationProgressesTable createAlias(String alias) {
    return $StationProgressesTable(attachedDatabase, alias);
  }
}

class StationProgressRow extends DataClass
    implements Insertable<StationProgressRow> {
  final String stationId;

  /// NULL یعنی هنوز تمام نشده.
  final int? completedAt;
  final double bestRatio;
  const StationProgressRow(
      {required this.stationId, this.completedAt, required this.bestRatio});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['station_id'] = Variable<String>(stationId);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['best_ratio'] = Variable<double>(bestRatio);
    return map;
  }

  StationProgressesCompanion toCompanion(bool nullToAbsent) {
    return StationProgressesCompanion(
      stationId: Value(stationId),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      bestRatio: Value(bestRatio),
    );
  }

  factory StationProgressRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StationProgressRow(
      stationId: serializer.fromJson<String>(json['stationId']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      bestRatio: serializer.fromJson<double>(json['bestRatio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stationId': serializer.toJson<String>(stationId),
      'completedAt': serializer.toJson<int?>(completedAt),
      'bestRatio': serializer.toJson<double>(bestRatio),
    };
  }

  StationProgressRow copyWith(
          {String? stationId,
          Value<int?> completedAt = const Value.absent(),
          double? bestRatio}) =>
      StationProgressRow(
        stationId: stationId ?? this.stationId,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        bestRatio: bestRatio ?? this.bestRatio,
      );
  StationProgressRow copyWithCompanion(StationProgressesCompanion data) {
    return StationProgressRow(
      stationId: data.stationId.present ? data.stationId.value : this.stationId,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      bestRatio: data.bestRatio.present ? data.bestRatio.value : this.bestRatio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StationProgressRow(')
          ..write('stationId: $stationId, ')
          ..write('completedAt: $completedAt, ')
          ..write('bestRatio: $bestRatio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stationId, completedAt, bestRatio);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StationProgressRow &&
          other.stationId == this.stationId &&
          other.completedAt == this.completedAt &&
          other.bestRatio == this.bestRatio);
}

class StationProgressesCompanion extends UpdateCompanion<StationProgressRow> {
  final Value<String> stationId;
  final Value<int?> completedAt;
  final Value<double> bestRatio;
  final Value<int> rowid;
  const StationProgressesCompanion({
    this.stationId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.bestRatio = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StationProgressesCompanion.insert({
    required String stationId,
    this.completedAt = const Value.absent(),
    this.bestRatio = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : stationId = Value(stationId);
  static Insertable<StationProgressRow> custom({
    Expression<String>? stationId,
    Expression<int>? completedAt,
    Expression<double>? bestRatio,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stationId != null) 'station_id': stationId,
      if (completedAt != null) 'completed_at': completedAt,
      if (bestRatio != null) 'best_ratio': bestRatio,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StationProgressesCompanion copyWith(
      {Value<String>? stationId,
      Value<int?>? completedAt,
      Value<double>? bestRatio,
      Value<int>? rowid}) {
    return StationProgressesCompanion(
      stationId: stationId ?? this.stationId,
      completedAt: completedAt ?? this.completedAt,
      bestRatio: bestRatio ?? this.bestRatio,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stationId.present) {
      map['station_id'] = Variable<String>(stationId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (bestRatio.present) {
      map['best_ratio'] = Variable<double>(bestRatio.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StationProgressesCompanion(')
          ..write('stationId: $stationId, ')
          ..write('completedAt: $completedAt, ')
          ..write('bestRatio: $bestRatio, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreaksTable extends Streaks with TableInfo<$StreaksTable, StreakRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreaksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _currentDaysMeta =
      const VerificationMeta('currentDays');
  @override
  late final GeneratedColumn<int> currentDays = GeneratedColumn<int>(
      'current_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _longestDaysMeta =
      const VerificationMeta('longestDays');
  @override
  late final GeneratedColumn<int> longestDays = GeneratedColumn<int>(
      'longest_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastActiveOnMeta =
      const VerificationMeta('lastActiveOn');
  @override
  late final GeneratedColumn<String> lastActiveOn = GeneratedColumn<String>(
      'last_active_on', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jamEJamMeta =
      const VerificationMeta('jamEJam');
  @override
  late final GeneratedColumn<int> jamEJam = GeneratedColumn<int>(
      'jam_e_jam', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, currentDays, longestDays, lastActiveOn, jamEJam];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streaks';
  @override
  VerificationContext validateIntegrity(Insertable<StreakRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_days')) {
      context.handle(
          _currentDaysMeta,
          currentDays.isAcceptableOrUnknown(
              data['current_days']!, _currentDaysMeta));
    }
    if (data.containsKey('longest_days')) {
      context.handle(
          _longestDaysMeta,
          longestDays.isAcceptableOrUnknown(
              data['longest_days']!, _longestDaysMeta));
    }
    if (data.containsKey('last_active_on')) {
      context.handle(
          _lastActiveOnMeta,
          lastActiveOn.isAcceptableOrUnknown(
              data['last_active_on']!, _lastActiveOnMeta));
    } else if (isInserting) {
      context.missing(_lastActiveOnMeta);
    }
    if (data.containsKey('jam_e_jam')) {
      context.handle(_jamEJamMeta,
          jamEJam.isAcceptableOrUnknown(data['jam_e_jam']!, _jamEJamMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      currentDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_days'])!,
      longestDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}longest_days'])!,
      lastActiveOn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_active_on'])!,
      jamEJam: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}jam_e_jam'])!,
    );
  }

  @override
  $StreaksTable createAlias(String alias) {
    return $StreaksTable(attachedDatabase, alias);
  }
}

class StreakRow extends DataClass implements Insertable<StreakRow> {
  final int id;
  final int currentDays;
  final int longestDays;

  /// تاریخِ محلی `YYYY-MM-DD` — نه unix. زنجیره با «روزِ کاربر» کار دارد؛
  /// کسی که ساعت ۲۳:۵۰ تمرین می‌کند نباید به‌خاطر منطقه‌ی زمانی روزش را ببازد.
  final String lastActiveOn;

  /// محافظِ زنجیره. بیشینه ۲ — در کد نگه داشته می‌شود، نه تنها در طرح‌واره.
  final int jamEJam;
  const StreakRow(
      {required this.id,
      required this.currentDays,
      required this.longestDays,
      required this.lastActiveOn,
      required this.jamEJam});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current_days'] = Variable<int>(currentDays);
    map['longest_days'] = Variable<int>(longestDays);
    map['last_active_on'] = Variable<String>(lastActiveOn);
    map['jam_e_jam'] = Variable<int>(jamEJam);
    return map;
  }

  StreaksCompanion toCompanion(bool nullToAbsent) {
    return StreaksCompanion(
      id: Value(id),
      currentDays: Value(currentDays),
      longestDays: Value(longestDays),
      lastActiveOn: Value(lastActiveOn),
      jamEJam: Value(jamEJam),
    );
  }

  factory StreakRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakRow(
      id: serializer.fromJson<int>(json['id']),
      currentDays: serializer.fromJson<int>(json['currentDays']),
      longestDays: serializer.fromJson<int>(json['longestDays']),
      lastActiveOn: serializer.fromJson<String>(json['lastActiveOn']),
      jamEJam: serializer.fromJson<int>(json['jamEJam']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentDays': serializer.toJson<int>(currentDays),
      'longestDays': serializer.toJson<int>(longestDays),
      'lastActiveOn': serializer.toJson<String>(lastActiveOn),
      'jamEJam': serializer.toJson<int>(jamEJam),
    };
  }

  StreakRow copyWith(
          {int? id,
          int? currentDays,
          int? longestDays,
          String? lastActiveOn,
          int? jamEJam}) =>
      StreakRow(
        id: id ?? this.id,
        currentDays: currentDays ?? this.currentDays,
        longestDays: longestDays ?? this.longestDays,
        lastActiveOn: lastActiveOn ?? this.lastActiveOn,
        jamEJam: jamEJam ?? this.jamEJam,
      );
  StreakRow copyWithCompanion(StreaksCompanion data) {
    return StreakRow(
      id: data.id.present ? data.id.value : this.id,
      currentDays:
          data.currentDays.present ? data.currentDays.value : this.currentDays,
      longestDays:
          data.longestDays.present ? data.longestDays.value : this.longestDays,
      lastActiveOn: data.lastActiveOn.present
          ? data.lastActiveOn.value
          : this.lastActiveOn,
      jamEJam: data.jamEJam.present ? data.jamEJam.value : this.jamEJam,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakRow(')
          ..write('id: $id, ')
          ..write('currentDays: $currentDays, ')
          ..write('longestDays: $longestDays, ')
          ..write('lastActiveOn: $lastActiveOn, ')
          ..write('jamEJam: $jamEJam')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, currentDays, longestDays, lastActiveOn, jamEJam);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakRow &&
          other.id == this.id &&
          other.currentDays == this.currentDays &&
          other.longestDays == this.longestDays &&
          other.lastActiveOn == this.lastActiveOn &&
          other.jamEJam == this.jamEJam);
}

class StreaksCompanion extends UpdateCompanion<StreakRow> {
  final Value<int> id;
  final Value<int> currentDays;
  final Value<int> longestDays;
  final Value<String> lastActiveOn;
  final Value<int> jamEJam;
  const StreaksCompanion({
    this.id = const Value.absent(),
    this.currentDays = const Value.absent(),
    this.longestDays = const Value.absent(),
    this.lastActiveOn = const Value.absent(),
    this.jamEJam = const Value.absent(),
  });
  StreaksCompanion.insert({
    this.id = const Value.absent(),
    this.currentDays = const Value.absent(),
    this.longestDays = const Value.absent(),
    required String lastActiveOn,
    this.jamEJam = const Value.absent(),
  }) : lastActiveOn = Value(lastActiveOn);
  static Insertable<StreakRow> custom({
    Expression<int>? id,
    Expression<int>? currentDays,
    Expression<int>? longestDays,
    Expression<String>? lastActiveOn,
    Expression<int>? jamEJam,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentDays != null) 'current_days': currentDays,
      if (longestDays != null) 'longest_days': longestDays,
      if (lastActiveOn != null) 'last_active_on': lastActiveOn,
      if (jamEJam != null) 'jam_e_jam': jamEJam,
    });
  }

  StreaksCompanion copyWith(
      {Value<int>? id,
      Value<int>? currentDays,
      Value<int>? longestDays,
      Value<String>? lastActiveOn,
      Value<int>? jamEJam}) {
    return StreaksCompanion(
      id: id ?? this.id,
      currentDays: currentDays ?? this.currentDays,
      longestDays: longestDays ?? this.longestDays,
      lastActiveOn: lastActiveOn ?? this.lastActiveOn,
      jamEJam: jamEJam ?? this.jamEJam,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentDays.present) {
      map['current_days'] = Variable<int>(currentDays.value);
    }
    if (longestDays.present) {
      map['longest_days'] = Variable<int>(longestDays.value);
    }
    if (lastActiveOn.present) {
      map['last_active_on'] = Variable<String>(lastActiveOn.value);
    }
    if (jamEJam.present) {
      map['jam_e_jam'] = Variable<int>(jamEJam.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreaksCompanion(')
          ..write('id: $id, ')
          ..write('currentDays: $currentDays, ')
          ..write('longestDays: $longestDays, ')
          ..write('lastActiveOn: $lastActiveOn, ')
          ..write('jamEJam: $jamEJam')
          ..write(')'))
        .toString();
  }
}

class $WalletsTable extends Wallets with TableInfo<$WalletsTable, WalletRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _farrMeta = const VerificationMeta('farr');
  @override
  late final GeneratedColumn<int> farr = GeneratedColumn<int>(
      'farr', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _goharMeta = const VerificationMeta('gohar');
  @override
  late final GeneratedColumn<int> gohar = GeneratedColumn<int>(
      'gohar', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, farr, gohar];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(Insertable<WalletRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('farr')) {
      context.handle(
          _farrMeta, farr.isAcceptableOrUnknown(data['farr']!, _farrMeta));
    }
    if (data.containsKey('gohar')) {
      context.handle(
          _goharMeta, gohar.isAcceptableOrUnknown(data['gohar']!, _goharMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalletRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalletRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      farr: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}farr'])!,
      gohar: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gohar'])!,
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }
}

class WalletRow extends DataClass implements Insertable<WalletRow> {
  final int id;
  final int farr;
  final int gohar;
  const WalletRow({required this.id, required this.farr, required this.gohar});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['farr'] = Variable<int>(farr);
    map['gohar'] = Variable<int>(gohar);
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      id: Value(id),
      farr: Value(farr),
      gohar: Value(gohar),
    );
  }

  factory WalletRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalletRow(
      id: serializer.fromJson<int>(json['id']),
      farr: serializer.fromJson<int>(json['farr']),
      gohar: serializer.fromJson<int>(json['gohar']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'farr': serializer.toJson<int>(farr),
      'gohar': serializer.toJson<int>(gohar),
    };
  }

  WalletRow copyWith({int? id, int? farr, int? gohar}) => WalletRow(
        id: id ?? this.id,
        farr: farr ?? this.farr,
        gohar: gohar ?? this.gohar,
      );
  WalletRow copyWithCompanion(WalletsCompanion data) {
    return WalletRow(
      id: data.id.present ? data.id.value : this.id,
      farr: data.farr.present ? data.farr.value : this.farr,
      gohar: data.gohar.present ? data.gohar.value : this.gohar,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalletRow(')
          ..write('id: $id, ')
          ..write('farr: $farr, ')
          ..write('gohar: $gohar')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, farr, gohar);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletRow &&
          other.id == this.id &&
          other.farr == this.farr &&
          other.gohar == this.gohar);
}

class WalletsCompanion extends UpdateCompanion<WalletRow> {
  final Value<int> id;
  final Value<int> farr;
  final Value<int> gohar;
  const WalletsCompanion({
    this.id = const Value.absent(),
    this.farr = const Value.absent(),
    this.gohar = const Value.absent(),
  });
  WalletsCompanion.insert({
    this.id = const Value.absent(),
    this.farr = const Value.absent(),
    this.gohar = const Value.absent(),
  });
  static Insertable<WalletRow> custom({
    Expression<int>? id,
    Expression<int>? farr,
    Expression<int>? gohar,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (farr != null) 'farr': farr,
      if (gohar != null) 'gohar': gohar,
    });
  }

  WalletsCompanion copyWith(
      {Value<int>? id, Value<int>? farr, Value<int>? gohar}) {
    return WalletsCompanion(
      id: id ?? this.id,
      farr: farr ?? this.farr,
      gohar: gohar ?? this.gohar,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (farr.present) {
      map['farr'] = Variable<int>(farr.value);
    }
    if (gohar.present) {
      map['gohar'] = Variable<int>(gohar.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('id: $id, ')
          ..write('farr: $farr, ')
          ..write('gohar: $gohar')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) => SettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SarehDatabase extends GeneratedDatabase {
  _$SarehDatabase(QueryExecutor e) : super(e);
  $SarehDatabaseManager get managers => $SarehDatabaseManager(this);
  late final $WordStatesTable wordStates = $WordStatesTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $StationProgressesTable stationProgresses =
      $StationProgressesTable(this);
  late final $StreaksTable streaks = $StreaksTable(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [wordStates, reviewLogs, stationProgresses, streaks, wallets, settings];
}

typedef $$WordStatesTableCreateCompanionBuilder = WordStatesCompanion Function({
  required String wordId,
  required double stability,
  required double difficulty,
  required int dueAt,
  required int lastReviewAt,
  Value<int> reps,
  Value<int> lapses,
  Value<int> rowid,
});
typedef $$WordStatesTableUpdateCompanionBuilder = WordStatesCompanion Function({
  Value<String> wordId,
  Value<double> stability,
  Value<double> difficulty,
  Value<int> dueAt,
  Value<int> lastReviewAt,
  Value<int> reps,
  Value<int> lapses,
  Value<int> rowid,
});

final class $$WordStatesTableReferences
    extends BaseReferences<_$SarehDatabase, $WordStatesTable, WordStateRow> {
  $$WordStatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLogRow>>
      _reviewLogsRefsTable(_$SarehDatabase db) =>
          MultiTypedResultKey.fromTable(db.reviewLogs,
              aliasName: 'word_states__word_id__review_logs__word_id');

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager($_db, $_db.reviewLogs).filter(
        (f) => f.wordId.wordId.sqlEquals($_itemColumn<String>('word_id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WordStatesTableFilterComposer
    extends Composer<_$SarehDatabase, $WordStatesTable> {
  $$WordStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueAt => $composableBuilder(
      column: $table.dueAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastReviewAt => $composableBuilder(
      column: $table.lastReviewAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnFilters(column));

  Expression<bool> reviewLogsRefs(
      Expression<bool> Function($$ReviewLogsTableFilterComposer f) f) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.reviewLogs,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogsTableFilterComposer(
              $db: $db,
              $table: $db.reviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WordStatesTableOrderingComposer
    extends Composer<_$SarehDatabase, $WordStatesTable> {
  $$WordStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordId => $composableBuilder(
      column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueAt => $composableBuilder(
      column: $table.dueAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastReviewAt => $composableBuilder(
      column: $table.lastReviewAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnOrderings(column));
}

class $$WordStatesTableAnnotationComposer
    extends Composer<_$SarehDatabase, $WordStatesTable> {
  $$WordStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get lastReviewAt => $composableBuilder(
      column: $table.lastReviewAt, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  Expression<T> reviewLogsRefs<T extends Object>(
      Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.reviewLogs,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.reviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WordStatesTableTableManager extends RootTableManager<
    _$SarehDatabase,
    $WordStatesTable,
    WordStateRow,
    $$WordStatesTableFilterComposer,
    $$WordStatesTableOrderingComposer,
    $$WordStatesTableAnnotationComposer,
    $$WordStatesTableCreateCompanionBuilder,
    $$WordStatesTableUpdateCompanionBuilder,
    (WordStateRow, $$WordStatesTableReferences),
    WordStateRow,
    PrefetchHooks Function({bool reviewLogsRefs})> {
  $$WordStatesTableTableManager(_$SarehDatabase db, $WordStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> wordId = const Value.absent(),
            Value<double> stability = const Value.absent(),
            Value<double> difficulty = const Value.absent(),
            Value<int> dueAt = const Value.absent(),
            Value<int> lastReviewAt = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WordStatesCompanion(
            wordId: wordId,
            stability: stability,
            difficulty: difficulty,
            dueAt: dueAt,
            lastReviewAt: lastReviewAt,
            reps: reps,
            lapses: lapses,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String wordId,
            required double stability,
            required double difficulty,
            required int dueAt,
            required int lastReviewAt,
            Value<int> reps = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WordStatesCompanion.insert(
            wordId: wordId,
            stability: stability,
            difficulty: difficulty,
            dueAt: dueAt,
            lastReviewAt: lastReviewAt,
            reps: reps,
            lapses: lapses,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WordStatesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({reviewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (reviewLogsRefs) db.reviewLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reviewLogsRefs)
                    await $_getPrefetchedData<WordStateRow, $WordStatesTable,
                            ReviewLogRow>(
                        currentTable: table,
                        referencedTable: $$WordStatesTableReferences
                            ._reviewLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WordStatesTableReferences(db, table, p0)
                                .reviewLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.wordId == item.wordId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WordStatesTableProcessedTableManager = ProcessedTableManager<
    _$SarehDatabase,
    $WordStatesTable,
    WordStateRow,
    $$WordStatesTableFilterComposer,
    $$WordStatesTableOrderingComposer,
    $$WordStatesTableAnnotationComposer,
    $$WordStatesTableCreateCompanionBuilder,
    $$WordStatesTableUpdateCompanionBuilder,
    (WordStateRow, $$WordStatesTableReferences),
    WordStateRow,
    PrefetchHooks Function({bool reviewLogsRefs})>;
typedef $$ReviewLogsTableCreateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  required String wordId,
  required int reviewedAt,
  required int rating,
  required double elapsedDays,
  required int answerMs,
  required String exercise,
});
typedef $$ReviewLogsTableUpdateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  Value<String> wordId,
  Value<int> reviewedAt,
  Value<int> rating,
  Value<double> elapsedDays,
  Value<int> answerMs,
  Value<String> exercise,
});

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$SarehDatabase, $ReviewLogsTable, ReviewLogRow> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordStatesTable _wordIdTable(_$SarehDatabase db) =>
      db.wordStates.createAlias('review_logs__word_id__word_states__word_id');

  $$WordStatesTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<String>('word_id')!;

    final manager = $$WordStatesTableTableManager($_db, $_db.wordStates)
        .filter((f) => f.wordId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$SarehDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elapsedDays => $composableBuilder(
      column: $table.elapsedDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get answerMs => $composableBuilder(
      column: $table.answerMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exercise => $composableBuilder(
      column: $table.exercise, builder: (column) => ColumnFilters(column));

  $$WordStatesTableFilterComposer get wordId {
    final $$WordStatesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.wordStates,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordStatesTableFilterComposer(
              $db: $db,
              $table: $db.wordStates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$SarehDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elapsedDays => $composableBuilder(
      column: $table.elapsedDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get answerMs => $composableBuilder(
      column: $table.answerMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exercise => $composableBuilder(
      column: $table.exercise, builder: (column) => ColumnOrderings(column));

  $$WordStatesTableOrderingComposer get wordId {
    final $$WordStatesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.wordStates,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordStatesTableOrderingComposer(
              $db: $db,
              $table: $db.wordStates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$SarehDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<double> get elapsedDays => $composableBuilder(
      column: $table.elapsedDays, builder: (column) => column);

  GeneratedColumn<int> get answerMs =>
      $composableBuilder(column: $table.answerMs, builder: (column) => column);

  GeneratedColumn<String> get exercise =>
      $composableBuilder(column: $table.exercise, builder: (column) => column);

  $$WordStatesTableAnnotationComposer get wordId {
    final $$WordStatesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.wordStates,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordStatesTableAnnotationComposer(
              $db: $db,
              $table: $db.wordStates,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableTableManager extends RootTableManager<
    _$SarehDatabase,
    $ReviewLogsTable,
    ReviewLogRow,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLogRow, $$ReviewLogsTableReferences),
    ReviewLogRow,
    PrefetchHooks Function({bool wordId})> {
  $$ReviewLogsTableTableManager(_$SarehDatabase db, $ReviewLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> wordId = const Value.absent(),
            Value<int> reviewedAt = const Value.absent(),
            Value<int> rating = const Value.absent(),
            Value<double> elapsedDays = const Value.absent(),
            Value<int> answerMs = const Value.absent(),
            Value<String> exercise = const Value.absent(),
          }) =>
              ReviewLogsCompanion(
            id: id,
            wordId: wordId,
            reviewedAt: reviewedAt,
            rating: rating,
            elapsedDays: elapsedDays,
            answerMs: answerMs,
            exercise: exercise,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String wordId,
            required int reviewedAt,
            required int rating,
            required double elapsedDays,
            required int answerMs,
            required String exercise,
          }) =>
              ReviewLogsCompanion.insert(
            id: id,
            wordId: wordId,
            reviewedAt: reviewedAt,
            rating: rating,
            elapsedDays: elapsedDays,
            answerMs: answerMs,
            exercise: exercise,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReviewLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (wordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.wordId,
                    referencedTable:
                        $$ReviewLogsTableReferences._wordIdTable(db),
                    referencedColumn:
                        $$ReviewLogsTableReferences._wordIdTable(db).wordId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReviewLogsTableProcessedTableManager = ProcessedTableManager<
    _$SarehDatabase,
    $ReviewLogsTable,
    ReviewLogRow,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLogRow, $$ReviewLogsTableReferences),
    ReviewLogRow,
    PrefetchHooks Function({bool wordId})>;
typedef $$StationProgressesTableCreateCompanionBuilder
    = StationProgressesCompanion Function({
  required String stationId,
  Value<int?> completedAt,
  Value<double> bestRatio,
  Value<int> rowid,
});
typedef $$StationProgressesTableUpdateCompanionBuilder
    = StationProgressesCompanion Function({
  Value<String> stationId,
  Value<int?> completedAt,
  Value<double> bestRatio,
  Value<int> rowid,
});

class $$StationProgressesTableFilterComposer
    extends Composer<_$SarehDatabase, $StationProgressesTable> {
  $$StationProgressesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get stationId => $composableBuilder(
      column: $table.stationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bestRatio => $composableBuilder(
      column: $table.bestRatio, builder: (column) => ColumnFilters(column));
}

class $$StationProgressesTableOrderingComposer
    extends Composer<_$SarehDatabase, $StationProgressesTable> {
  $$StationProgressesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get stationId => $composableBuilder(
      column: $table.stationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bestRatio => $composableBuilder(
      column: $table.bestRatio, builder: (column) => ColumnOrderings(column));
}

class $$StationProgressesTableAnnotationComposer
    extends Composer<_$SarehDatabase, $StationProgressesTable> {
  $$StationProgressesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get stationId =>
      $composableBuilder(column: $table.stationId, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<double> get bestRatio =>
      $composableBuilder(column: $table.bestRatio, builder: (column) => column);
}

class $$StationProgressesTableTableManager extends RootTableManager<
    _$SarehDatabase,
    $StationProgressesTable,
    StationProgressRow,
    $$StationProgressesTableFilterComposer,
    $$StationProgressesTableOrderingComposer,
    $$StationProgressesTableAnnotationComposer,
    $$StationProgressesTableCreateCompanionBuilder,
    $$StationProgressesTableUpdateCompanionBuilder,
    (
      StationProgressRow,
      BaseReferences<_$SarehDatabase, $StationProgressesTable,
          StationProgressRow>
    ),
    StationProgressRow,
    PrefetchHooks Function()> {
  $$StationProgressesTableTableManager(
      _$SarehDatabase db, $StationProgressesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StationProgressesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StationProgressesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StationProgressesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> stationId = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
            Value<double> bestRatio = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StationProgressesCompanion(
            stationId: stationId,
            completedAt: completedAt,
            bestRatio: bestRatio,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String stationId,
            Value<int?> completedAt = const Value.absent(),
            Value<double> bestRatio = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StationProgressesCompanion.insert(
            stationId: stationId,
            completedAt: completedAt,
            bestRatio: bestRatio,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StationProgressesTableProcessedTableManager = ProcessedTableManager<
    _$SarehDatabase,
    $StationProgressesTable,
    StationProgressRow,
    $$StationProgressesTableFilterComposer,
    $$StationProgressesTableOrderingComposer,
    $$StationProgressesTableAnnotationComposer,
    $$StationProgressesTableCreateCompanionBuilder,
    $$StationProgressesTableUpdateCompanionBuilder,
    (
      StationProgressRow,
      BaseReferences<_$SarehDatabase, $StationProgressesTable,
          StationProgressRow>
    ),
    StationProgressRow,
    PrefetchHooks Function()>;
typedef $$StreaksTableCreateCompanionBuilder = StreaksCompanion Function({
  Value<int> id,
  Value<int> currentDays,
  Value<int> longestDays,
  required String lastActiveOn,
  Value<int> jamEJam,
});
typedef $$StreaksTableUpdateCompanionBuilder = StreaksCompanion Function({
  Value<int> id,
  Value<int> currentDays,
  Value<int> longestDays,
  Value<String> lastActiveOn,
  Value<int> jamEJam,
});

class $$StreaksTableFilterComposer
    extends Composer<_$SarehDatabase, $StreaksTable> {
  $$StreaksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentDays => $composableBuilder(
      column: $table.currentDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get longestDays => $composableBuilder(
      column: $table.longestDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastActiveOn => $composableBuilder(
      column: $table.lastActiveOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get jamEJam => $composableBuilder(
      column: $table.jamEJam, builder: (column) => ColumnFilters(column));
}

class $$StreaksTableOrderingComposer
    extends Composer<_$SarehDatabase, $StreaksTable> {
  $$StreaksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentDays => $composableBuilder(
      column: $table.currentDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get longestDays => $composableBuilder(
      column: $table.longestDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastActiveOn => $composableBuilder(
      column: $table.lastActiveOn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get jamEJam => $composableBuilder(
      column: $table.jamEJam, builder: (column) => ColumnOrderings(column));
}

class $$StreaksTableAnnotationComposer
    extends Composer<_$SarehDatabase, $StreaksTable> {
  $$StreaksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get currentDays => $composableBuilder(
      column: $table.currentDays, builder: (column) => column);

  GeneratedColumn<int> get longestDays => $composableBuilder(
      column: $table.longestDays, builder: (column) => column);

  GeneratedColumn<String> get lastActiveOn => $composableBuilder(
      column: $table.lastActiveOn, builder: (column) => column);

  GeneratedColumn<int> get jamEJam =>
      $composableBuilder(column: $table.jamEJam, builder: (column) => column);
}

class $$StreaksTableTableManager extends RootTableManager<
    _$SarehDatabase,
    $StreaksTable,
    StreakRow,
    $$StreaksTableFilterComposer,
    $$StreaksTableOrderingComposer,
    $$StreaksTableAnnotationComposer,
    $$StreaksTableCreateCompanionBuilder,
    $$StreaksTableUpdateCompanionBuilder,
    (StreakRow, BaseReferences<_$SarehDatabase, $StreaksTable, StreakRow>),
    StreakRow,
    PrefetchHooks Function()> {
  $$StreaksTableTableManager(_$SarehDatabase db, $StreaksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreaksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreaksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreaksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> currentDays = const Value.absent(),
            Value<int> longestDays = const Value.absent(),
            Value<String> lastActiveOn = const Value.absent(),
            Value<int> jamEJam = const Value.absent(),
          }) =>
              StreaksCompanion(
            id: id,
            currentDays: currentDays,
            longestDays: longestDays,
            lastActiveOn: lastActiveOn,
            jamEJam: jamEJam,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> currentDays = const Value.absent(),
            Value<int> longestDays = const Value.absent(),
            required String lastActiveOn,
            Value<int> jamEJam = const Value.absent(),
          }) =>
              StreaksCompanion.insert(
            id: id,
            currentDays: currentDays,
            longestDays: longestDays,
            lastActiveOn: lastActiveOn,
            jamEJam: jamEJam,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StreaksTableProcessedTableManager = ProcessedTableManager<
    _$SarehDatabase,
    $StreaksTable,
    StreakRow,
    $$StreaksTableFilterComposer,
    $$StreaksTableOrderingComposer,
    $$StreaksTableAnnotationComposer,
    $$StreaksTableCreateCompanionBuilder,
    $$StreaksTableUpdateCompanionBuilder,
    (StreakRow, BaseReferences<_$SarehDatabase, $StreaksTable, StreakRow>),
    StreakRow,
    PrefetchHooks Function()>;
typedef $$WalletsTableCreateCompanionBuilder = WalletsCompanion Function({
  Value<int> id,
  Value<int> farr,
  Value<int> gohar,
});
typedef $$WalletsTableUpdateCompanionBuilder = WalletsCompanion Function({
  Value<int> id,
  Value<int> farr,
  Value<int> gohar,
});

class $$WalletsTableFilterComposer
    extends Composer<_$SarehDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get farr => $composableBuilder(
      column: $table.farr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gohar => $composableBuilder(
      column: $table.gohar, builder: (column) => ColumnFilters(column));
}

class $$WalletsTableOrderingComposer
    extends Composer<_$SarehDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get farr => $composableBuilder(
      column: $table.farr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gohar => $composableBuilder(
      column: $table.gohar, builder: (column) => ColumnOrderings(column));
}

class $$WalletsTableAnnotationComposer
    extends Composer<_$SarehDatabase, $WalletsTable> {
  $$WalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get farr =>
      $composableBuilder(column: $table.farr, builder: (column) => column);

  GeneratedColumn<int> get gohar =>
      $composableBuilder(column: $table.gohar, builder: (column) => column);
}

class $$WalletsTableTableManager extends RootTableManager<
    _$SarehDatabase,
    $WalletsTable,
    WalletRow,
    $$WalletsTableFilterComposer,
    $$WalletsTableOrderingComposer,
    $$WalletsTableAnnotationComposer,
    $$WalletsTableCreateCompanionBuilder,
    $$WalletsTableUpdateCompanionBuilder,
    (WalletRow, BaseReferences<_$SarehDatabase, $WalletsTable, WalletRow>),
    WalletRow,
    PrefetchHooks Function()> {
  $$WalletsTableTableManager(_$SarehDatabase db, $WalletsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> farr = const Value.absent(),
            Value<int> gohar = const Value.absent(),
          }) =>
              WalletsCompanion(
            id: id,
            farr: farr,
            gohar: gohar,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> farr = const Value.absent(),
            Value<int> gohar = const Value.absent(),
          }) =>
              WalletsCompanion.insert(
            id: id,
            farr: farr,
            gohar: gohar,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WalletsTableProcessedTableManager = ProcessedTableManager<
    _$SarehDatabase,
    $WalletsTable,
    WalletRow,
    $$WalletsTableFilterComposer,
    $$WalletsTableOrderingComposer,
    $$WalletsTableAnnotationComposer,
    $$WalletsTableCreateCompanionBuilder,
    $$WalletsTableUpdateCompanionBuilder,
    (WalletRow, BaseReferences<_$SarehDatabase, $WalletsTable, WalletRow>),
    WalletRow,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$SarehDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$SarehDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$SarehDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$SarehDatabase,
    $SettingsTable,
    SettingRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$SarehDatabase, $SettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$SarehDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$SarehDatabase,
    $SettingsTable,
    SettingRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$SarehDatabase, $SettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()>;

class $SarehDatabaseManager {
  final _$SarehDatabase _db;
  $SarehDatabaseManager(this._db);
  $$WordStatesTableTableManager get wordStates =>
      $$WordStatesTableTableManager(_db, _db.wordStates);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$StationProgressesTableTableManager get stationProgresses =>
      $$StationProgressesTableTableManager(_db, _db.stationProgresses);
  $$StreaksTableTableManager get streaks =>
      $$StreaksTableTableManager(_db, _db.streaks);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
