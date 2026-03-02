import 'event_model.dart';

// Temel EventModel'den miras alıp detay özelliklerini ekliyoruz
class EventDetailModel extends EventModel {
  final int commentsCount;
  final List<String> recentComments;

  EventDetailModel({
    required super.id,
    required super.title,
    required super.description,
    required super.city,
    required super.category,
    required super.startDate,
    required super.maxCapacity,
    required super.currentAttendeesCount,
    required this.commentsCount,
    required this.recentComments,
  });

  factory EventDetailModel.fromJson(Map<String, dynamic> json) {
    return EventDetailModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      category: json['category'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      maxCapacity: json['maxCapacity'] ?? 0,
      currentAttendeesCount: json['currentAttendeesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      recentComments: List<String>.from(json['recentComments'] ?? []),
    );
  }
}