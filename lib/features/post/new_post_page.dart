import 'package:flutter/material.dart';

class NewPostPage extends StatefulWidget {
  const NewPostPage({super.key});
  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyuru Yap')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _ctrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Mesaj',
                hintText: 'Mahallenle paylaş...',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Boş olamaz' : null,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Paylaş'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context); // Şimdilik mock
                  // TODO: Supabase'e post et
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
