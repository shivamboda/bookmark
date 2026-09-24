import 'dart:convert';
import 'dart:typed_data';

/// Represents the reading status of a book in "Bookmark".
enum ReadingStatus {
  wantToRead('Want to Read'),
  reading('Reading'),
  finished('Finished'),
  paused('Paused/DNF');

  final String label;
  const ReadingStatus(this.label);

  static ReadingStatus fromString(String value) {
    return ReadingStatus.values.firstWhere(
      (status) => status.name == value || status.label == value,
      orElse: () => ReadingStatus.wantToRead,
    );
  }
}

/// Represents a favorite quote saved from a book.
class BookQuote {
  final String id;
  final String quote;
  final int? pageNumber;
  final DateTime createdAt;

  const BookQuote({
    required this.id,
    required this.quote,
    this.pageNumber,
    required this.createdAt,
  });

  /// Strips any enclosing quotation marks (straight ", ', curly “ ”, ‘ ’, or « »)
  /// so quote text is never duplicated when displayed inside quotation marks.
  static String stripOuterQuotes(String raw) {
    var s = raw.trim();
    bool changed = true;
    while (changed && s.isNotEmpty) {
      changed = false;
      // Paired quotes
      if ((s.startsWith('"') && s.endsWith('"') && s.length >= 2) ||
          (s.startsWith("'") && s.endsWith("'") && s.length >= 2) ||
          (s.startsWith('“') && s.endsWith('”') && s.length >= 2) ||
          (s.startsWith('‘') && s.endsWith('’') && s.length >= 2) ||
          (s.startsWith('«') && s.endsWith('»') && s.length >= 2) ||
          (s.startsWith('”') && s.endsWith('”') && s.length >= 2) ||
          (s.startsWith('“') && s.endsWith('“') && s.length >= 2)) {
        s = s.substring(1, s.length - 1).trim();
        changed = true;
        continue;
      }
      // Single stray outer quotes
      if (s.startsWith('"') || s.startsWith("'") || s.startsWith('“') || s.startsWith('‘') || s.startsWith('«')) {
        s = s.substring(1).trim();
        changed = true;
        continue;
      }
      if (s.endsWith('"') || s.endsWith("'") || s.endsWith('”') || s.endsWith('’') || s.endsWith('»')) {
        s = s.substring(0, s.length - 1).trim();
        changed = true;
        continue;
      }
    }
    return s;
  }

  /// Ensures that trailing dots never exceed 3 (e.g. cleans "…." or ".…" or "...." to "…").
  static String sanitizeTrailingDots(String text) {
    var s = text.trim();
    // Collapse any ellipsis + dot or dot + ellipsis into a single ellipsis
    s = s.replaceAll(RegExp(r'(…|\.\.\.)\s*\.+'), '…');
    s = s.replaceAll(RegExp(r'\.+\s*(…|\.\.\.)'), '…');
    // Collapse 4 or more dots in a row to 3 dots
    s = s.replaceAll(RegExp(r'\.{4,}'), '...');
    s = s.replaceAll('….', '…');
    s = s.replaceAll('.…', '…');
    return s;
  }

  /// Returns the cleaned quote text (without outer quotes and with sanitized trailing dots).
  String get cleanText => sanitizeTrailingDots(stripOuterQuotes(quote));

  /// Formatted for full display on Book Detail and Add/Edit cards: “Cleaned text”
  String get displayQuote => '“$cleanText”';

  /// Formatted for compact 1-line snippet on Library cards.
  /// Ensures trailing periods before ellipsis are stripped so it never displays more than 3 dots.
  static String formatSnippet(String rawQuote, {int maxLength = 52}) {
    var clean = stripOuterQuotes(rawQuote);
    clean = sanitizeTrailingDots(clean);

    if (clean.length > maxLength) {
      var truncated = clean.substring(0, maxLength);
      // If we cut in the middle of a word, rewind to the last space
      if (maxLength < clean.length && !RegExp(r'[\s.,;:!?]').hasMatch(clean[maxLength])) {
        final lastSpace = truncated.lastIndexOf(' ');
        if (lastSpace > maxLength ~/ 2) {
          truncated = truncated.substring(0, lastSpace);
        }
      }
      // Strip any trailing punctuation (.,;:!?) so we don't end up with "tragedy.…"
      truncated = truncated.replaceAll(RegExp(r'[\s.,;:!?\u2026]+$'), '');
      return '“$truncated…”';
    }
    return '“$clean”';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote': quote,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookQuote.fromMap(Map<String, dynamic> map) {
    return BookQuote(
      id: map['id'] as String,
      quote: map['quote'] as String,
      pageNumber: map['pageNumber'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

/// Primary data model for a book entry in "Bookmark".
class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final Uint8List? coverBytes;
  final List<String> genres;
  final double? rating; // 0.0 to 5.0 with 0.5 increments, nullable
  final String description;
  final bool descriptionIsUserEdited;
  final DateTime? startDate;
  final DateTime? finishDate;
  final ReadingStatus status;
  final String notes;
  final List<BookQuote> quotes;
  final int? pageCount;
  final DateTime dateAdded;

  const Book({
    required this.id,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.coverBytes,
    this.genres = const [],
    this.rating,
    this.description = '',
    this.descriptionIsUserEdited = false,
    this.startDate,
    this.finishDate,
    this.status = ReadingStatus.wantToRead,
    this.notes = '',
    this.quotes = const [],
    this.pageCount,
    required this.dateAdded,
  });

  String get authorDisplay => authors.isEmpty ? 'Unknown Author' : authors.join(', ');

  bool get isRated => rating != null && rating! > 0;
  double get ratingOrZero => rating ?? 0.0;

  /// Returns only clean, human-friendly genre labels, filtering out catalog strings.
  List<String> get cleanGenres => genres.where((g) {
    final t = g.trim();
    if (t.isEmpty) return false;
    if (t.contains(':') || t.contains(',') || t.contains('=') || t.contains('/')) return false;
    if (t.length > 25) return false;
    final lower = t.toLowerCase();
    if (lower.contains('nyt') || lower.contains('bestseller') || lower.contains('print') || lower.contains('edition')) return false;
    if (lower.contains('fiction') && t.contains(' ')) return false;
    return true;
  }).toList();

  Book copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? coverUrl,
    Uint8List? coverBytes,
    bool clearCoverBytes = false,
    List<String>? genres,
    double? rating,
    bool clearRating = false,
    String? description,
    bool? descriptionIsUserEdited,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? finishDate,
    bool clearFinishDate = false,
    ReadingStatus? status,
    String? notes,
    List<BookQuote>? quotes,
    int? pageCount,
    bool clearPageCount = false,
    DateTime? dateAdded,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      coverUrl: coverUrl ?? this.coverUrl,
      coverBytes: clearCoverBytes ? null : (coverBytes ?? this.coverBytes),
      genres: genres ?? this.genres,
      rating: clearRating ? null : (rating ?? this.rating),
      description: description ?? this.description,
      descriptionIsUserEdited: descriptionIsUserEdited ?? this.descriptionIsUserEdited,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      finishDate: clearFinishDate ? null : (finishDate ?? this.finishDate),
      status: status ?? this.status,
      notes: notes ?? this.notes,
      quotes: quotes ?? this.quotes,
      pageCount: clearPageCount ? null : (pageCount ?? this.pageCount),
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'coverUrl': coverUrl,
      'coverBytes': coverBytes != null ? base64Encode(coverBytes!) : null,
      'genres': genres,
      'rating': rating,
      'description': description,
      'descriptionIsUserEdited': descriptionIsUserEdited,
      'startDate': startDate?.toIso8601String(),
      'finishDate': finishDate?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'quotes': quotes.map((q) => q.toMap()).toList(),
      'pageCount': pageCount,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    Uint8List? parsedCoverBytes;
    if (map['coverBytes'] != null) {
      try {
        parsedCoverBytes = base64Decode(map['coverBytes'] as String);
      } catch (_) {}
    }

    final rawGenres = List<String>.from(map['genres'] as List? ?? []);
    final cleanGenres = rawGenres.where((g) {
      final t = g.trim();
      if (t.isEmpty) return false;
      if (t.contains(':') || t.contains(',') || t.contains('=') || t.contains('/')) return false;
      if (t.length > 25) return false;
      final lower = t.toLowerCase();
      if (lower.contains('nyt') || lower.contains('bestseller')) return false;
      return true;
    }).toList();

    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      authors: List<String>.from(map['authors'] as List? ?? []),
      coverUrl: map['coverUrl'] as String?,
      coverBytes: parsedCoverBytes,
      genres: cleanGenres,
      rating: (map['rating'] as num?)?.toDouble(),
      description: map['description'] as String? ?? '',
      descriptionIsUserEdited: map['descriptionIsUserEdited'] as bool? ?? false,
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate'] as String) : null,
      finishDate: map['finishDate'] != null ? DateTime.parse(map['finishDate'] as String) : null,
      status: ReadingStatus.fromString(map['status'] as String? ?? 'wantToRead'),
      notes: map['notes'] as String? ?? '',
      quotes: (map['quotes'] as List? ?? [])
          .map((q) => BookQuote.fromMap(Map<String, dynamic>.from(q as Map)))
          .toList(),
      pageCount: map['pageCount'] as int?,
      dateAdded: map['dateAdded'] != null
          ? DateTime.parse(map['dateAdded'] as String)
          : DateTime.now(),
    );
  }
}
