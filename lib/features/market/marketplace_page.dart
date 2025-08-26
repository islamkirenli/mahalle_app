import 'package:flutter/material.dart';

class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demoItems = List.generate(
      6,
      (i) => (
        title: "Ürün ${i + 1}",
        price: "${(i + 1) * 50} ₺",
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Mahalle Pazarı")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3 / 4,
        ),
        itemCount: demoItems.length,
        itemBuilder: (_, i) {
          final item = demoItems[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // TODO: ürün detayına git
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(item.price,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
