import 'package:flutter_test/flutter_test.dart';
import 'package:recallr/common/all_links_wid.dart';

void main() {
  group('readingTimeLabel', () {
    test('empty text returns < 1 min', () {
      expect(readingTimeLabel('', null), '< 1 min');
    });

    test('single word returns < 1 min', () {
      expect(readingTimeLabel('Hello', null), '< 1 min');
    });

    test('exactly 200 words returns < 1 min', () {
      final title = List.filled(200, 'word').join(' ');
      expect(readingTimeLabel(title, null), '< 1 min');
    });

    test('201 words returns 2 min', () {
      final title = List.filled(201, 'word').join(' ');
      expect(readingTimeLabel(title, null), '2 min');
    });

    test('combines title and description word counts', () {
      final title = List.filled(150, 'word').join(' ');
      final desc = List.filled(51, 'word').join(' ');
      expect(readingTimeLabel(title, desc), '2 min');
    });

    test('801 words returns 5 min', () {
      final title = List.filled(801, 'word').join(' ');
      expect(readingTimeLabel(title, null), '5 min');
    });

    test('null description treated as empty', () {
      expect(readingTimeLabel('Hello world', null), '< 1 min');
    });

    test('whitespace-only description does not affect count', () {
      final title = List.filled(200, 'word').join(' ');
      expect(readingTimeLabel(title, '   '), '< 1 min');
    });
  });
}
