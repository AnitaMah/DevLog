import 'package:flutter_test/flutter_test.dart';

import 'package:dev_log/helpers/search_index.dart';
import 'package:dev_log/models/note.dart';

void main() {
  Note note(String id, String title, {String content = '', List<String>? tags}) => Note(
        id: id,
        moduleId: 'm1',
        title: title,
        content: content,
        tags: tags,
      );

  group('SearchIndex', () {
    test('a blank query returns every note, most-recently-updated first', () {
      final older = Note(id: 'a', moduleId: 'm1', title: 'A', updatedAt: DateTime(2026, 1, 1));
      final newer = Note(id: 'b', moduleId: 'm1', title: 'B', updatedAt: DateTime(2026, 2, 1));
      final index = SearchIndex.build([older, newer]);

      expect(index.search('').map((n) => n.id), ['b', 'a']);
    });

    test('matches a note by a title word prefix', () {
      final index = SearchIndex.build([note('a', 'Rust ownership')]);

      expect(index.search('rust').map((n) => n.id), ['a']);
      expect(index.search('own').map((n) => n.id), ['a']);
    });

    test('matches a note by content', () {
      final index = SearchIndex.build([note('a', 'Notes', content: 'borrow checker basics')]);

      expect(index.search('checker').map((n) => n.id), ['a']);
    });

    test('matches a note by tag', () {
      final index = SearchIndex.build([note('a', 'Notes', tags: ['flutter'])]);

      expect(index.search('flut').map((n) => n.id), ['a']);
    });

    test('a multi-word query requires every word to match, even across title and content', () {
      final index = SearchIndex.build([note('a', 'Rust', content: 'ownership model')]);

      expect(index.search('rust ownership').map((n) => n.id), ['a']);
      expect(index.search('rust missing'), isEmpty);
    });

    test('a title match ranks above a content-only match', () {
      final titleMatch = note('a', 'Dart basics');
      final contentMatch = note('b', 'Other', content: 'dart is nice');
      final index = SearchIndex.build([contentMatch, titleMatch]);

      expect(index.search('dart').map((n) => n.id), ['a', 'b']);
    });

    test('no match returns an empty list', () {
      final index = SearchIndex.build([note('a', 'Rust ownership')]);

      expect(index.search('zzz'), isEmpty);
    });
  });
}
