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
  final List<String> genres;
  final double rating; // 0.0 to 5.0 with 0.5 increments
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
    this.genres = const [],
    this.rating = 0.0,
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

  Book copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? coverUrl,
    List<String>? genres,
    double? rating,
    String? description,
    DateTime? startDate,
    DateTime? finishDate,
    ReadingStatus? status,
    String? notes,
    List<BookQuote>? quotes,
    int? pageCount,
    DateTime? dateAdded,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      coverUrl: coverUrl ?? this.coverUrl,
      genres: genres ?? this.genres,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      finishDate: finishDate ?? this.finishDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      quotes: quotes ?? this.quotes,
      pageCount: pageCount ?? this.pageCount,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'coverUrl': coverUrl,
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
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      authors: List<String>.from(map['authors'] as List? ?? []),
      coverUrl: map['coverUrl'] as String?,
      genres: List<String>.from(map['genres'] as List? ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
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
