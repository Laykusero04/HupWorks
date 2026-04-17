import 'package:equatable/equatable.dart';

class ServiceRequirement extends Equatable {
  final String id;
  final String serviceId;
  final String question;
  final bool isRequired;
  final DateTime? createdAt;

  const ServiceRequirement({
    required this.id,
    required this.serviceId,
    required this.question,
    this.isRequired = true,
    this.createdAt,
  });

  factory ServiceRequirement.fromJson(Map<String, dynamic> json) {
    return ServiceRequirement(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      question: json['question'] as String,
      isRequired: (json['is_required'] as bool?) ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'service_id': serviceId,
        'question': question,
        'is_required': isRequired,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, serviceId, question, isRequired, createdAt];
}
