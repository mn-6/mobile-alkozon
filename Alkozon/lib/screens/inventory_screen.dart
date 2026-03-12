import 'package:flutter/material.dart';
import 'inventory_detail_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  final List<Map<String, dynamic>> _inventoryItems = const [
    {'name': 'Banan', 'current': 150, 'min': 50, 'max': 500, 'imgSeed': 'banan'},
    {'name': 'Jabłko', 'current': 45, 'min': 100, 'max': 1000, 'imgSeed': 'jablko'},
    {'name': 'Gruszka', 'current': 210, 'min': 100, 'max': 400, 'imgSeed': 'gruszka'},
    {'name': 'Pomarańcza', 'current': 320, 'min': 150, 'max': 600, 'imgSeed': 'pomarancza'},
    {'name': 'Arbuz', 'current': 12, 'min': 20, 'max': 80, 'imgSeed': 'arbuz'},
    {'name': 'Kiwi', 'current': 540, 'min': 200, 'max': 800, 'imgSeed': 'kiwi'},
    {'name': 'Truskawki', 'current': 80, 'min': 50, 'max': 150, 'imgSeed': 'truskawka'},
    {'name': 'Maliny', 'current': 15, 'min': 30, 'max': 100, 'imgSeed': 'malina'},
    {'name': 'Borówki', 'current': 15, 'min': 30, 'max': 100, 'imgSeed': 'borowka'},
    {'name': 'Borówki2', 'current': 15, 'min': 30, 'max': 100, 'imgSeed': 'borowka2'},
    {'name': 'Borówki3', 'current': 15, 'min': 30, 'max': 100, 'imgSeed': 'borowka3'},
  ];

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
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _inventoryItems.length,
        itemBuilder: (context, index) {
          final item = _inventoryItems[index];
          final bool isLowStock = item['current'] < item['min'];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InventoryDetailScreen(item: item),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://picsum.photos/seed/${item['imgSeed']}/100/100',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
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
                                "Stan aktualny: ",
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                              ),
                              Text(
                                "${item['current']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock ? Colors.redAccent : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Text(
                            "Min/Max:  ${item['min']} / ${item['max']}",
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}