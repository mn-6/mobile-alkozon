import 'package:flutter/material.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<Map<String, dynamic>> _orders = [
    {'id': '#1024', 'name': 'Piwko', 'quantity': 2, 'status': 'W realizacji', 'imgSeed': 'tools'},
    {'id': '#1025', 'name': 'Winko', 'quantity': 10, 'status': 'Oczekuje', 'imgSeed': 'helmet'},
    {'id': '#1026', 'name': 'Jakaś customowa nalewka v1', 'quantity': 50, 'status': 'Wysłano', 'imgSeed': 'gloves'},
    {'id': '#1027', 'name': 'Jakaś customowa nalewka v2', 'quantity': 1, 'status': 'W realizacji', 'imgSeed': 'drill'},
    {'id': '#1028', 'name': 'Nie wiem, spirytus', 'quantity': 5, 'status': 'Oczekuje', 'imgSeed': 'shoes'},
  ];

  Future<void> _navigateToDetail(BuildContext context, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: _orders[index]),
      ),
    );

    // Jeśli odebrano nowy status, aktualizujemy listę
    if (result != null && result is String) {
      setState(() {
        _orders[index]['status'] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Colors.greenAccent;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Aktywne zamówienia",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        backgroundColor: themeColor.withOpacity(0.15),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: themeColor.withOpacity(0.5),
            height: 2.0,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];

          return GestureDetector(
            onTap: () => _navigateToDetail(context, index),
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
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://picsum.photos/seed/${order['imgSeed']}/100/100',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Zamówienie ${order['id']}",
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          Text(
                            order['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Status: ${order['status']}",
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
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