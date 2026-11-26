/// Which kind of record an [ActivityItem] wraps.
enum ActivityType { note, module }

/// A lightweight, read-only view of a single recently-changed [Note] or
/// [Module], for the dashboard's activity feed
/// (`DatabaseHelper.getRecentActivity`). Deliberately not a HiveObject or
/// tied to storage - it's assembled fresh from existing records each time.
class ActivityItem {
  final ActivityType type;
  final String id;
  final String title;

  /// The module this activity belongs to: the note's own moduleId, or the
  /// module's own id. Lets the feed link back to - or badge by - a module
  /// regardless of which kind of record the activity came from.
  final String moduleId;

  final DateTime timestamp;

  const ActivityItem({
    required this.type,
    required this.id,
    required this.title,
    required this.moduleId,
    required this.timestamp,
  });
}
