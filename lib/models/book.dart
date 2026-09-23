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

    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      authors: List<String>.from(map['authors'] as List? ?? []),
      coverUrl: map['coverUrl'] as String?,
      coverBytes: parsedCoverBytes,
      genres: List<String>.from(map['genres'] as List? ?? []),
      rating: (map['rating'] as num?)?.toDouble(),
      description: map['description'] as String? ?? '',
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
