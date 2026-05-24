class TicketUploadModel {
  final String id;
  final String fileName;
  final String uploadedBy;
  final DateTime uploadedAt;

  TicketUploadModel({
    required this.id,
    required this.fileName,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory TicketUploadModel.fromJson(Map<String, dynamic> json) {
    return TicketUploadModel(
      id: json['id'],
      fileName: json['fileName'],
      uploadedBy: json['uploadedBy'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}