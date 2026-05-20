enum PostureStatus { normal, warning, danger }

class PostureEvent {
  final DateTime timestamp;
  final PostureStatus status;

  const PostureEvent({required this.timestamp, required this.status});
}
