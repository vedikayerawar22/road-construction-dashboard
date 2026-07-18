class Authority {
  final String name;
  final List<int> monthlyCompletion;

  Authority({required this.name, required this.monthlyCompletion});

  factory Authority.fromJson(Map<String, dynamic> json) {
    return Authority(
      name: json['name'] as String,
      monthlyCompletion: (json['monthlyCompletion'] as List)
          .map((e) => e as int)
          .toList(),
    );
  }
}
