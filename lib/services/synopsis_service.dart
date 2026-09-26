/// Service for sanitizing and validating book descriptions / synopses
/// coming from external sources (Open Library, Google Books) or manual entry.
class SynopsisCleaner {
  SynopsisCleaner._();

  /// Extracts string content from dynamic values, handling:
  /// - null -> ''
  /// - String -> String
  /// - Open Library object: `{"type": "/type/text", "value": "..."}`
  /// - Map with "description" or "value"
  static String extractRawText(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      final val = raw['value'] ?? raw['description'];
      if (val != null) return val.toString();
    }
    return raw.toString();
  }

  /// Cleans incoming description text:
  /// 1. HTML entities decoding & tag stripping
  /// 2. Markdown link and emphasis stripping
  /// 3. Horizontal rules stripping
  /// 4. "Source:", "Contains:", and "See also" section stripping
  /// 5. Edition / ISBN / Catalog boilerplate stripping
  /// 6. Whitespace and trailing junk normalization
  static String clean(dynamic raw) {
    var text = extractRawText(raw).trim();
    if (text.isEmpty) return '';

    // 1. Decode HTML entities
    text = _decodeHtmlEntities(text);

    // 2. Replace HTML line breaks with newlines before stripping tags
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</?p\s*>', caseSensitive: false), '\n\n');

    // 3. Strip remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    // 4. Strip Markdown links: [anchor text](url) -> anchor text
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    );

    // 5. Strip Markdown formatting (bold, italic)
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m.group(1) ?? '');

    // 6. Process line by line for boilerplate, source lines, catalog dumps, and "See also"
    final lines = text.split('\n');
    final cleanedLines = <String>[];

    for (final rawLine in lines) {
      var line = rawLine.trim();

      // Check for "See also" section: stop processing subsequent reference lines
      if (RegExp(r'^see also\b', caseSensitive: false).hasMatch(line)) {
        break;
      }

      // Horizontal rules (e.g. ----------, ***, ---, ___)
      if (RegExp(r'^[*\-_]{3,}$').hasMatch(line)) {
        continue;
      }

      // Markdown headings (#, ##, ###)
      line = line.replaceFirst(RegExp(r'^#{1,6}\s+'), '');

      // "Source:" / "Sources:" / "Contains:" lines
      if (RegExp(r'^(source|sources|contains):\s*', caseSensitive: false).hasMatch(line)) {
        continue;
      }

      // Edition / ISBN / Catalog / Digital library boilerplate
      if (RegExp(
        r'^(isbn(-1[03])?|oclc|lccn|edition|pagination|published by|publisher|format|dewey|classification|series|table of contents|borrowed from|scanned by|digitized by|open library|gutenberg):\s*',
        caseSensitive: false,
      ).hasMatch(line)) {
        continue;
      }

      // Standalone ISBN lines
      if (RegExp(r'^\s*(isbn\s*)?[0-9-]{10,17}[0-9xX]?\s*$', caseSensitive: false).hasMatch(line)) {
        continue;
      }

      // Standalone "digitized by..." or "open library..."
      if (RegExp(r'^(digitized by|open library|gutenberg project)\b', caseSensitive: false).hasMatch(line)) {
        continue;
      }

      cleanedLines.add(line);
    }

    var result = cleanedLines.join('\n');

    // 7. Normalize whitespace: collapse horizontal tabs/spaces
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Collapse 3+ newlines to 2
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Strip trailing punctuation junk and trailing symbols
    result = result.replaceAll(RegExp(r'[\s\-*_#~]+$'), '');

    return result.trim();
  }

  /// Quality check: rejects descriptions that:
  /// - Are under 40 characters
  /// - Are mostly non-letters (< 50% letters)
  /// - Are mostly uppercase (> 65% uppercase of letters, e.g. ALL CAPS shouting)
  /// - Contain a high proportion of URLs (> 20% or 3+ URLs)
  /// - Look like metadata dumps rather than prose (e.g. multiple "Field: Value" lines)
  static bool isQuality(String cleaned) {
    final text = cleaned.trim();
    if (text.length < 40) return false;

    // Count letters
    final letters = RegExp(r'[a-zA-Z\u00C0-\u024F\u1E00-\u1EFF]').allMatches(text).length;
    if (letters / text.length < 0.50) return false;

    // Check uppercase ratio
    if (letters >= 20) {
      final uppers = RegExp(r'[A-Z]').allMatches(text).length;
      if (uppers / letters > 0.65) return false;
    }

    // Check URLs
    final urlMatches = RegExp(r'https?://[^\s]+|www\.[^\s]+').allMatches(text);
    if (urlMatches.length >= 3) return false;
    int totalUrlChars = 0;
    for (final m in urlMatches) {
      totalUrlChars += m.group(0)?.length ?? 0;
    }
    if (totalUrlChars / text.length > 0.20) return false;

    // Check metadata format vs prose
    final nonBlankLines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (nonBlankLines.length >= 3) {
      final colonLines = nonBlankLines.where((l) => RegExp(r'^[A-Za-z\s]{2,18}:\s*').hasMatch(l)).length;
      if (colonLines / nonBlankLines.length >= 0.50) return false;
    }

    // Must have at least 6 words
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 6) return false;

    return true;
  }


  /// Detects descriptions that are actually the book's opening line/sentence
  /// rather than a genuine editorial synopsis.
  ///
  /// Opening lines share common patterns:
  /// 1. Start with an ALL-CAPS word/phrase followed by lowercase narration
  ///    ("IN THE CORNER of a first-class smoking carriage...")
  /// 2. Read as scene-setting narrative without summary structure
  ///    (no character-plus-goal, no "discovers", "must", "follows the story of")
  /// 3. May be in a completely wrong language (Italian, French, etc.)
  ///
  /// Returns true if the text looks like an opening line (should be rejected).
  static bool isLikelyOpeningLine(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // --- Pattern 1: Starts with ALL-CAPS word(s) followed by lowercase ---
    // Matches: "ERANO LE CINQUE di...", "IN THE CORNER of...",
    //          "TEN THOUSAND MILE AWAY, IN THE COLD, WINdowless..."
    final capsStartPattern = RegExp(
      r'^[A-Z][A-Z\s,]{2,}[a-z]',
    );
    if (capsStartPattern.hasMatch(trimmed)) {
      // Additional check: if the caps start is followed by scene-setting
      // (not summary language), it's an opening line
      if (!_hasSummaryLanguage(trimmed)) {
        return true;
      }
    }

    // --- Pattern 2: Non-English content detection ---
    // Check for high proportion of accented/non-ASCII Latin characters
    // typical of Italian, French, Spanish, German text
    if (_isLikelyNonEnglish(trimmed)) {
      return true;
    }

    // --- Pattern 3: Pure scene-setting narrative ---
    // Single continuous paragraph that reads like prose fiction:
    // - No sentence resembling a summary hook
    // - Present tense scene-setting or past tense narration
    // - No meta-words about the book itself
    if (_isPureNarrative(trimmed)) {
      return true;
    }

    return false;
  }

  /// Checks if text contains language typical of book summaries/synopses.
  static bool _hasSummaryLanguage(String text) {
    final lower = text.toLowerCase();
    // Words/phrases that indicate this IS a genuine synopsis
    final summaryMarkers = [
      'must', 'discovers', 'discovers that', 'when ',
      'follows the story', 'a novel about', 'a tale of',
      'the story of', 'in this', 'bestselling', 'award-winning',
      'new york times', 'explores', 'journey', 'struggles',
      'uncovers', 'confronts', 'faces', 'secrets',
      'is forced to', 'sets out to', 'finds herself',
      'finds himself', 'leads to', 'plunges into',
      'a story of', 'debut novel', 'masterpiece',
      'page-turner', 'gripping', 'riveting',
      'heartwarming', 'unforgettable', 'compelling',
      'author of', 'from the creator', 'introduces',
      '#1', 'number one', 'million copies',
    ];

    for (final marker in summaryMarkers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  /// Basic non-English detection for Latin-script languages.
  /// Checks for high frequency of accented characters and common
  /// non-English function words.
  static bool _isLikelyNonEnglish(String text) {
    final lower = text.toLowerCase();

    // Common function words in Italian, French, Spanish, German, Portuguese
    final nonEnglishMarkers = [
      // Italian
      ' della ', ' delle ', ' degli ', ' nella ', ' nelle ',
      ' una ', ' erano ', ' questa ', ' questo ', ' mattina ',
      ' giorno ', ' notte ', ' quando ', ' perché ',
      // French
      ' dans ', ' cette ', ' avec ', ' pour ', ' mais ',
      ' était ', " c'est ", ' les ', ' des ', ' une ',
      // Spanish
      ' esta ', ' pero ', ' porque ', ' cuando ',
      ' había ', ' también ',
      // German
      ' und ', ' nicht ', ' aber ', ' oder ', ' auch ',
      ' diese ', ' einem ', ' einen ',
      // Portuguese
      ' estava ', ' tinha ', ' também ',
    ];

    int nonEnglishHits = 0;
    for (final marker in nonEnglishMarkers) {
      if (lower.contains(marker)) nonEnglishHits++;
    }
    // If 2+ non-English markers found, likely wrong language
    if (nonEnglishHits >= 2) return true;

    // Check ratio of accented characters
    final accentedPattern = RegExp(r'[àáâãäåæçèéêëìíîïðñòóôõöùúûüýþÿ]');
    final accentedCount = accentedPattern.allMatches(lower).length;
    final letterCount = RegExp(r'[a-zA-Z\u00C0-\u024F]').allMatches(lower).length;
    if (letterCount > 20 && accentedCount / letterCount > 0.06) return true;

    return false;
  }

  /// Detects pure narrative prose that is scene-setting rather than synopsis.
  /// A narrative opening typically:
  /// - Is a single paragraph (no line breaks for structure)
  /// - Uses concrete sensory details (time, place, weather, actions)
  /// - Lacks any meta-description of the book's plot arc or themes
  static bool _isPureNarrative(String text) {
    final lower = text.toLowerCase();

    // Must lack ALL summary language to be considered pure narrative
    if (_hasSummaryLanguage(text)) return false;

    // Narrative scene-setting markers
    final narrativeMarkers = [
      // Time/place openers
      RegExp(r'^(it was|there was|on the|at the|in the)\b', caseSensitive: false),
      // Past-tense scene description
      RegExp(r'\b(puffed at|sat in|stood at|walked|looked|stared)\b', caseSensitive: false),
      // Concrete sensory details in opening
      RegExp(r'\b(morning|evening|night|dawn|cold|warm|rain|sun|wind|smoke|cigar)\b', caseSensitive: false),
    ];

    int narrativeHits = 0;
    for (final pattern in narrativeMarkers) {
      if (pattern.hasMatch(lower)) narrativeHits++;
    }

    // If 2+ narrative markers AND no summary language, likely an opening line
    if (narrativeHits >= 2) return true;

    // Very short text (under 200 chars) with no summary language
    // that reads as a single scene-setting sentence
    if (text.length < 200) {
      final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).toList();
      if (sentences.length <= 2 && !_hasSummaryLanguage(text)) {
        // Check if it starts with a location/time phrase
        if (RegExp(r'^(In |On |At |It was |There |From |The )', caseSensitive: false).hasMatch(text)) {
          // But not if it sounds like a summary ("In this novel...", "The story of...")
          if (!RegExp(r'^(In this |The story |The tale |This )', caseSensitive: false).hasMatch(text)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Convenience pipeline: cleans raw input and verifies quality.
  /// If it passes quality check, returns the cleaned string.
  /// Otherwise, returns an empty string (no junk shown).
  static String cleanAndValidate(dynamic raw) {
    final cleaned = clean(raw);
    if (isQuality(cleaned) && !isLikelyOpeningLine(cleaned)) {
      return cleaned;
    }
    return '';
  }

  /// Truncates text for display without ever cutting in the middle of a word.
  static String truncatePreview(String text, {int maxLength = 260}) {
    final trimmed = text.trim();
    if (trimmed.length <= maxLength) return trimmed;

    var cut = trimmed.substring(0, maxLength);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace > maxLength ~/ 2) {
      cut = cut.substring(0, lastSpace);
    }
    // Clean trailing punctuation
    cut = cut.replaceAll(RegExp(r'[\s.,;:!?\-_]+$'), '');
    return '$cut...';
  }

  /// Decodes common HTML entities including numeric codes.
  static String _decodeHtmlEntities(String text) {
    var out = text
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…');

    // Decode decimal numeric entities: &#123;
    out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1) ?? '');
      if (code != null && code > 0 && code <= 0x10FFFF) {
        return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    });

    // Decode hex numeric entities: &#x1f;
    out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final code = int.tryParse(match.group(1) ?? '', radix: 16);
      if (code != null && code > 0 && code <= 0x10FFFF) {
        return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    });

    return out;
  }
}
