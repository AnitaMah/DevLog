/// What to do with a file whose title matches a note that already exists
/// in the target module. Chosen per-file in [ImportPreviewDialog] and
/// applied by [runImport] - see those for how each option behaves.
enum ImportConflictChoice {
  overwrite,
  merge,
  skip;

  String get label => switch (this) {
        ImportConflictChoice.overwrite => 'Overwrite',
        ImportConflictChoice.merge => 'Merge',
        ImportConflictChoice.skip => 'Skip',
      };
}
