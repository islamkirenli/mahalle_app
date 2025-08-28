import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demoEvents = List.generate(
      6,
      (i) => (
        title: "Mahalle Buluşması ${i + 1}",
        date: "12/0${(i % 9) + 1}/2024 • 19:00",
        location: "Mahalle Parkı",
        cover:
            "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1200&q=80",
        tags: <String>["Açık Hava", "Komşuluk", if (i.isEven) "Ücretsiz"],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Etkinlikler"),
        actions: [
          IconButton(
            tooltip: "Takvim",
            onPressed: () {},
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // Arama & filtre çubuğu
          _SearchBar(onChanged: (v) {
            // TODO: arama
          }),
          const SizedBox(height: 12),

          // Etkinlik kartları
          ...demoEvents.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventCard(
                  title: e.title,
                  date: e.date,
                  location: e.location,
                  cover: e.cover,
                  tags: e.tags,
                  onTap: () {
                    // TODO: etkinlik detayına git
                  },
                  onJoin: () {
                    // TODO: katıl
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Katılım bildirildi.")),
                    );
                  },
                  onShare: () {
                    // TODO: paylaş
                  },
                ),
              )),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Etkinlik ara…",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.date,
    required this.location,
    required this.cover,
    required this.tags,
    required this.onTap,
    required this.onJoin,
    required this.onShare,
  });

  final String title;
  final String date;
  final String location;
  final String cover;
  final List<String> tags;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kapak görseli + tarih rozeti
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Ink.image(
                    image: NetworkImage(cover),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          date,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),

            // Konum
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 18, color: theme.hintColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Etiketler
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children: tags
                      .map((t) => Chip(
                            label: Text(t),
                            visualDensity: VisualDensity.compact,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 8),

            // Aksiyon barı
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Katıl"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share),
                    label: const Text("Paylaş"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
