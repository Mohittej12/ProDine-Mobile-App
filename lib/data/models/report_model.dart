class ReportModel {
  final String id;
  final String title;
  final Map<String, dynamic> data;
  final DateTime generatedAt;

  ReportModel({
    required this.id,
    required this.title,
    required this.data,
    required this.generatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      title: json['title'],
      data: json['data'],
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'data': data,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}