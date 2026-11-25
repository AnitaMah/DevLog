// Unit tests for the pure HTML-to-text extraction used by the AI chat
// import feature (Session 9). No Flutter widget harness needed - these are
// plain Dart functions.

import 'package:flutter_test/flutter_test.dart';
import 'package:dev_log/helpers/chat_text_extraction.dart';

void main() {
  test('extractTextFromHtml strips tags and preserves paragraph breaks', () {
    const html = '<html><body><p>Hello</p><p>World</p></body></html>';

    expect(extractTextFromHtml(html), 'Hello\n\nWorld');
  });

  test('extractTextFromHtml drops script and style content entirely', () {
    const html = '<body><script>ignored()</script><style>.x{color:red}</style><div>Visible</div></body>';

    expect(extractTextFromHtml(html), 'Visible');
  });

  test('extractTextFromHtml collapses runs of whitespace', () {
    const html = '<body><p>Line   one</p>\n\n\n<p>Line two</p></body>';

    expect(extractTextFromHtml(html), 'Line one\n\nLine two');
  });

  test('extractTextFromHtml handles nested block elements without duplicating text', () {
    const html = '<body><div><p>Nested</p></div></body>';

    expect(extractTextFromHtml(html), 'Nested');
  });
}
