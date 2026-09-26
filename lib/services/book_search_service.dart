import 'synopsis_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Lightweight data class for a single search result from external APIs.
///
/// This is separate from the [Book] model because it represents
/// a *candidate* result before the user decides to save it.
class BookSearchResult {
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final int? pageCount;
  final String? description;
  final List<String> genres;

  const BookSearchResult({
    required this.title,
    this.authors = const [],
    this.coverUrl,
    this.pageCount,
    this.description,
    this.genres = const [],
  });
}

/// Service that queries external book APIs to find books by title/author.
///
/// **Strategy**: Open Library first (no API key, CORS-friendly),
/// then Google Books as a fallback (rate-limited but also keyless).
///
/// Both APIs support CORS and work from Flutter Web without a proxy.
class BookSearchService {
  /// Fetches and cleans a description from Google Books for a specific book title and author.
  static Future<String?> fetchGoogleBooksDescription(String title, List<String> authors) async {
    try {
      final query = authors.isNotEmpty
          ? 'intitle:"$title"+inauthor:"${authors.first}"'
          : 'intitle:"$title"';
      final uri = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes'
        '?q=${Uri.encodeComponent(query)}'
        '&maxResults=1'
        '&printType=books',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final items = json['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          final volumeInfo = (items.first as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>?;
          final rawDesc = volumeInfo?['description'];
          final cleaned = SynopsisCleaner.cleanAndValidate(rawDesc);
          if (cleaned.isNotEmpty) return cleaned;
        }
      }
    } catch (_) {}
    return null;
  }

  BookSearchService._();

  /// Maximum results to display in the search list.
  static const int _maxResults = 15;

  /// Searches Open Library first; if it returns zero results or errors,
  /// falls back to Google Books. Returns up to [_maxResults] results.
  static Future<List<BookSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final olResults = await _searchOpenLibrary(query);
      if (olResults.isNotEmpty) return olResults;
      return await _searchGoogleBooks(query);
    } catch (e) {
      debugPrint('BookSearchService: All searches failed — $e');
      try {
        return await _searchGoogleBooks(query);
      } catch (_) {
        return [];
      }
    }
  }

  // -------------------------------------------------------------------------
  // Open Library  (https://openlibrary.org/dev/docs/api/search)
  // -------------------------------------------------------------------------

  static Future<List<BookSearchResult>> _searchOpenLibrary(String query) async {
    final uri = Uri.parse(
      'https://openlibrary.org/search.json'
      '?q=${Uri.encodeComponent(query)}'
      '&limit=$_maxResults'
      '&fields=title,author_name,cover_i,number_of_pages_median,subject',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      debugPrint('OpenLibrary: HTTP ${response.statusCode}');
      return [];
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = json['docs'] as List<dynamic>? ?? [];

    final docsMapped = docs.map<BookSearchResult?>((doc) {
      final d = doc as Map<String, dynamic>;
      final title = d['title'] as String?;
      if (title == null || title.trim().isEmpty) return null;

      // Cover image URL from Open Library cover ID
      final coverId = d['cover_i'];
      String? coverUrl;
      if (coverId != null) {
        coverUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
      }

      // Authors list
      final authorList = (d['author_name'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [];

      // Page count (median across editions)
      final pages = d['number_of_pages_median'] as int?;

      // Note: Open Library search API doesn't return reliable descriptions
      // (it often returns the book's opening line via 'first_sentence').
      // Descriptions will be fetched from Google Books in the enrichment step.
      String? desc;

      // Genres / Subjects — cleaned via keyword matching to the app's genre list
      final rawSubjects = (d['subject'] as List<dynamic>?)
              ?.take(20)  // Take more raw subjects to increase matching chances
              .map((s) => s.toString())
              .toList() ??
          [];
      final subjects = _cleanGenres(rawSubjects);

      return BookSearchResult(
        title: title,
        authors: authorList,
        coverUrl: coverUrl,
        pageCount: pages,
        description: desc,
        genres: subjects,
      );
    }).whereType<BookSearchResult>().take(_maxResults).toList();

    // Always try Google Books for descriptions — their editorial summaries
    // are consistently higher quality than Open Library's first_sentence data.
    final enriched = <BookSearchResult>[];
    for (final res in docsMapped) {
      String? desc;
      try {
        final googleDesc = await fetchGoogleBooksDescription(res.title, res.authors);
        if (googleDesc != null && googleDesc.isNotEmpty) {
          desc = googleDesc;
        }
      } catch (_) {}
      // Fall back to OL description only if Google Books returned nothing
      desc ??= res.description;
      enriched.add(BookSearchResult(
        title: res.title,
        authors: res.authors,
        coverUrl: res.coverUrl,
        pageCount: res.pageCount,
        description: desc,
        genres: res.genres,
      ));
    }
    return enriched;
  }

  // -------------------------------------------------------------------------
  // Google Books  (https://developers.google.com/books/docs/v1/using)
  // -------------------------------------------------------------------------

  static Future<List<BookSearchResult>> _searchGoogleBooks(String query) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes'
      '?q=${Uri.encodeComponent(query)}'
      '&maxResults=$_maxResults'
      '&printType=books',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      debugPrint('GoogleBooks: HTTP ${response.statusCode}');
      return [];
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>? ?? [];

    return items.map<BookSearchResult?>((item) {
      final volumeInfo =
          (item as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>?;
      if (volumeInfo == null) return null;

      final title = volumeInfo['title'] as String?;
      if (title == null || title.trim().isEmpty) return null;

      // Authors
      final authors = (volumeInfo['authors'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [];

      // Cover image — prefer thumbnail, upgrade HTTP to HTTPS
      String? coverUrl;
      final imageLinks =
          volumeInfo['imageLinks'] as Map<String, dynamic>?;
      if (imageLinks != null) {
        coverUrl = (imageLinks['thumbnail'] ??
                imageLinks['smallThumbnail']) as String?;
        coverUrl = coverUrl?.replaceFirst('http://', 'https://');
      }

      // Page count
      final pages = volumeInfo['pageCount'] as int?;

      // Description cleaned through SynopsisCleaner
      final rawDesc = volumeInfo['description'];
      final cleanedDesc = SynopsisCleaner.cleanAndValidate(rawDesc);
      final desc = cleanedDesc.isNotEmpty ? cleanedDesc : null;

      // Categories — cleaned via keyword matching to the app's genre list
      final rawCategories = (volumeInfo['categories'] as List<dynamic>?)
              ?.map((c) => c.toString())
              .toList() ??
          [];
      final categories = _cleanGenres(rawCategories);

      return BookSearchResult(
        title: title,
        authors: authors,
        coverUrl: coverUrl,
        pageCount: pages,
        description: desc,
        genres: categories,
      );
    }).whereType<BookSearchResult>().take(_maxResults).toList();
  }

  // -------------------------------------------------------------------------
  // Genre / Subject cleaning
  // -------------------------------------------------------------------------

  /// The app's canonical genre labels (must match AddEditBookScreen._suggestedGenres).
  static const List<String> _knownGenres = [
    'Fantasy', 'Romance', 'Mystery', 'Historical Fiction', 'Classic',
    'Sci-Fi', 'Non-fiction', 'Poetry', 'Thriller', 'Young Adult',
    'Mythology', 'Drama',
  ];

  /// Keyword fragments that map a raw subject string to a known genre.
  /// Checked case-insensitively.  Order matters: first match wins.
  static const Map<String, String> _keywordToGenre = {
    'fantasy': 'Fantasy',
    'romance': 'Romance',
    'mystery': 'Mystery',
    'detective': 'Mystery',
    'crime': 'Mystery',
    'histor': 'Historical Fiction',
    'classic': 'Classic',
    'sci-fi': 'Sci-Fi',
    'science fiction': 'Sci-Fi',
    'nonfiction': 'Non-fiction',
    'non-fiction': 'Non-fiction',
    'poetry': 'Poetry',
    'poems': 'Poetry',
    'thriller': 'Thriller',
    'suspense': 'Thriller',
    'young adult': 'Young Adult',
    'ya ': 'Young Adult',
    'mythology': 'Mythology',
    'myth': 'Mythology',
    'drama': 'Drama',
    'plays': 'Drama',
    'horror': 'Thriller',
    'adventure': 'Fantasy',
    'biography': 'Non-fiction',
    'memoir': 'Non-fiction',
    'self-help': 'Non-fiction',
    'philosophy': 'Non-fiction',
    'humor': 'Drama',
    'humorous': 'Drama',
    'literary': 'Classic',
  };

  /// Cleans raw API subject/category strings into usable genre tags.
  ///
  /// Rules:
  /// 1. Drop subjects containing colons (catalog codes like "nyt:...").
  /// 2. Drop subjects containing commas (compound headings like "Fiction, humorous, general").
  /// 3. Drop subjects longer than 25 characters.
  /// 4. Try to map remaining subjects to [_knownGenres] via keyword matching.
  /// 5. Anything that doesn't match is dropped entirely.
  /// 6. De-duplicate the final list.
  static List<String> _cleanGenres(List<String> rawSubjects) {
    final Set<String> matched = {};

    for (final raw in rawSubjects) {
      final trimmed = raw.trim();

      // Filter: skip catalog codes, compound headings, and overly long strings
      if (trimmed.contains(':')) continue;
      if (trimmed.contains(',')) continue;
      if (trimmed.length > 25) continue;

      // Check if it's already an exact known genre (case-insensitive)
      final exactMatch = _knownGenres.where(
        (g) => g.toLowerCase() == trimmed.toLowerCase(),
      );
      if (exactMatch.isNotEmpty) {
        matched.add(exactMatch.first);
        continue;
      }

      // Try keyword matching
      final lower = trimmed.toLowerCase();
      for (final entry in _keywordToGenre.entries) {
        if (lower.contains(entry.key)) {
          matched.add(entry.value);
          break;
        }
      }
      // If no match, drop it — better zero genres than garbage
    }

    return matched.toList();
  }
}
