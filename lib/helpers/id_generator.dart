int _counter = 0;

/// Generates an id that's unique for the lifetime of the app process, even
/// if called more than once within the same millisecond (e.g. while bulk
/// importing files). A plain `DateTime.now().millisecondsSinceEpoch` repeats
/// under that condition, which let two notes/modules silently end up with
/// the same id - breaking anything that looks records up by id, like
/// deleting a specific note.
String generateId() {
  _counter++;
  return '${DateTime.now().millisecondsSinceEpoch}-$_counter';
}
