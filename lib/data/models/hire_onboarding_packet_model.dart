import 'package:equatable/equatable.dart';

class HireOnboardingSection extends Equatable {
  final String key;
  final String title;
  final String body;

  const HireOnboardingSection({
    required this.key,
    required this.title,
    required this.body,
  });

  factory HireOnboardingSection.fromJson(Map<String, dynamic> json) {
    return HireOnboardingSection(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'body': body,
      };

  HireOnboardingSection copyWith({String? title, String? body}) {
    return HireOnboardingSection(
      key: key,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  static List<HireOnboardingSection> defaultSections() => const [
        HireOnboardingSection(key: 'where', title: 'Where to go', body: ''),
        HireOnboardingSection(key: 'when', title: 'When to arrive', body: ''),
        HireOnboardingSection(key: 'who', title: 'Who to contact', body: ''),
        HireOnboardingSection(key: 'access', title: 'Building access', body: ''),
        HireOnboardingSection(key: 'rules', title: 'Site rules', body: ''),
        HireOnboardingSection(
          key: 'attendance',
          title: 'Attendance',
          body: '',
        ),
        HireOnboardingSection(key: 'emergency', title: 'Emergency', body: ''),
      ];

  @override
  List<Object?> get props => [key, title, body];
}

class HireOnboardingPacket extends Equatable {
  final String id;
  final String orderId;
  final String clientId;
  final String sellerId;
  final String status;
  final bool requiredAck;
  final List<HireOnboardingSection> sections;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool acknowledged;

  const HireOnboardingPacket({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.sellerId,
    required this.status,
    required this.requiredAck,
    required this.sections,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.acknowledged = false,
  });

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';

  factory HireOnboardingPacket.fromJson(
    Map<String, dynamic> json, {
    bool acknowledged = false,
  }) {
    final rawSections = json['sections'];
    final List<HireOnboardingSection> sections;
    if (rawSections is List) {
      sections = rawSections
          .whereType<Map>()
          .map((e) => HireOnboardingSection.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      sections = HireOnboardingSection.defaultSections();
    }

    return HireOnboardingPacket(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      clientId: json['client_id'] as String,
      sellerId: json['seller_id'] as String,
      status: json['status'] as String? ?? 'draft',
      requiredAck: json['required_ack'] as bool? ?? true,
      sections: sections.isEmpty ? HireOnboardingSection.defaultSections() : sections,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      acknowledged: acknowledged,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'client_id': clientId,
        'seller_id': sellerId,
        'status': status,
        'required_ack': requiredAck,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        orderId,
        status,
        sections,
        publishedAt,
        acknowledged,
      ];
}
