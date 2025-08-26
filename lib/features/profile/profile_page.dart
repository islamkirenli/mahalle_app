import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(radius: 36, child: Text('K')),
        const SizedBox(height: 8),
        Text('Komşu Kullanıcı',
            style: Theme.of(context).textTheme.titleLarge),
        Text('Kadıköy / Osmanağa',
            style: Theme.of(context).textTheme.bodyMedium),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Adres / Mahalle'),
          subtitle: const Text('Doğrulanmadı'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Çıkış yap'),
          onTap: () {},
        ),
      ],
    );
  }
}
