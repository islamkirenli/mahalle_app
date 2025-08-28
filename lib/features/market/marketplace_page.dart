import 'package:flutter/material.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  // Demo veri modeli
  final List<_Product> _allProducts = List.generate(16, (i) {
    final cats = ['Elektronik', 'Ev', 'Moda', 'Spor', 'Kitap', 'Hobi'];
    return _Product(
      id: i,
      title: 'Ürün ${i + 1}',
      price: (i + 1) * 75,
      category: cats[i % cats.length],
      isNew: i % 3 == 0,
      location: ['Osmanağa', 'Moda', 'Yeldeğirmeni', 'Fenerbahçe'][i % 4],
      postedAgo: '${(i % 6) + 1}g', // 1–6 gün önce
    );
  });

  final List<String> _categories = [
    'Tümü',
    'Elektronik',
    'Ev',
    'Moda',
    'Spor',
    'Kitap',
    'Hobi',
  ];

  String _selectedCategory = 'Tümü';
  bool _onlyNew = false;

  // Sıralama seçenekleri
  SortOption _sort = SortOption.newest;

  // Favoriler
  final Set<int> _favorites = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    // Filtreleme
    Iterable<_Product> list = _allProducts;

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => p.title.toLowerCase().contains(q));
    }
    if (_selectedCategory != 'Tümü') {
      list = list.where((p) => p.category == _selectedCategory);
    }
    if (_onlyNew) {
      list = list.where((p) => p.isNew);
    }

    // Sıralama
    final products = list.toList()
      ..sort((a, b) {
        switch (_sort) {
          case SortOption.priceLowHigh:
            return a.price.compareTo(b.price);
          case SortOption.priceHighLow:
            return b.price.compareTo(a.price);
          case SortOption.newest:
            return b.id.compareTo(a.id); // id ~ eklenme sırası
        }
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahalle Pazarı'),
        actions: [
          // Sıralama menüsü
          PopupMenuButton<SortOption>(
            tooltip: 'Sırala',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              _sortItem(SortOption.newest, 'En yeni'),
              _sortItem(SortOption.priceLowHigh, 'Fiyat (Artan)'),
              _sortItem(SortOption.priceHighLow, 'Fiyat (Azalan)'),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Arama kutusu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SearchField(
              controller: _searchCtrl,
              hintText: 'Pazarda ara…',
              onChanged: (_) => setState(() {}),
              onClearTap: () {
                _searchCtrl.clear();
                setState(() {});
              },
            ),
          ),

          // Kategori çipleri (yatay kaydırma)
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Ürün ızgarası
          Expanded(
            child: LayoutBuilder(
              builder: (_, c) {
                final w = c.maxWidth;
                final cross = w >= 1100
                    ? 4
                    : w >= 800
                        ? 3
                        : 2;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) {
                    final p = products[i];
                    final isFav = _favorites.contains(p.id);
                    return _ProductCard(
                      product: p,
                      isFavorite: isFav,
                      onTap: () {
                        // TODO: Ürün detay sayfasına git
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('“${p.title}” seçildi (detay sayfası yok).'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onToggleFavorite: () {
                        setState(() {
                          if (isFav) {
                            _favorites.remove(p.id);
                          } else {
                            _favorites.add(p.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- yardımcılar ---

  PopupMenuItem<SortOption> _sortItem(SortOption v, String label) {
    return PopupMenuItem(
      value: v,
      child: Row(
        children: [
          Icon(
            v == _sort
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

enum SortOption { newest, priceLowHigh, priceHighLow }

// --- Basit ürün modeli ---
class _Product {
  final int id;
  final String title;
  final int price; // ₺
  final String category;
  final bool isNew;
  final String location;
  final String postedAgo; // “2g” gibi

  _Product({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.isNew,
    required this.location,
    required this.postedAgo,
  });
}

// --- Arama alanı ---
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClearTap,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Temizle',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClearTap,
              ),
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// --- Ürün kartı ---
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final _Product product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Görsel alanı
            Expanded(
              child: Stack(
                children: [
                  // Placeholder görsel
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer.withOpacity(0.35),
                            theme.colorScheme.secondaryContainer.withOpacity(0.45),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.image_rounded, size: 56, color: Colors.white70),
                      ),
                    ),
                  ),
                  // Favori düğmesi
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withOpacity(0.20),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onToggleFavorite,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? Colors.redAccent : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // “Yeni” rozeti
                  if (product.isNew)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Yeni',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bilgi alanı
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₺${product.price}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.place_rounded, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(product.location,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text('${product.postedAgo} önce',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
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
