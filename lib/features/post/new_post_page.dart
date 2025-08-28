import 'package:flutter/material.dart';

class NewPostPage extends StatefulWidget {
  const NewPostPage({super.key});
  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

enum _PostType { duyuru, etkinlik, ilan, yardim, pazarIlani, diger }
enum _ItemCondition { newItem, usedItem }

class _NewPostPageState extends State<NewPostPage> {
  final _formKey = GlobalKey<FormState>();

  // Metin / açıklama
  final _ctrl = TextEditingController();

  // Konum
  final _locCtrl = TextEditingController();

  // Pazar yeri (ilan) alanları
  final TextEditingController _priceCtrl = TextEditingController();
  final List<String> _marketCategories = const [
    'Elektronik',
    'Ev',
    'Moda',
    'Spor',
    'Kitap',
    'Hobi',
    'Diğer'
  ];
  String? _marketCategory;
  _ItemCondition _condition = _ItemCondition.usedItem;
  bool _negotiable = true;

  static const int _maxChars = 500;

  _PostType _type = _PostType.duyuru;
  bool _shareLocation = false;
  bool _allowComments = true;
  bool _urgent = false;

  // Etkinlik için
  DateTime? _eventDateTime;

  // Görsel ekleme (placeholder)
  final List<_Attachment> _attachments = [];

  @override
  void dispose() {
    _ctrl.dispose();
    _locCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final textOk =
        _ctrl.text.trim().isNotEmpty && _ctrl.text.trim().length <= _maxChars;

    final etkinlikOk =
        _type != _PostType.etkinlik || _eventDateTime != null;

    final pazarOk = _type != _PostType.pazarIlani
        ? true
        : _parsePrice(_priceCtrl.text) > 0 && _marketCategory != null;

    return textOk && etkinlikOk && pazarOk;
  }

  int _parsePrice(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  Future<void> _pickEventDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _eventDateTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _eventDateTime != null
          ? TimeOfDay.fromDateTime(_eventDateTime!)
          : TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      _eventDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _addImage() {
    setState(() {
      _attachments.add(_Attachment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        colorSeed: Colors.primaries[_attachments.length % Colors.primaries.length],
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Görsel ekleme placeholder eklendi (gerçek picker TODO).'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeImage(String id) {
    setState(() {
      _attachments.removeWhere((e) => e.id == id);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_type == _PostType.etkinlik && _eventDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Etkinlik tarihi seçiniz.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_type == _PostType.pazarIlani) {
      if (_marketCategory == null || _parsePrice(_priceCtrl.text) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pazar ilanı için kategori ve geçerli fiyat giriniz.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // TODO: Supabase’e post et:
    // - type: _type
    // - text: _ctrl.text
    // - attachments: _attachments
    // - etkinlik: _eventDateTime
    // - pazar ilani: category, price, condition, negotiable
    // - location: _shareLocation ? _locCtrl.text : null
    // - allowComments, urgent
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gönderin paylaşıldı (demoda).'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remain =
        (_maxChars - _ctrl.text.characters.length).clamp(0, _maxChars);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyuru Yap'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: FilledButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Paylaş'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
            onPressed: _canSubmit ? _submit : null,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Paylaş'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Kategori / Etiket seçimleri
            _SectionLabel('Tür'),
            Wrap(
              spacing: 8,
              runSpacing: -6,
              children: [
                _typeChip('Duyuru', _PostType.duyuru),
                _typeChip('Etkinlik', _PostType.etkinlik),
                _typeChip('İlan', _PostType.ilan),
                _typeChip('Yardım', _PostType.yardim),
                _typeChip('Pazar İlanı', _PostType.pazarIlani),
                _typeChip('Diğer', _PostType.diger),
              ],
            ),

            // Etkinlik tarihi
            if (_type == _PostType.etkinlik) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: Text(
                  _eventDateTime == null
                      ? 'Etkinlik tarihi/saatini seçin'
                      : _fmtDateTime(_eventDateTime!),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickEventDateTime,
              ),
            ],

            // Pazar yeri alanları
            if (_type == _PostType.pazarIlani) ...[
              const SizedBox(height: 12),
              _SectionLabel('Pazar İlanı'),
              DropdownButtonFormField<String>(
                value: _marketCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _marketCategories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _marketCategory = v),
                validator: (v) =>
                    v == null ? 'Kategori seçiniz' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fiyat (₺)',
                  hintText: 'Örn. 1500',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (v) =>
                    _parsePrice(v ?? '') > 0 ? null : 'Geçerli bir fiyat giriniz',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Sıfır'),
                    selected: _condition == _ItemCondition.newItem,
                    onSelected: (_) =>
                        setState(() => _condition = _ItemCondition.newItem),
                  ),
                  ChoiceChip(
                    label: const Text('İkinci el'),
                    selected: _condition == _ItemCondition.usedItem,
                    onSelected: (_) =>
                        setState(() => _condition = _ItemCondition.usedItem),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.handshake_outlined),
                title: const Text('Pazarlık payı var'),
                value: _negotiable,
                onChanged: (v) => setState(() => _negotiable = v),
              ),
            ],

            const SizedBox(height: 12),

            // Mesaj / Açıklama
            _SectionLabel(_type == _PostType.pazarIlani ? 'Açıklama' : 'Mesaj'),
            TextFormField(
              controller: _ctrl,
              maxLines: 8,
              minLines: 5,
              maxLength: _maxChars,
              decoration: InputDecoration(
                hintText: _type == _PostType.pazarIlani
                    ? 'Ürün/İlan açıklaması…'
                    : 'Mahallenle paylaş…',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Boş olamaz';
                if (t.length > _maxChars) return 'En fazla $_maxChars karakter';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$remain',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ),

            const SizedBox(height: 12),

            // Görseller
            _SectionLabel('Görseller'),
            _AttachmentRow(
              attachments: _attachments,
              onAdd: _addImage,
              onRemove: _removeImage,
            ),

            const SizedBox(height: 12),

            // Ayarlar
            _SectionLabel('Ayarlar'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.location_on_outlined),
              title: const Text('Konumu paylaş'),
              subtitle: Text(
                _shareLocation
                    ? 'Konum bilgisi gönderiye eklenecek'
                    : 'Konum ekli değil',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              value: _shareLocation,
              onChanged: (v) => setState(() => _shareLocation = v),
            ),
            if (_shareLocation)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: TextField(
                  controller: _locCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.place_rounded),
                    hintText: 'Konum açıklaması (örn. “Osmanağa Meydanı”)',
                    isDense: true,
                  ),
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.mode_comment_outlined),
              title: const Text('Yorumlara izin ver'),
              value: _allowComments,
              onChanged: (v) => setState(() => _allowComments = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.priority_high_rounded),
              title: const Text('Öncelikli göster (Acil)'),
              value: _urgent,
              onChanged: (v) => setState(() => _urgent = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, _PostType value) {
    final selected = _type == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _type = value),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  static String _fmtDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }
}

// ---- UI alt bileşenler ----

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _Attachment {
  final String id;
  final Color colorSeed;
  _Attachment({required this.id, required this.colorSeed});
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.attachments,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_Attachment> attachments;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _AddTile(onAdd: onAdd),
      ...attachments.map((a) => _ImageTile(
            id: a.id,
            colorSeed: a.colorSeed,
            onRemove: onRemove,
          )),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        child: const Center(
          child: Icon(Icons.add_photo_alternate_rounded, size: 28),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.id,
    required this.colorSeed,
    required this.onRemove,
  });

  final String id;
  final Color colorSeed;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                colorSeed.withOpacity(0.35),
                theme.colorScheme.primaryContainer.withOpacity(0.45),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.image_rounded, size: 36, color: Colors.white70),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Material(
            color: Colors.black.withOpacity(0.35),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onRemove(id),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
