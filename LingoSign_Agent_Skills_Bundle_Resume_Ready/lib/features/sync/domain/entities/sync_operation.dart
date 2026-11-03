class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.operation,
    required this.record,
  });
  final String id;
  final String operation;
  final Map<String, Object?> record;
  Map<String, Object?> toJson() => {
    'opId': id,
    'operation': operation,
    'record': record,
  };
}

class SyncPage {
  const SyncPage({
    required this.records,
    required this.cursor,
    required this.hasMore,
  });
  final List<Map<String, Object?>> records;
  final String cursor;
  final bool hasMore;
}
