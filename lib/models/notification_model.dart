class ProjectNotification {
  final String id;
  final String title;
  final String message;
  final String project;
  final String time;
  bool unread;

  ProjectNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.project,
    required this.time,
    required this.unread,
  });

  factory ProjectNotification.fromJson(Map<String, dynamic> json) {
    return ProjectNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      project: json['project'] as String,
      time: json['time'] as String,
      unread: json['unread'] as bool,
    );
  }
}
