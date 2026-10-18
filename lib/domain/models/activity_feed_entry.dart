/// 친구 활동 피드에 뜨는 항목 하나 — "누가 뭘 했다"는 짧은 한 줄.
class ActivityFeedEntry {
  const ActivityFeedEntry({
    required this.uid,
    required this.message,
    required this.at,
  });

  final String uid;
  final String message;
  final DateTime at;
}
