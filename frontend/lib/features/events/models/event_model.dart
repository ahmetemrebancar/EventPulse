class EventModel {
  final int id;
  final String title;
  final String description;
  final String city;
  final String category;
  final DateTime startDate;
  final int maxCapacity;
  final int currentAttendeesCount;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.city,
    required this.category,
    required this.startDate,
    required this.maxCapacity,
    required this.currentAttendeesCount,
  });

  // JSON'dan Dart nesnesine dönüştürme (Factory Constructor)
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      category: json['category'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      maxCapacity: json['maxCapacity'] ?? 0,
      currentAttendeesCount: json['currentAttendeesCount'] ?? 0,
    );
  }
}