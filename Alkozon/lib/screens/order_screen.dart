import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/product_image_resolver.dart';
import 'order_detail_screen.dart';

class _OrdersViewData {
  const _OrdersViewData({
    required this.active,
    required this.finished,
    required this.delivery,
  });

  final List<OrderData> active;
  final List<OrderData> finished;
  final List<OrderData> delivery;
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialOrderId,
  });

  final int initialTabIndex;
  final int? initialOrderId;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  late Future<_OrdersViewData> _ordersFuture;
  bool _initialOrderHandled = false;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadData();
  }

  Future<_OrdersViewData> _loadData() async {
    final allOrders = await _orderService.getAllOrders();
    final assignedOrders = await _orderService.getMyDeliveryOrders(
      onlyInDelivery: false,
    );

    final active = allOrders.where(_isActive).toList();
    final deliveryOrders = assignedOrders.where(
      (o) => o.status == 'IN_DELIVERY',
    );

    final finishedMap = <int, OrderData>{
      for (final order in allOrders.where(_isFinished)) order.id: order,
      for (final order in assignedOrders.where(_isFinished)) order.id: order,
    };
    final finished = finishedMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _OrdersViewData(
      active: active,
      finished: finished,
      delivery: deliveryOrders.toList(),
    );
  }

  Future<void> _reload() async {
    final next = _loadData();
    setState(() {
      _ordersFuture = next;
    });
    await next;
  }

  Future<void> _navigateToDetail(BuildContext context, OrderData order) async {
    final updated = await Navigator.push<OrderData>(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order)),
    );

    if (updated != null) {
      await _reload();
    }
  }

  bool _isActive(OrderData order) {
    return order.status != 'CANCELLED' &&
        order.status != 'DELIVERED' &&
        order.status != 'IN_DELIVERY';
  }

  bool _isFinished(OrderData order) {
    return order.status == 'CANCELLED' || order.status == 'DELIVERED';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'SUBMITTED':
        return 'Zgłoszone';
      case 'IN_PRODUCTION':
        return 'Produkcja';
      case 'IN_PACKING':
        return 'Pakowanie';
      case 'IN_DELIVERY':
        return 'Dostawa';
      case 'DELIVERED':
        return 'Dostarczone';
      case 'CANCELLED':
        return 'Anulowane';
      default:
        return status;
    }
  }

  void _maybeOpenInitialOrder(_OrdersViewData data) {
    if (_initialOrderHandled || widget.initialOrderId == null) {
      return;
    }

    final allOrders = [...data.active, ...data.finished, ...data.delivery];
    final targetOrder = allOrders.cast<OrderData?>().firstWhere(
      (order) => order?.id == widget.initialOrderId,
      orElse: () => null,
    );
    if (targetOrder == null) {
      return;
    }

    _initialOrderHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _navigateToDetail(context, targetOrder);
    });
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
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeColor.withOpacity(0.15),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: themeColor.withOpacity(0.5), height: 2.0),
        ),
      ),
      body: FutureBuilder<_OrdersViewData>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Icon(
                    Icons.cloud_off,
                    size: 54,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nie udało się pobrać zamówień.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          final data =
              snapshot.data ??
              const _OrdersViewData(active: [], finished: [], delivery: []);

          _maybeOpenInitialOrder(data);

          return DefaultTabController(
            initialIndex: widget.initialTabIndex.clamp(0, 2),
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.green,
                  unselectedLabelColor: Color(0xFF64748B),
                  indicatorColor: Colors.green,
                  tabs: [
                    Tab(text: 'Aktywne'),
                    Tab(text: 'Zakończone'),
                    Tab(text: 'Dowozy'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOrderList(data.active),
                      _buildOrderList(data.finished),
                      _buildOrderList(data.delivery),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<OrderData> orders) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF94A3B8)),
            SizedBox(height: 10),
            Text(
              'Brak zamówień w tej zakładce',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final productsLabel = order.items.isEmpty
              ? 'Brak pozycji'
              : order.items.first.productName;
          final imagePath = ProductImageResolver.findAssetForNames(
            order.items.map((item) => item.productName),
          );

          return GestureDetector(
            onTap: () => _navigateToDetail(context, order),
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imagePath != null
                            ? Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.green,
                                  size: 34,
                                ),
                              )
                            : const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.green,
                                size: 34,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zamówienie ${order.displayNumber}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            productsLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${_statusLabel(order.status)}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
