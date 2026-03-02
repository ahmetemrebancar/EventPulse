import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için (flutter pub add intl)
import '../screens/event_detail_screen.dart'; // Bu import'u ekle

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(event.startDate);
    final isFull = event.currentAttendeesCount >= event.maxCapacity;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // Tıklandığında Detay Sayfasına Yönlendir
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(event.category, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.deepPurple.shade50,
                  ),
                  Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              // İŞTE BURASI: Hero Animasyonu Başlangıç Noktası
              Hero(
                tag: 'event_title_${event.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    event.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(event.city, style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  Icon(
                    isFull ? Icons.group_off : Icons.group, 
                    size: 16, 
                    color: isFull ? Colors.red : Colors.green
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.currentAttendeesCount} / ${event.maxCapacity}',
                    style: TextStyle(
                      color: isFull ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}