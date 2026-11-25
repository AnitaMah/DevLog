import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Tags whose content should start a new line in the extracted text, so an
/// HTML chat export reads as separated paragraphs/messages rather than one
/// run-on sentence.
const _blockTags = {
  'p', 'div', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'br', 'tr', 'section', 'article',
};

/// Extracts readable plain text from an HTML chat export: strips tags,
/// drops `<script>`/`<style>`/`<noscript>` content entirely, and inserts a
/// line break after each block-level element so paragraphs/messages stay
/// visually separated instead of running together.
///
/// Deliberately does not attempt to detect or label individual speaker
/// turns ("You said... / Claude said...") - export markup differs and is
/// unreliable per provider. This produces one flowing, paragraph-separated
/// text dump of the whole conversation, which is enough to make it
/// readable as a note without taking on open-ended per-provider HTML
/// structure maintenance.
String extractTextFromHtml(String rawHtml) {
  final document = html_parser.parse(rawHtml);
  for (final tag in ['script', 'style', 'noscript']) {
    for (final el in document.querySelectorAll(tag).toList()) {
      el.remove();
    }
  }

  final buffer = StringBuffer();
  void walk(dom.Node node) {
    if (node is dom.Text) {
      buffer.write(node.text);
    } else if (node is dom.Element) {
      for (final child in node.nodes) {
        walk(child);
      }
      // Two newlines (a blank line), not one - so sibling block elements
      // read as separated paragraphs rather than merely separate lines.
      // The whitespace-collapse pass below cleans up the runs of 4+
      // newlines this produces for nested block elements (e.g. a <p>
      // inside a <div>).
      if (_blockTags.contains(node.localName)) buffer.write('\n\n');
    }
  }

  walk(document.body ?? document.documentElement!);

  return buffer
      .toString()
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Extracts the text layer from a PDF chat export. Throws a
/// [FormatException] if the PDF has no extractable text (e.g. it's a
/// scanned image with no text layer) - callers should treat that the same
/// as any other unreadable file (skip it), not create a blank note.
String extractTextFromPdf(List<int> bytes) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    final text = PdfTextExtractor(document).extractText();
    if (text.trim().isEmpty) {
      throw const FormatException('No extractable text (likely a scanned-image PDF)');
    }
    return text;
  } finally {
    document.dispose();
  }
}
