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

/// Tags whose content is dropped entirely rather than walked - their text
/// isn't readable chat content.
const _skippedTags = {'script', 'style', 'noscript'};

/// Safety cap on how many DOM nodes the walk below will visit. A corrupted
/// or adversarial export can nest tens of thousands of elements; past this
/// many nodes we stop descending further and return whatever text was
/// gathered so far rather than let extraction run unbounded.
const _maxHtmlNodesWalked = 200000;

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

  final buffer = StringBuffer();
  _walkHtml(document.body ?? document.documentElement!, buffer);

  return buffer
      .toString()
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Walks the DOM tree iteratively (an explicit stack instead of recursive
/// calls, and without using [dom.Element.querySelectorAll] - which recurses
/// per depth level internally in the `html` package and so is itself a
/// stack-overflow risk on a deeply nested document) so a pathologically
/// deep/nested document can't blow the call stack - a real risk for a
/// corrupted or adversarial export, where recursive descent would throw an
/// unrecoverable [StackOverflowError]. Also caps total nodes visited
/// ([_maxHtmlNodesWalked]) so a huge document can't make this run
/// unbounded, and drops the content of [_skippedTags] entirely rather than
/// descending into it.
void _walkHtml(dom.Node root, StringBuffer buffer) {
  final stack = [_HtmlFrame(root)];
  var visited = 0;

  while (stack.isNotEmpty) {
    final frame = stack.last;
    final node = frame.node;

    if (node is dom.Text) {
      buffer.write(node.text);
      stack.removeLast();
      continue;
    }
    if (node is! dom.Element) {
      stack.removeLast();
      continue;
    }

    if (frame.childIndex == 0 &&
        (++visited > _maxHtmlNodesWalked || _skippedTags.contains(node.localName))) {
      stack.removeLast(); // cap hit, or a script/style/noscript subtree
      continue;
    }

    if (frame.childIndex < node.nodes.length) {
      stack.add(_HtmlFrame(node.nodes[frame.childIndex++]));
    } else {
      // Two newlines (a blank line), not one - so sibling block elements
      // read as separated paragraphs rather than merely separate lines.
      // The whitespace-collapse pass above cleans up the runs of 4+
      // newlines this produces for nested block elements (e.g. a <p>
      // inside a <div>).
      if (_blockTags.contains(node.localName)) buffer.write('\n\n');
      stack.removeLast();
    }
  }
}

class _HtmlFrame {
  final dom.Node node;
  int childIndex = 0;
  _HtmlFrame(this.node);
}

/// Safety cap on how many pages of a PDF get text-extracted. A chat export
/// has no business running past this many pages - a file that does is
/// either corrupted or not actually a chat export, and extracting every
/// page of a huge PDF can take a long time and a lot of memory for no
/// benefit here.
const _maxPdfPagesExtracted = 2000;

/// Extracts the text layer from a PDF chat export. Throws a
/// [FormatException] if the PDF has no extractable text (e.g. it's a
/// scanned image with no text layer) - callers should treat that the same
/// as any other unreadable file (skip it), not create a blank note.
String extractTextFromPdf(List<int> bytes) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    final pageCount = document.pages.count;
    final text = pageCount > _maxPdfPagesExtracted
        ? PdfTextExtractor(document)
            .extractText(startPageIndex: 0, endPageIndex: _maxPdfPagesExtracted - 1)
        : PdfTextExtractor(document).extractText();
    if (text.trim().isEmpty) {
      throw const FormatException('No extractable text (likely a scanned-image PDF)');
    }
    return text;
  } finally {
    document.dispose();
  }
}
