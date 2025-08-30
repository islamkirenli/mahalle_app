import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String _name = '';
  String _neighborhood = '';
  String _bio = '';
  bool _addressVerified = false;

  // Ayarlar
  bool _isPrivate = false;
  bool _pushNotif = false;
  bool _emailNotif = false;

  // Sayaçlar
  int _posts = 24;
  int _followers = 128;
  int _following = 76;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final row = await Supabase.instance.client
          .from('profiles')
          .select(
              'display_name, district, bio, address_verified, is_private, notif_push, notif_email')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _name = (row?['display_name'] as String?)?.trim().isNotEmpty == true
            ? row!['display_name'] as String
            : (user.email ?? 'Komşu Kullanıcı');
        _neighborhood = (row?['district'] as String?) ?? '';
        _bio = (row?['bio'] as String?) ?? '';
        _addressVerified = (row?['address_verified'] as bool?) ?? false;
        _isPrivate = (row?['is_private'] as bool?) ?? false;
        _pushNotif = (row?['notif_push'] as bool?) ?? true;
        _emailNotif = (row?['notif_email'] as bool?) ?? false;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_loading) const LinearProgressIndicator(),
          // Üst Profil Kartı
          _ProfileHeader(
            name: _name,
            neighborhood: _neighborhood,
            bio: _bio,
            addressVerified: _addressVerified,
            onEditAvatar: _onEditAvatar,
            onEditProfile: _openEditProfileSheet,
            onVerifyAddress: _openAddressSheet,
          ),

          const SizedBox(height: 16),

          // Sayaçlar
          _StatsRow(
            posts: _posts,
            followers: _followers,
            following: _following,
          ),

          const SizedBox(height: 16),

          // Hesap bölüm başlığı
          _SectionHeader(title: 'Hesap'),

          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Profili Düzenle'),
            subtitle: Text(_bio.isEmpty ? 'Biyografi yok' : _bio,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _openEditProfileSheet,
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Adres / Mahalle'),
            subtitle: Text(
              _neighborhood +
                  (_addressVerified ? '  • Doğrulandı' : '  • Doğrulanmadı'),
              style: TextStyle(
                color: _addressVerified
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _openAddressSheet,
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'Bildirimler'),

          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Push bildirimleri'),
            value: _pushNotif,
            onChanged: (v) async {
              setState(() => _pushNotif = v);
              try {
                final uid = Supabase.instance.client.auth.currentUser!.id;
                await Supabase.instance.client
                    .from('profiles')
                    .update({'notif_push': v}).eq('id', uid);
              } catch (_) {}
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.mail_outline_rounded),
            title: const Text('E-posta bildirimleri'),
            value: _emailNotif,
            onChanged: (v) async {
              setState(() => _emailNotif = v);
              try {
                final uid = Supabase.instance.client.auth.currentUser!.id;
                await Supabase.instance.client
                    .from('profiles')
                    .update({'notif_email': v}).eq('id', uid);
              } catch (_) {}
            },
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'Gizlilik & Güvenlik'),

          SwitchListTile(
            secondary: const Icon(Icons.lock_outline_rounded),
            title: const Text('Hesabı gizli yap'),
            value: _isPrivate,
            onChanged: (v) async {
              setState(() => _isPrivate = v);
              try {
                final uid = Supabase.instance.client.auth.currentUser!.id;
                await Supabase.instance.client
                    .from('profiles')
                    .update({'is_private': v}).eq('id', uid);
              } catch (_) {}
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Engellenen kullanıcılar'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _snack('Engellenen kullanıcılar sayfası yakında.'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Gizlilik politikası'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _snack('Gizlilik politikası bağlantısı yok.'),
          ),

          const SizedBox(height: 8),
          _SectionHeader(title: 'Yardım'),

          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Yardım & Geri Bildirim'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _snack('Geri bildirim ekranı yakında.'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Hakkında'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _snack('Uygulama hakkında ekranı yakında.'),
          ),

          const SizedBox(height: 16),

          // Çıkış yap
          ListTile(
            leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            title: Text('Çıkış yap',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  // ---- Actions ----

  void _onEditAvatar() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.photo_library_outlined),
                title: Text('Galeriden seç'),
              ),
              const ListTile(
                leading: Icon(Icons.photo_camera_outlined),
                title: Text('Kamera ile çek'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _snack('Avatar güncelleme yakında.');
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _name);
    final bioCtrl = TextEditingController(text: _bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Biyografi',
                prefixIcon: Icon(Icons.text_snippet_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Vazgeç'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Kaydet'),
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      final newBio = bioCtrl.text.trim();

                      try {
                        final uid =
                            Supabase.instance.client.auth.currentUser!.id;
                        final update = <String, dynamic>{};
                        if (newName.isNotEmpty)
                          update['display_name'] = newName;
                        update['bio'] = newBio; // boşsa '' yazılır, sorun değil
                        if (update.isNotEmpty) {
                          await Supabase.instance.client
                              .from('profiles')
                              .update(update)
                              .eq('id', uid);
                        }
                      } catch (_) {}

                      setState(() {
                        if (newName.isNotEmpty) _name = newName;
                        _bio = newBio;
                      });
                      if (context.mounted) Navigator.pop(context);
                      _snack('Profil güncellendi');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAddressSheet() {
    final placeCtrl = TextEditingController(text: _neighborhood);
    bool verified = _addressVerified;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
        ),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: placeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mahalle / Adres',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: verified,
                onChanged: (v) => setLocal(() => verified = v ?? false),
                title: const Text('Adres doğrulandı'),
                secondary: const Icon(Icons.verified_outlined),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Vazgeç'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Kaydet'),
                      onPressed: () async {
                        final newPlace = placeCtrl.text.trim();

                        try {
                          final uid =
                              Supabase.instance.client.auth.currentUser!.id;
                          await Supabase.instance.client
                              .from('profiles')
                              .update({
                            if (newPlace.isNotEmpty) 'district': newPlace,
                            'address_verified': verified,
                          }).eq('id', uid);
                        } catch (_) {}

                        setState(() {
                          if (newPlace.isNotEmpty) _neighborhood = newPlace;
                          _addressVerified = verified;
                        });
                        if (context.mounted) Navigator.pop(context);
                        _snack('Adres güncellendi');
                      },
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

  void _confirmLogout() async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Hesabınızdan çıkış yapmak üzeresiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

// --- Widgets ---

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.neighborhood,
    required this.bio,
    required this.addressVerified,
    required this.onEditAvatar,
    required this.onEditProfile,
    required this.onVerifyAddress,
  });

  final String name;
  final String neighborhood;
  final String bio;
  final bool addressVerified;
  final VoidCallback onEditAvatar;
  final VoidCallback onEditProfile;
  final VoidCallback onVerifyAddress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + isim + adres
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _initials(name),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: theme.colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onEditAvatar,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.edit_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (addressVerified)
                            _VerifiedBadge(color: theme.colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.place_rounded,
                              size: 16, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              neighborhood,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                bio,
                style: theme.textTheme.bodyMedium,
              ),
            ],

            const SizedBox(height: 12),

            // Aksiyonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Profili Düzenle'),
                    onPressed: onEditProfile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(
                      addressVerified
                          ? Icons.verified_rounded
                          : Icons.verified_outlined,
                    ),
                    label: Text(
                        addressVerified ? 'Adres doğrulandı' : 'Adres doğrula'),
                    onPressed: onVerifyAddress,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'K';
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    final a = parts.first.characters.take(1).toString();
    final b = parts.last.characters.take(1).toString();
    return (a + b).toUpperCase();
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text('Doğrulandı',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.posts,
    required this.followers,
    required this.following,
  });

  final int posts;
  final int followers;
  final int following;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cell(String title, int value, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell('Gönderi', posts, Icons.post_add_rounded),
        const SizedBox(width: 8),
        cell('Takipçi', followers, Icons.group_rounded),
        const SizedBox(width: 8),
        cell('Takip', following, Icons.person_add_rounded),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
