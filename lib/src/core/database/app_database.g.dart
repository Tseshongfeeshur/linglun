// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LibraryTracksTable extends LibraryTracks
    with TableInfo<$LibraryTracksTable, LibraryTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverBytesMeta = const VerificationMeta(
    'coverBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> coverBytes = GeneratedColumn<Uint8List>(
    'cover_bytes',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
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
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverColorMeta = const VerificationMeta(
    'coverColor',
  );
  @override
  late final GeneratedColumn<int> coverColor = GeneratedColumn<int>(
    'cover_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lyricsMeta = const VerificationMeta('lyrics');
  @override
  late final GeneratedColumn<String> lyrics = GeneratedColumn<String>(
    'lyrics',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lyricsFormatMeta = const VerificationMeta(
    'lyricsFormat',
  );
  @override
  late final GeneratedColumn<String> lyricsFormat = GeneratedColumn<String>(
    'lyrics_format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lyricsSourcesJsonMeta = const VerificationMeta(
    'lyricsSourcesJson',
  );
  @override
  late final GeneratedColumn<String> lyricsSourcesJson =
      GeneratedColumn<String>(
        'lyrics_sources_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replayGainDbMeta = const VerificationMeta(
    'replayGainDb',
  );
  @override
  late final GeneratedColumn<double> replayGainDb = GeneratedColumn<double>(
    'replay_gain_db',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replayGainModeMeta = const VerificationMeta(
    'replayGainMode',
  );
  @override
  late final GeneratedColumn<String> replayGainMode = GeneratedColumn<String>(
    'replay_gain_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    filePath,
    coverBytes,
    title,
    artist,
    album,
    durationMs,
    coverColor,
    lyrics,
    lyricsFormat,
    lyricsSourcesJson,
    metadataJson,
    replayGainDb,
    replayGainMode,
    playCount,
    lastPlayedAt,
    addedAt,
    modifiedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('cover_bytes')) {
      context.handle(
        _coverBytesMeta,
        coverBytes.isAcceptableOrUnknown(data['cover_bytes']!, _coverBytesMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    } else if (isInserting) {
      context.missing(_albumMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('cover_color')) {
      context.handle(
        _coverColorMeta,
        coverColor.isAcceptableOrUnknown(data['cover_color']!, _coverColorMeta),
      );
    } else if (isInserting) {
      context.missing(_coverColorMeta);
    }
    if (data.containsKey('lyrics')) {
      context.handle(
        _lyricsMeta,
        lyrics.isAcceptableOrUnknown(data['lyrics']!, _lyricsMeta),
      );
    }
    if (data.containsKey('lyrics_format')) {
      context.handle(
        _lyricsFormatMeta,
        lyricsFormat.isAcceptableOrUnknown(
          data['lyrics_format']!,
          _lyricsFormatMeta,
        ),
      );
    }
    if (data.containsKey('lyrics_sources_json')) {
      context.handle(
        _lyricsSourcesJsonMeta,
        lyricsSourcesJson.isAcceptableOrUnknown(
          data['lyrics_sources_json']!,
          _lyricsSourcesJsonMeta,
        ),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('replay_gain_db')) {
      context.handle(
        _replayGainDbMeta,
        replayGainDb.isAcceptableOrUnknown(
          data['replay_gain_db']!,
          _replayGainDbMeta,
        ),
      );
    }
    if (data.containsKey('replay_gain_mode')) {
      context.handle(
        _replayGainModeMeta,
        replayGainMode.isAcceptableOrUnknown(
          data['replay_gain_mode']!,
          _replayGainModeMeta,
        ),
      );
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
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
  LibraryTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryTrack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      coverBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}cover_bytes'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      coverColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_color'],
      )!,
      lyrics: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lyrics'],
      ),
      lyricsFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lyrics_format'],
      ),
      lyricsSourcesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lyrics_sources_json'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
      replayGainDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}replay_gain_db'],
      ),
      replayGainMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replay_gain_mode'],
      ),
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LibraryTracksTable createAlias(String alias) {
    return $LibraryTracksTable(attachedDatabase, alias);
  }
}

class LibraryTrack extends DataClass implements Insertable<LibraryTrack> {
  final String id;
  final String filePath;
  final Uint8List? coverBytes;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final int coverColor;
  final String? lyrics;
  final String? lyricsFormat;
  final String? lyricsSourcesJson;
  final String? metadataJson;
  final double? replayGainDb;
  final String? replayGainMode;
  final int playCount;
  final DateTime? lastPlayedAt;
  final DateTime? addedAt;
  final DateTime? modifiedAt;
  final DateTime updatedAt;
  const LibraryTrack({
    required this.id,
    required this.filePath,
    this.coverBytes,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.coverColor,
    this.lyrics,
    this.lyricsFormat,
    this.lyricsSourcesJson,
    this.metadataJson,
    this.replayGainDb,
    this.replayGainMode,
    required this.playCount,
    this.lastPlayedAt,
    this.addedAt,
    this.modifiedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || coverBytes != null) {
      map['cover_bytes'] = Variable<Uint8List>(coverBytes);
    }
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['album'] = Variable<String>(album);
    map['duration_ms'] = Variable<int>(durationMs);
    map['cover_color'] = Variable<int>(coverColor);
    if (!nullToAbsent || lyrics != null) {
      map['lyrics'] = Variable<String>(lyrics);
    }
    if (!nullToAbsent || lyricsFormat != null) {
      map['lyrics_format'] = Variable<String>(lyricsFormat);
    }
    if (!nullToAbsent || lyricsSourcesJson != null) {
      map['lyrics_sources_json'] = Variable<String>(lyricsSourcesJson);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    if (!nullToAbsent || replayGainDb != null) {
      map['replay_gain_db'] = Variable<double>(replayGainDb);
    }
    if (!nullToAbsent || replayGainMode != null) {
      map['replay_gain_mode'] = Variable<String>(replayGainMode);
    }
    map['play_count'] = Variable<int>(playCount);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    if (!nullToAbsent || addedAt != null) {
      map['added_at'] = Variable<DateTime>(addedAt);
    }
    if (!nullToAbsent || modifiedAt != null) {
      map['modified_at'] = Variable<DateTime>(modifiedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LibraryTracksCompanion toCompanion(bool nullToAbsent) {
    return LibraryTracksCompanion(
      id: Value(id),
      filePath: Value(filePath),
      coverBytes: coverBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(coverBytes),
      title: Value(title),
      artist: Value(artist),
      album: Value(album),
      durationMs: Value(durationMs),
      coverColor: Value(coverColor),
      lyrics: lyrics == null && nullToAbsent
          ? const Value.absent()
          : Value(lyrics),
      lyricsFormat: lyricsFormat == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricsFormat),
      lyricsSourcesJson: lyricsSourcesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(lyricsSourcesJson),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      replayGainDb: replayGainDb == null && nullToAbsent
          ? const Value.absent()
          : Value(replayGainDb),
      replayGainMode: replayGainMode == null && nullToAbsent
          ? const Value.absent()
          : Value(replayGainMode),
      playCount: Value(playCount),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      addedAt: addedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addedAt),
      modifiedAt: modifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LibraryTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryTrack(
      id: serializer.fromJson<String>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      coverBytes: serializer.fromJson<Uint8List?>(json['coverBytes']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String>(json['album']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      coverColor: serializer.fromJson<int>(json['coverColor']),
      lyrics: serializer.fromJson<String?>(json['lyrics']),
      lyricsFormat: serializer.fromJson<String?>(json['lyricsFormat']),
      lyricsSourcesJson: serializer.fromJson<String?>(
        json['lyricsSourcesJson'],
      ),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      replayGainDb: serializer.fromJson<double?>(json['replayGainDb']),
      replayGainMode: serializer.fromJson<String?>(json['replayGainMode']),
      playCount: serializer.fromJson<int>(json['playCount']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      addedAt: serializer.fromJson<DateTime?>(json['addedAt']),
      modifiedAt: serializer.fromJson<DateTime?>(json['modifiedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'filePath': serializer.toJson<String>(filePath),
      'coverBytes': serializer.toJson<Uint8List?>(coverBytes),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String>(album),
      'durationMs': serializer.toJson<int>(durationMs),
      'coverColor': serializer.toJson<int>(coverColor),
      'lyrics': serializer.toJson<String?>(lyrics),
      'lyricsFormat': serializer.toJson<String?>(lyricsFormat),
      'lyricsSourcesJson': serializer.toJson<String?>(lyricsSourcesJson),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'replayGainDb': serializer.toJson<double?>(replayGainDb),
      'replayGainMode': serializer.toJson<String?>(replayGainMode),
      'playCount': serializer.toJson<int>(playCount),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'addedAt': serializer.toJson<DateTime?>(addedAt),
      'modifiedAt': serializer.toJson<DateTime?>(modifiedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LibraryTrack copyWith({
    String? id,
    String? filePath,
    Value<Uint8List?> coverBytes = const Value.absent(),
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    int? coverColor,
    Value<String?> lyrics = const Value.absent(),
    Value<String?> lyricsFormat = const Value.absent(),
    Value<String?> lyricsSourcesJson = const Value.absent(),
    Value<String?> metadataJson = const Value.absent(),
    Value<double?> replayGainDb = const Value.absent(),
    Value<String?> replayGainMode = const Value.absent(),
    int? playCount,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    Value<DateTime?> addedAt = const Value.absent(),
    Value<DateTime?> modifiedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => LibraryTrack(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    coverBytes: coverBytes.present ? coverBytes.value : this.coverBytes,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    durationMs: durationMs ?? this.durationMs,
    coverColor: coverColor ?? this.coverColor,
    lyrics: lyrics.present ? lyrics.value : this.lyrics,
    lyricsFormat: lyricsFormat.present ? lyricsFormat.value : this.lyricsFormat,
    lyricsSourcesJson: lyricsSourcesJson.present
        ? lyricsSourcesJson.value
        : this.lyricsSourcesJson,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
    replayGainDb: replayGainDb.present ? replayGainDb.value : this.replayGainDb,
    replayGainMode: replayGainMode.present
        ? replayGainMode.value
        : this.replayGainMode,
    playCount: playCount ?? this.playCount,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    addedAt: addedAt.present ? addedAt.value : this.addedAt,
    modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LibraryTrack copyWithCompanion(LibraryTracksCompanion data) {
    return LibraryTrack(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      coverBytes: data.coverBytes.present
          ? data.coverBytes.value
          : this.coverBytes,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      coverColor: data.coverColor.present
          ? data.coverColor.value
          : this.coverColor,
      lyrics: data.lyrics.present ? data.lyrics.value : this.lyrics,
      lyricsFormat: data.lyricsFormat.present
          ? data.lyricsFormat.value
          : this.lyricsFormat,
      lyricsSourcesJson: data.lyricsSourcesJson.present
          ? data.lyricsSourcesJson.value
          : this.lyricsSourcesJson,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      replayGainDb: data.replayGainDb.present
          ? data.replayGainDb.value
          : this.replayGainDb,
      replayGainMode: data.replayGainMode.present
          ? data.replayGainMode.value
          : this.replayGainMode,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryTrack(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('coverBytes: $coverBytes, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('coverColor: $coverColor, ')
          ..write('lyrics: $lyrics, ')
          ..write('lyricsFormat: $lyricsFormat, ')
          ..write('lyricsSourcesJson: $lyricsSourcesJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('replayGainDb: $replayGainDb, ')
          ..write('replayGainMode: $replayGainMode, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('addedAt: $addedAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    $driftBlobEquality.hash(coverBytes),
    title,
    artist,
    album,
    durationMs,
    coverColor,
    lyrics,
    lyricsFormat,
    lyricsSourcesJson,
    metadataJson,
    replayGainDb,
    replayGainMode,
    playCount,
    lastPlayedAt,
    addedAt,
    modifiedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryTrack &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          $driftBlobEquality.equals(other.coverBytes, this.coverBytes) &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.durationMs == this.durationMs &&
          other.coverColor == this.coverColor &&
          other.lyrics == this.lyrics &&
          other.lyricsFormat == this.lyricsFormat &&
          other.lyricsSourcesJson == this.lyricsSourcesJson &&
          other.metadataJson == this.metadataJson &&
          other.replayGainDb == this.replayGainDb &&
          other.replayGainMode == this.replayGainMode &&
          other.playCount == this.playCount &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.addedAt == this.addedAt &&
          other.modifiedAt == this.modifiedAt &&
          other.updatedAt == this.updatedAt);
}

class LibraryTracksCompanion extends UpdateCompanion<LibraryTrack> {
  final Value<String> id;
  final Value<String> filePath;
  final Value<Uint8List?> coverBytes;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> album;
  final Value<int> durationMs;
  final Value<int> coverColor;
  final Value<String?> lyrics;
  final Value<String?> lyricsFormat;
  final Value<String?> lyricsSourcesJson;
  final Value<String?> metadataJson;
  final Value<double?> replayGainDb;
  final Value<String?> replayGainMode;
  final Value<int> playCount;
  final Value<DateTime?> lastPlayedAt;
  final Value<DateTime?> addedAt;
  final Value<DateTime?> modifiedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LibraryTracksCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.coverBytes = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.lyricsFormat = const Value.absent(),
    this.lyricsSourcesJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.replayGainDb = const Value.absent(),
    this.replayGainMode = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryTracksCompanion.insert({
    required String id,
    required String filePath,
    this.coverBytes = const Value.absent(),
    required String title,
    required String artist,
    required String album,
    required int durationMs,
    required int coverColor,
    this.lyrics = const Value.absent(),
    this.lyricsFormat = const Value.absent(),
    this.lyricsSourcesJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.replayGainDb = const Value.absent(),
    this.replayGainMode = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       filePath = Value(filePath),
       title = Value(title),
       artist = Value(artist),
       album = Value(album),
       durationMs = Value(durationMs),
       coverColor = Value(coverColor),
       updatedAt = Value(updatedAt);
  static Insertable<LibraryTrack> custom({
    Expression<String>? id,
    Expression<String>? filePath,
    Expression<Uint8List>? coverBytes,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<int>? durationMs,
    Expression<int>? coverColor,
    Expression<String>? lyrics,
    Expression<String>? lyricsFormat,
    Expression<String>? lyricsSourcesJson,
    Expression<String>? metadataJson,
    Expression<double>? replayGainDb,
    Expression<String>? replayGainMode,
    Expression<int>? playCount,
    Expression<DateTime>? lastPlayedAt,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? modifiedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (coverBytes != null) 'cover_bytes': coverBytes,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (durationMs != null) 'duration_ms': durationMs,
      if (coverColor != null) 'cover_color': coverColor,
      if (lyrics != null) 'lyrics': lyrics,
      if (lyricsFormat != null) 'lyrics_format': lyricsFormat,
      if (lyricsSourcesJson != null) 'lyrics_sources_json': lyricsSourcesJson,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (replayGainDb != null) 'replay_gain_db': replayGainDb,
      if (replayGainMode != null) 'replay_gain_mode': replayGainMode,
      if (playCount != null) 'play_count': playCount,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (addedAt != null) 'added_at': addedAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryTracksCompanion copyWith({
    Value<String>? id,
    Value<String>? filePath,
    Value<Uint8List?>? coverBytes,
    Value<String>? title,
    Value<String>? artist,
    Value<String>? album,
    Value<int>? durationMs,
    Value<int>? coverColor,
    Value<String?>? lyrics,
    Value<String?>? lyricsFormat,
    Value<String?>? lyricsSourcesJson,
    Value<String?>? metadataJson,
    Value<double?>? replayGainDb,
    Value<String?>? replayGainMode,
    Value<int>? playCount,
    Value<DateTime?>? lastPlayedAt,
    Value<DateTime?>? addedAt,
    Value<DateTime?>? modifiedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LibraryTracksCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      coverBytes: coverBytes ?? this.coverBytes,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      coverColor: coverColor ?? this.coverColor,
      lyrics: lyrics ?? this.lyrics,
      lyricsFormat: lyricsFormat ?? this.lyricsFormat,
      lyricsSourcesJson: lyricsSourcesJson ?? this.lyricsSourcesJson,
      metadataJson: metadataJson ?? this.metadataJson,
      replayGainDb: replayGainDb ?? this.replayGainDb,
      replayGainMode: replayGainMode ?? this.replayGainMode,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      addedAt: addedAt ?? this.addedAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
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
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (coverBytes.present) {
      map['cover_bytes'] = Variable<Uint8List>(coverBytes.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (coverColor.present) {
      map['cover_color'] = Variable<int>(coverColor.value);
    }
    if (lyrics.present) {
      map['lyrics'] = Variable<String>(lyrics.value);
    }
    if (lyricsFormat.present) {
      map['lyrics_format'] = Variable<String>(lyricsFormat.value);
    }
    if (lyricsSourcesJson.present) {
      map['lyrics_sources_json'] = Variable<String>(lyricsSourcesJson.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (replayGainDb.present) {
      map['replay_gain_db'] = Variable<double>(replayGainDb.value);
    }
    if (replayGainMode.present) {
      map['replay_gain_mode'] = Variable<String>(replayGainMode.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
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
    return (StringBuffer('LibraryTracksCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('coverBytes: $coverBytes, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('coverColor: $coverColor, ')
          ..write('lyrics: $lyrics, ')
          ..write('lyricsFormat: $lyricsFormat, ')
          ..write('lyricsSourcesJson: $lyricsSourcesJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('replayGainDb: $replayGainDb, ')
          ..write('replayGainMode: $replayGainMode, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('addedAt: $addedAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryDirectoriesTable extends LibraryDirectories
    with TableInfo<$LibraryDirectoriesTable, LibraryDirectory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryDirectoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _directoryPathMeta = const VerificationMeta(
    'directoryPath',
  );
  @override
  late final GeneratedColumn<String> directoryPath = GeneratedColumn<String>(
    'directory_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [directoryPath, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_directories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryDirectory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('directory_path')) {
      context.handle(
        _directoryPathMeta,
        directoryPath.isAcceptableOrUnknown(
          data['directory_path']!,
          _directoryPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_directoryPathMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {directoryPath};
  @override
  LibraryDirectory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryDirectory(
      directoryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}directory_path'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $LibraryDirectoriesTable createAlias(String alias) {
    return $LibraryDirectoriesTable(attachedDatabase, alias);
  }
}

class LibraryDirectory extends DataClass
    implements Insertable<LibraryDirectory> {
  final String directoryPath;
  final DateTime addedAt;
  const LibraryDirectory({required this.directoryPath, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['directory_path'] = Variable<String>(directoryPath);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  LibraryDirectoriesCompanion toCompanion(bool nullToAbsent) {
    return LibraryDirectoriesCompanion(
      directoryPath: Value(directoryPath),
      addedAt: Value(addedAt),
    );
  }

  factory LibraryDirectory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryDirectory(
      directoryPath: serializer.fromJson<String>(json['directoryPath']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'directoryPath': serializer.toJson<String>(directoryPath),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  LibraryDirectory copyWith({String? directoryPath, DateTime? addedAt}) =>
      LibraryDirectory(
        directoryPath: directoryPath ?? this.directoryPath,
        addedAt: addedAt ?? this.addedAt,
      );
  LibraryDirectory copyWithCompanion(LibraryDirectoriesCompanion data) {
    return LibraryDirectory(
      directoryPath: data.directoryPath.present
          ? data.directoryPath.value
          : this.directoryPath,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryDirectory(')
          ..write('directoryPath: $directoryPath, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(directoryPath, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryDirectory &&
          other.directoryPath == this.directoryPath &&
          other.addedAt == this.addedAt);
}

class LibraryDirectoriesCompanion extends UpdateCompanion<LibraryDirectory> {
  final Value<String> directoryPath;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const LibraryDirectoriesCompanion({
    this.directoryPath = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryDirectoriesCompanion.insert({
    required String directoryPath,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : directoryPath = Value(directoryPath),
       addedAt = Value(addedAt);
  static Insertable<LibraryDirectory> custom({
    Expression<String>? directoryPath,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (directoryPath != null) 'directory_path': directoryPath,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryDirectoriesCompanion copyWith({
    Value<String>? directoryPath,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return LibraryDirectoriesCompanion(
      directoryPath: directoryPath ?? this.directoryPath,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (directoryPath.present) {
      map['directory_path'] = Variable<String>(directoryPath.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryDirectoriesCompanion(')
          ..write('directoryPath: $directoryPath, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackEventsTable extends PlaybackEvents
    with TableInfo<$PlaybackEventsTable, PlaybackEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, trackId, playedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $PlaybackEventsTable createAlias(String alias) {
    return $PlaybackEventsTable(attachedDatabase, alias);
  }
}

class PlaybackEvent extends DataClass implements Insertable<PlaybackEvent> {
  final int id;
  final String trackId;
  final DateTime playedAt;
  const PlaybackEvent({
    required this.id,
    required this.trackId,
    required this.playedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<String>(trackId);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  PlaybackEventsCompanion toCompanion(bool nullToAbsent) {
    return PlaybackEventsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      playedAt: Value(playedAt),
    );
  }

  factory PlaybackEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackEvent(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<String>(trackId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  PlaybackEvent copyWith({int? id, String? trackId, DateTime? playedAt}) =>
      PlaybackEvent(
        id: id ?? this.id,
        trackId: trackId ?? this.trackId,
        playedAt: playedAt ?? this.playedAt,
      );
  PlaybackEvent copyWithCompanion(PlaybackEventsCompanion data) {
    return PlaybackEvent(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackEvent(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackId, playedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackEvent &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.playedAt == this.playedAt);
}

class PlaybackEventsCompanion extends UpdateCompanion<PlaybackEvent> {
  final Value<int> id;
  final Value<String> trackId;
  final Value<DateTime> playedAt;
  const PlaybackEventsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.playedAt = const Value.absent(),
  });
  PlaybackEventsCompanion.insert({
    this.id = const Value.absent(),
    required String trackId,
    required DateTime playedAt,
  }) : trackId = Value(trackId),
       playedAt = Value(playedAt);
  static Insertable<PlaybackEvent> custom({
    Expression<int>? id,
    Expression<String>? trackId,
    Expression<DateTime>? playedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (playedAt != null) 'played_at': playedAt,
    });
  }

  PlaybackEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? trackId,
    Value<DateTime>? playedAt,
  }) {
    return PlaybackEventsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      playedAt: playedAt ?? this.playedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackEventsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
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
  List<GeneratedColumn> get $columns => [key, valueJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
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
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String valueJson;
  final DateTime updatedAt;
  const AppSetting({
    required this.key,
    required this.valueJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? valueJson, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        valueJson: valueJson ?? this.valueJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.valueJson == this.valueJson &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String valueJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LibraryTracksTable libraryTracks = $LibraryTracksTable(this);
  late final $LibraryDirectoriesTable libraryDirectories =
      $LibraryDirectoriesTable(this);
  late final $PlaybackEventsTable playbackEvents = $PlaybackEventsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    libraryTracks,
    libraryDirectories,
    playbackEvents,
    appSettings,
  ];
}

typedef $$LibraryTracksTableCreateCompanionBuilder =
    LibraryTracksCompanion Function({
      required String id,
      required String filePath,
      Value<Uint8List?> coverBytes,
      required String title,
      required String artist,
      required String album,
      required int durationMs,
      required int coverColor,
      Value<String?> lyrics,
      Value<String?> lyricsFormat,
      Value<String?> lyricsSourcesJson,
      Value<String?> metadataJson,
      Value<double?> replayGainDb,
      Value<String?> replayGainMode,
      Value<int> playCount,
      Value<DateTime?> lastPlayedAt,
      Value<DateTime?> addedAt,
      Value<DateTime?> modifiedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LibraryTracksTableUpdateCompanionBuilder =
    LibraryTracksCompanion Function({
      Value<String> id,
      Value<String> filePath,
      Value<Uint8List?> coverBytes,
      Value<String> title,
      Value<String> artist,
      Value<String> album,
      Value<int> durationMs,
      Value<int> coverColor,
      Value<String?> lyrics,
      Value<String?> lyricsFormat,
      Value<String?> lyricsSourcesJson,
      Value<String?> metadataJson,
      Value<double?> replayGainDb,
      Value<String?> replayGainMode,
      Value<int> playCount,
      Value<DateTime?> lastPlayedAt,
      Value<DateTime?> addedAt,
      Value<DateTime?> modifiedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LibraryTracksTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableFilterComposer({
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

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get coverBytes => $composableBuilder(
    column: $table.coverBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lyrics => $composableBuilder(
    column: $table.lyrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lyricsFormat => $composableBuilder(
    column: $table.lyricsFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lyricsSourcesJson => $composableBuilder(
    column: $table.lyricsSourcesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get replayGainDb => $composableBuilder(
    column: $table.replayGainDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replayGainMode => $composableBuilder(
    column: $table.replayGainMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableOrderingComposer({
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

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get coverBytes => $composableBuilder(
    column: $table.coverBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lyrics => $composableBuilder(
    column: $table.lyrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lyricsFormat => $composableBuilder(
    column: $table.lyricsFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lyricsSourcesJson => $composableBuilder(
    column: $table.lyricsSourcesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get replayGainDb => $composableBuilder(
    column: $table.replayGainDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replayGainMode => $composableBuilder(
    column: $table.replayGainMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<Uint8List> get coverBytes => $composableBuilder(
    column: $table.coverBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lyrics =>
      $composableBuilder(column: $table.lyrics, builder: (column) => column);

  GeneratedColumn<String> get lyricsFormat => $composableBuilder(
    column: $table.lyricsFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lyricsSourcesJson => $composableBuilder(
    column: $table.lyricsSourcesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get replayGainDb => $composableBuilder(
    column: $table.replayGainDb,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replayGainMode => $composableBuilder(
    column: $table.replayGainMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LibraryTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryTracksTable,
          LibraryTrack,
          $$LibraryTracksTableFilterComposer,
          $$LibraryTracksTableOrderingComposer,
          $$LibraryTracksTableAnnotationComposer,
          $$LibraryTracksTableCreateCompanionBuilder,
          $$LibraryTracksTableUpdateCompanionBuilder,
          (
            LibraryTrack,
            BaseReferences<_$AppDatabase, $LibraryTracksTable, LibraryTrack>,
          ),
          LibraryTrack,
          PrefetchHooks Function()
        > {
  $$LibraryTracksTableTableManager(_$AppDatabase db, $LibraryTracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<Uint8List?> coverBytes = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> album = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> coverColor = const Value.absent(),
                Value<String?> lyrics = const Value.absent(),
                Value<String?> lyricsFormat = const Value.absent(),
                Value<String?> lyricsSourcesJson = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<double?> replayGainDb = const Value.absent(),
                Value<String?> replayGainMode = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<DateTime?> addedAt = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryTracksCompanion(
                id: id,
                filePath: filePath,
                coverBytes: coverBytes,
                title: title,
                artist: artist,
                album: album,
                durationMs: durationMs,
                coverColor: coverColor,
                lyrics: lyrics,
                lyricsFormat: lyricsFormat,
                lyricsSourcesJson: lyricsSourcesJson,
                metadataJson: metadataJson,
                replayGainDb: replayGainDb,
                replayGainMode: replayGainMode,
                playCount: playCount,
                lastPlayedAt: lastPlayedAt,
                addedAt: addedAt,
                modifiedAt: modifiedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String filePath,
                Value<Uint8List?> coverBytes = const Value.absent(),
                required String title,
                required String artist,
                required String album,
                required int durationMs,
                required int coverColor,
                Value<String?> lyrics = const Value.absent(),
                Value<String?> lyricsFormat = const Value.absent(),
                Value<String?> lyricsSourcesJson = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<double?> replayGainDb = const Value.absent(),
                Value<String?> replayGainMode = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<DateTime?> addedAt = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LibraryTracksCompanion.insert(
                id: id,
                filePath: filePath,
                coverBytes: coverBytes,
                title: title,
                artist: artist,
                album: album,
                durationMs: durationMs,
                coverColor: coverColor,
                lyrics: lyrics,
                lyricsFormat: lyricsFormat,
                lyricsSourcesJson: lyricsSourcesJson,
                metadataJson: metadataJson,
                replayGainDb: replayGainDb,
                replayGainMode: replayGainMode,
                playCount: playCount,
                lastPlayedAt: lastPlayedAt,
                addedAt: addedAt,
                modifiedAt: modifiedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryTracksTable, LibraryTrack>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LibraryTracksTable,
                    LibraryTrack
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryTracksTable,
      LibraryTrack,
      $$LibraryTracksTableFilterComposer,
      $$LibraryTracksTableOrderingComposer,
      $$LibraryTracksTableAnnotationComposer,
      $$LibraryTracksTableCreateCompanionBuilder,
      $$LibraryTracksTableUpdateCompanionBuilder,
      (
        LibraryTrack,
        BaseReferences<_$AppDatabase, $LibraryTracksTable, LibraryTrack>,
      ),
      LibraryTrack,
      PrefetchHooks Function()
    >;
typedef $$LibraryDirectoriesTableCreateCompanionBuilder =
    LibraryDirectoriesCompanion Function({
      required String directoryPath,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$LibraryDirectoriesTableUpdateCompanionBuilder =
    LibraryDirectoriesCompanion Function({
      Value<String> directoryPath,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

class $$LibraryDirectoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryDirectoriesTable> {
  $$LibraryDirectoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get directoryPath => $composableBuilder(
    column: $table.directoryPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryDirectoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryDirectoriesTable> {
  $$LibraryDirectoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get directoryPath => $composableBuilder(
    column: $table.directoryPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryDirectoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryDirectoriesTable> {
  $$LibraryDirectoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get directoryPath => $composableBuilder(
    column: $table.directoryPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$LibraryDirectoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryDirectoriesTable,
          LibraryDirectory,
          $$LibraryDirectoriesTableFilterComposer,
          $$LibraryDirectoriesTableOrderingComposer,
          $$LibraryDirectoriesTableAnnotationComposer,
          $$LibraryDirectoriesTableCreateCompanionBuilder,
          $$LibraryDirectoriesTableUpdateCompanionBuilder,
          (
            LibraryDirectory,
            BaseReferences<
              _$AppDatabase,
              $LibraryDirectoriesTable,
              LibraryDirectory
            >,
          ),
          LibraryDirectory,
          PrefetchHooks Function()
        > {
  $$LibraryDirectoriesTableTableManager(
    _$AppDatabase db,
    $LibraryDirectoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryDirectoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryDirectoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryDirectoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> directoryPath = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryDirectoriesCompanion(
                directoryPath: directoryPath,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String directoryPath,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => LibraryDirectoriesCompanion.insert(
                directoryPath: directoryPath,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryDirectoriesTable, LibraryDirectory>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LibraryDirectoriesTable,
                    LibraryDirectory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryDirectoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryDirectoriesTable,
      LibraryDirectory,
      $$LibraryDirectoriesTableFilterComposer,
      $$LibraryDirectoriesTableOrderingComposer,
      $$LibraryDirectoriesTableAnnotationComposer,
      $$LibraryDirectoriesTableCreateCompanionBuilder,
      $$LibraryDirectoriesTableUpdateCompanionBuilder,
      (
        LibraryDirectory,
        BaseReferences<
          _$AppDatabase,
          $LibraryDirectoriesTable,
          LibraryDirectory
        >,
      ),
      LibraryDirectory,
      PrefetchHooks Function()
    >;
typedef $$PlaybackEventsTableCreateCompanionBuilder =
    PlaybackEventsCompanion Function({
      Value<int> id,
      required String trackId,
      required DateTime playedAt,
    });
typedef $$PlaybackEventsTableUpdateCompanionBuilder =
    PlaybackEventsCompanion Function({
      Value<int> id,
      Value<String> trackId,
      Value<DateTime> playedAt,
    });

class $$PlaybackEventsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackEventsTable> {
  $$PlaybackEventsTableFilterComposer({
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

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaybackEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackEventsTable> {
  $$PlaybackEventsTableOrderingComposer({
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

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaybackEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackEventsTable> {
  $$PlaybackEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);
}

class $$PlaybackEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackEventsTable,
          PlaybackEvent,
          $$PlaybackEventsTableFilterComposer,
          $$PlaybackEventsTableOrderingComposer,
          $$PlaybackEventsTableAnnotationComposer,
          $$PlaybackEventsTableCreateCompanionBuilder,
          $$PlaybackEventsTableUpdateCompanionBuilder,
          (
            PlaybackEvent,
            BaseReferences<_$AppDatabase, $PlaybackEventsTable, PlaybackEvent>,
          ),
          PlaybackEvent,
          PrefetchHooks Function()
        > {
  $$PlaybackEventsTableTableManager(
    _$AppDatabase db,
    $PlaybackEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
              }) => PlaybackEventsCompanion(
                id: id,
                trackId: trackId,
                playedAt: playedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trackId,
                required DateTime playedAt,
              }) => PlaybackEventsCompanion.insert(
                id: id,
                trackId: trackId,
                playedAt: playedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaybackEventsTable, PlaybackEvent>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlaybackEventsTable,
                    PlaybackEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaybackEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackEventsTable,
      PlaybackEvent,
      $$PlaybackEventsTableFilterComposer,
      $$PlaybackEventsTableOrderingComposer,
      $$PlaybackEventsTableAnnotationComposer,
      $$PlaybackEventsTableCreateCompanionBuilder,
      $$PlaybackEventsTableUpdateCompanionBuilder,
      (
        PlaybackEvent,
        BaseReferences<_$AppDatabase, $PlaybackEventsTable, PlaybackEvent>,
      ),
      PlaybackEvent,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String valueJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                valueJson: valueJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                valueJson: valueJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LibraryTracksTableTableManager get libraryTracks =>
      $$LibraryTracksTableTableManager(_db, _db.libraryTracks);
  $$LibraryDirectoriesTableTableManager get libraryDirectories =>
      $$LibraryDirectoriesTableTableManager(_db, _db.libraryDirectories);
  $$PlaybackEventsTableTableManager get playbackEvents =>
      $$PlaybackEventsTableTableManager(_db, _db.playbackEvents);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
