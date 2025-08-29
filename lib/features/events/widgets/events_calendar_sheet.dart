import 'package:flutter/material.dart';

/// Etkinlik takvimi alt sayfası (bottom sheet)
/// [events]: (title, date, location, cover, tags) tuple listesi (events_page.dart'taki demoEvents yapısı)
class EventsCalendarSheet extends StatefulWidget {
  const EventsCalendarSheet({super.key, required this.events});

  final List<({
    String title,
    String date,
    String location,
    String cover,
    List<String> tags,
  })> events;

  @override
  State<EventsCalendarSheet> createState() => _EventsCalendarSheetState();
}

class _EventsCalendarSheetState extends State<EventsCalendarSheet> {
  late final Map<DateTime, List<(String title, String time)>> _eventsByDay;
  late DateTime _month; // gösterilen ay
  DateTime? _selectedDay;

  static const _monthNamesTr = [
    '', 'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
    'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'
  ];
  static const _weekdaysTr = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz']; // Pazartesi başlangıç

  @override
  void initState() {
    super.initState();
    _eventsByDay = _buildIndex(widget.events);

    final firstKey = _eventsByDay.keys.isNotEmpty
        ? (_eventsByDay.keys.toList()..sort()).first
        : DateTime.now();
    _month = DateTime(firstKey.year, firstKey.month, 1);
  }

  Map<DateTime, List<(String title, String time)>> _buildIndex(
    List<({
      String title,
      String date,
      String location,
      String cover,
      List<String> tags,
    })> evts,
  ) {
    final map = <DateTime, List<(String, String)>>{};
    for (final e in evts) {
      // "12/01/2024 • 19:00" -> "12/01/2024" + "19:00"
      final parts = e.date.split('•');
      final datePart = parts.first.trim(); // 12/01/2024
      final timePart = parts.length > 1 ? parts[1].trim() : '';

      final d = datePart.split('/');
      final day = int.parse(d[0]);
      final month = int.parse(d[1]);
      final year = int.parse(d[2]);

      final key = DateTime(year, month, day); 
      (map[key] ??= []).add((e.title, timePart));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; 
    final leadingEmpty = (firstWeekday - 1) % 7; 

    Color dotColor(bool isSelected) =>
        isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Önceki ay',
                    onPressed: () {
                      setState(() {
                        _month = DateTime(_month.year, _month.month - 1, 1);
                        _selectedDay = null;
                      });
                    },
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_monthNamesTr[_month.month]} ${_month.year}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sonraki ay',
                    onPressed: () {
                      setState(() {
                        _month = DateTime(_month.year, _month.month + 1, 1);
                        _selectedDay = null;
                      });
                    },
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Hafta başlıkları
              Row(
                children: List.generate(7, (i) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        _weekdaysTr[i],
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.hintColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),

              // Gün ızgarası
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: leadingEmpty + daysInMonth,
                itemBuilder: (_, idx) {
                  if (idx < leadingEmpty) {
                    return const SizedBox.shrink();
                  }
                  final day = idx - leadingEmpty + 1;
                  final date = DateTime(_month.year, _month.month, day);
                  final hasEvents = _eventsByDay.containsKey(date);
                  final isSelected = _selectedDay != null &&
                      _selectedDay!.year == date.year &&
                      _selectedDay!.month == date.month &&
                      _selectedDay!.day == date.day;

                  // --- OVERFLOW FIXES ---
                  // 1) Daha az dikey padding
                  // 2) Metin boyutunu bir seviye küçült (bodyMedium)
                  // 3) Nokta ile sayı arasındaki boşluğu azalt
                  final bg = isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedDay = date);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasEvents
                              ? theme.colorScheme.primary.withOpacity(.35)
                              : theme.colorScheme.outlineVariant.withOpacity(.35),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4), // ↓ 6 → 4
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // ← overflow’u önler
                        children: [
                          Text(
                            '$day',
                            style: theme.textTheme.bodyMedium?.copyWith( // ↓ bodyLarge → bodyMedium
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w700 : null,
                              height: 1.0, // satır yüksekliğini sıkı tut
                            ),
                          ),
                          const SizedBox(height: 2), // ↓ 4 → 2
                          if (hasEvents)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: dotColor(isSelected),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Seçili günün etkinlik listesi
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedDay == null
                      ? 'Bir gün seçin'
                      : 'Etkinlikler — ${_selectedDay!.day.toString().padLeft(2, '0')}.${_selectedDay!.month.toString().padLeft(2, '0')}.${_selectedDay!.year}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),

              if (_selectedDay != null &&
                  (_eventsByDay[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]?.isEmpty ?? true))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Bu gün için etkinlik bulunmuyor.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                ),

              if (_selectedDay != null &&
                  (_eventsByDay[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]?.isNotEmpty ?? false))
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _eventsByDay[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]!.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1, color: theme.colorScheme.outlineVariant.withOpacity(.4),
                  ),
                  itemBuilder: (_, i) {
                    final (title, time) =
                        _eventsByDay[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]![i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                        child: Icon(Icons.event, color: theme.colorScheme.primary),
                      ),
                      title: Text(title, style: theme.textTheme.bodyLarge),
                      subtitle: Text(
                        time.isEmpty ? 'Saat bilgisi yok' : time,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).pop(); // takvim sheet'ini kapat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('"$title" açılıyor…')),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
