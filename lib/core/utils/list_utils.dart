/// Splits [list] into chunks of at most [chunkSize] elements.
///
/// Useful for batching Firestore operations that have per-query limits
/// (e.g., 10-item `whereIn` limit, 500-operation batch limit).
List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
  final chunks = <List<T>>[];
  for (var i = 0; i < list.length; i += chunkSize) {
    final end = (i + chunkSize) > list.length ? list.length : i + chunkSize;
    chunks.add(list.sublist(i, end));
  }
  return chunks;
}
