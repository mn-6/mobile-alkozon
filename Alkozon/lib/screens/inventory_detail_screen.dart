import 'package:flutter/material.dart';

class InventoryDetailScreen extends StatelessWidget {

  final Map<String, dynamic> item;

  const InventoryDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = item['current'] < item['min'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          item['name'],
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent.withOpacity(0.15),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: Colors.orangeAccent,
            height: 2.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://picsum.photos/seed/${item['imgSeed']}/300/300',
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 160,
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 24),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Stan aktualny - ${item['current']}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? Colors.redAccent : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Min - ${item['min']}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Max - ${item['max']}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
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