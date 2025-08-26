import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demoEvents = List.generate(
      5,
      (i) => (
        title: "Etkinlik ${i + 1}",
        date: "12/0${i + 1}/2024",
        location: "Mahalle Parkı",
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Etkinlikler")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demoEvents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final e = demoEvents[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.event, color: Colors.blue),
              title: Text(e.title),
              subtitle: Text("${e.date} — ${e.location}"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: etkinlik detay sayfasına yönlendir
              },
            ),
          );
        },
      ),
    );
  }
}
