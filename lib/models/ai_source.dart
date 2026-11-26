/// Which AI a chat-import [Note] came from. A plain (non-Hive) enum -
/// [Note.aiSource] stores [storageValue] as a string, so this can be
/// renamed/extended without touching the Hive schema.
enum AiSource {
  gemini,
  geminiNotebook,
  claude;

  /// Value persisted on [Note.aiSource] - stable even if display labels
  /// change.
  String get storageValue => name;

  /// Looks up the enum value for a stored string, or null if it doesn't
  /// match any known source (e.g. a legacy/unrecognized value) - this
  /// degrades to "no badge" rather than throwing.
  static AiSource? fromStorageValue(String? value) {
    for (final source in AiSource.values) {
      if (source.name == value) return source;
    }
    return null;
  }

  /// Full label, e.g. for the "which AI is this from?" picker dialog.
  String get label => switch (this) {
        AiSource.gemini => 'Gemini',
        AiSource.geminiNotebook => 'Gemini Notebook (NotebookLM)',
        AiSource.claude => 'Claude',
      };

  /// Short label for compact UI, e.g. the note-tile badge and mirrored tag.
  String get tagLabel => switch (this) {
        AiSource.gemini => 'Gemini',
        AiSource.geminiNotebook => 'NotebookLM',
        AiSource.claude => 'Claude',
      };
}
