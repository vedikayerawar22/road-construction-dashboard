class ConstructionStage {
  final String name;
  final int progress;

  ConstructionStage({required this.name, required this.progress});

  factory ConstructionStage.fromJson(Map<String, dynamic> json) {
    return ConstructionStage(
      name: json['name'] as String,
      progress: json['progress'] as int,
    );
  }
}

class TimelineEvent {
  final DateTime date;
  final String event;

  TimelineEvent({required this.date, required this.event});

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      date: DateTime.parse(json['date'] as String),
      event: json['event'] as String,
    );
  }
}

class MaterialItem {
  final String name;
  final String quantity;
  final String status;

  MaterialItem({
    required this.name,
    required this.quantity,
    required this.status,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      status: json['status'] as String,
    );
  }
}

enum ProjectStatus { completed, inProgress, delayed }

extension ProjectStatusX on ProjectStatus {
  static ProjectStatus fromString(String value) {
    switch (value) {
      case 'Completed':
        return ProjectStatus.completed;
      case 'Delayed':
        return ProjectStatus.delayed;
      default:
        return ProjectStatus.inProgress;
    }
  }

  String get label {
    switch (this) {
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.delayed:
        return 'Delayed';
      case ProjectStatus.inProgress:
        return 'In Progress';
    }
  }
}

class Project {
  final String id;
  final String name;
  final String district;
  final String authority;
  final String contractor;
  final int completionPercent;
  final ProjectStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double budgetCr;
  final double spentCr;
  final double lengthKm;
  final int delayDays;
  final List<ConstructionStage> stages;
  final List<TimelineEvent> timeline;
  final List<MaterialItem> materials;

  Project({
    required this.id,
    required this.name,
    required this.district,
    required this.authority,
    required this.contractor,
    required this.completionPercent,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.budgetCr,
    required this.spentCr,
    required this.lengthKm,
    required this.delayDays,
    required this.stages,
    required this.timeline,
    required this.materials,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      district: json['district'] as String,
      authority: json['authority'] as String,
      contractor: json['contractor'] as String,
      completionPercent: json['completionPercent'] as int,
      status: ProjectStatusX.fromString(json['status'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      budgetCr: (json['budgetCr'] as num).toDouble(),
      spentCr: (json['spentCr'] as num).toDouble(),
      lengthKm: (json['lengthKm'] as num).toDouble(),
      delayDays: json['delayDays'] as int,
      stages: (json['stages'] as List)
          .map((e) => ConstructionStage.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline: (json['timeline'] as List)
          .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      materials: (json['materials'] as List)
          .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
