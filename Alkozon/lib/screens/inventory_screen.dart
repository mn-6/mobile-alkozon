import 'package:flutter/material.dart';

import '../services/inventory_service.dart';
import '../services/product_image_resolver.dart';
import 'inventory_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  late Future<InventoryOverview> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _inventoryService.getInventory();
  }

  Future<void> _reloadInventory() async {
    final nextFuture = _inventoryService.getInventory();
    setState(() {
      _inventoryFuture = nextFuture;
    });
    await nextFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Stany magazynowe",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orangeAccent.withOpacity(0.15),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: Colors.orangeAccent, height: 2.0),
        ),
      ),
      body: FutureBuilder<InventoryOverview>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _reloadInventory,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 120),
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nie udało się pobrać stanów magazynowych.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _reloadInventory,
                      child: const Text('Spróbuj ponownie'),
                    ),
                  ),
                ],
              ),
            );
          }

          final overview = snapshot.data!;
          final items = overview.allItems;

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reloadInventory,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.inventory_outlined,
                    size: 56,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Brak pozycji w magazynie.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reloadInventory,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (overview.products.isNotEmpty) ...[
                  const _SectionHeader(title: 'Produkty'),
                  const SizedBox(height: 12),
                  ...overview.products.map(
                    (item) => _InventoryCard(
                      item: item,
                      onInventoryChanged: _reloadInventory,
                    ),
                  ),
                ],
                if (overview.rawMaterials.isNotEmpty) ...[
                  if (overview.products.isNotEmpty) const SizedBox(height: 8),
                  const _SectionHeader(title: 'Surowce'),
                  const SizedBox(height: 12),
                  ...overview.rawMaterials.map(
                    (item) => _InventoryCard(
                      item: item,
                      onInventoryChanged: _reloadInventory,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onInventoryChanged});

  final InventoryItem item;
  final Future<void> Function() onInventoryChanged;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = item.isProduct
        ? Colors.orangeAccent
        : Colors.teal;
    final IconData icon = item.isProduct
        ? Icons.inventory_2_outlined
        : Icons.science_outlined;
    final imagePath = ProductImageResolver.findAssetForName(item.name);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InventoryDetailScreen(
              item: item,
              onInventoryChanged: onInventoryChanged,
            ),
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imagePath != null
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(icon, color: accentColor, size: 36),
                        )
                      : Icon(icon, color: accentColor, size: 36),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Stan aktualny: ',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          item.quantityLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
