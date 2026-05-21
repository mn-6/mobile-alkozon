import 'package:flutter/material.dart';

import 'package:alkozon/core/di/injection_container.dart';
import 'package:alkozon/core/localization/user_message.dart';
import 'package:alkozon/core/widgets/app_status_panel.dart';
import 'package:alkozon/features/inventory/domain/entities/inventory_item.dart';
import 'package:alkozon/core/widgets/product_thumbnail.dart';
import 'package:alkozon/features/inventory/presentation/pages/inventory_detail_page.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _inventoryRepository = InjectionContainer.I.inventoryRepository;
  late Future<InventoryOverview> _inventoryFuture;
  final TextEditingController _nameFilterController = TextEditingController();
  String _nameFilter = '';

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _inventoryRepository.getInventory();
  }

  @override
  void dispose() {
    _nameFilterController.dispose();
    super.dispose();
  }

  Future<void> _reloadInventory() async {
    final nextFuture = _inventoryRepository.getInventory();
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
        backgroundColor: Colors.orangeAccent.withValues(alpha: 0.15),
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
                children: [
                  AppStatusPanel(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nie udało się pobrać stanów magazynowych',
                    message: UserMessage.fromError(snapshot.error),
                    actionLabel: 'Spróbuj ponownie',
                    onAction: _reloadInventory,
                  ),
                ],
              ),
            );
          }

          final overview = snapshot.data!;
          final query = _nameFilter.trim().toLowerCase();
          final filteredProducts = overview.products.where((item) {
            if (query.isEmpty) return true;
            return item.name.toLowerCase().contains(query);
          }).toList();
          final filteredRawMaterials = overview.rawMaterials.where((item) {
            if (query.isEmpty) return true;
            return item.name.toLowerCase().contains(query);
          }).toList();
          final items = [...filteredProducts, ...filteredRawMaterials];

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
                TextField(
                  controller: _nameFilterController,
                  onChanged: (value) {
                    setState(() {
                      _nameFilter = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Filtruj po nazwie produktu',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredProducts.isNotEmpty) ...[
                  const _SectionHeader(title: 'Produkty'),
                  const SizedBox(height: 12),
                  ...filteredProducts.map(
                    (item) => _InventoryCard(
                      item: item,
                      onInventoryChanged: _reloadInventory,
                    ),
                  ),
                ],
                if (filteredRawMaterials.isNotEmpty) ...[
                  if (filteredProducts.isNotEmpty) const SizedBox(height: 8),
                  const _SectionHeader(title: 'Surowce'),
                  const SizedBox(height: 12),
                  ...filteredRawMaterials.map(
                    (item) => _InventoryCard(
                      item: item,
                      onInventoryChanged: _reloadInventory,
                    ),
                  ),
                ],
                if (items.isEmpty) ...[
                  const SizedBox(height: 36),
                  const Center(
                    child: Text(
                      'Brak wyników dla podanego filtra.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
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
              ProductThumbnail(
                productNames: [item.name],
                accentColor: accentColor,
                fallbackIcon: icon,
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
