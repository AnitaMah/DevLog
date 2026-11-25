import 'package:dev_log/models/note.dart';

/// An in-memory full-text index over note titles, tags, and content, built
/// once from a snapshot of notes and then queried many times without
/// re-scanning every note's text on each keystroke.
///
/// Each distinct word is mapped to the ids of every note containing it
/// (title/tag words and content words are tracked separately, so a title
/// match can outrank a content-only match). A query is tokenized the same
/// way; a note must contain every query word, by prefix (so "rea" matches
/// "react"), to match at all.
class SearchIndex {
  final Map<String, Set<String>> _titleWords = {};
  final Map<String, Set<String>> _contentWords = {};
  final Map<String, Note> _notesById = {};

  SearchIndex.build(List<Note> notes) {
    for (final note in notes) {
      _notesById[note.id] = note;
      for (final word in _tokenize(note.title)) {
        _titleWords.putIfAbsent(word, () => {}).add(note.id);
      }
      for (final tag in note.tags) {
        for (final word in _tokenize(tag)) {
          _titleWords.putIfAbsent(word, () => {}).add(note.id);
        }
      }
      for (final word in _tokenize(note.content)) {
        _contentWords.putIfAbsent(word, () => {}).add(note.id);
      }
    }
  }

  /// Every indexed note, most-recently-updated first, when [query] is
  /// blank; otherwise every note matching all of [query]'s words (by
  /// prefix), ranked by title/tag hits first, then by most recently
  /// updated.
  List<Note> search(String query) {
    final words = _tokenize(query);
    if (words.isEmpty) {
      return _notesById.values.toList()..sort(_byRecency);
    }

    Set<String>? matchIds;
    final titleHits = <String, int>{};
    for (final word in words) {
      final idsForWord = <String>{};
      for (final entry in _titleWords.entries) {
        if (!entry.key.startsWith(word)) continue;
        idsForWord.addAll(entry.value);
        for (final id in entry.value) {
          titleHits[id] = (titleHits[id] ?? 0) + 1;
        }
      }
      for (final entry in _contentWords.entries) {
        if (entry.key.startsWith(word)) idsForWord.addAll(entry.value);
      }
      matchIds = matchIds == null ? idsForWord : matchIds.intersection(idsForWord);
      if (matchIds.isEmpty) break;
    }

    final results = (matchIds ?? const <String>{}).map((id) => _notesById[id]!).toList();
    results.sort((a, b) {
      final byTitle = (titleHits[b.id] ?? 0).compareTo(titleHits[a.id] ?? 0);
      return byTitle != 0 ? byTitle : _byRecency(a, b);
    });
    return results;
  }

  int _byRecency(Note a, Note b) => b.updatedAt.compareTo(a.updatedAt);

  static List<String> _tokenize(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.isNotEmpty)
      .toList();
}
