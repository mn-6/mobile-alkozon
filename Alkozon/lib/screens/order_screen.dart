import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../widgets/product_thumbnail.dart';
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
  final TextEditingController _idFilterController = TextEditingController();
  bool _initialOrderHandled = false;
  String _idFilter = '';
  String _statusFilter = 'ALL';
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadData();
  }

  @override
  void dispose() {
    _idFilterController.dispose();
    super.dispose();
  }

  Future<_OrdersViewData> _loadData() async {
    final staffCombined = await _orderService.getStaffCombinedOrders();
    final allOrders = staffCombined.shopOrders;
    final customOrders = staffCombined.customOrders;
    final combined = [...allOrders, ...customOrders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final assignedOrders = await _orderService.getMyDeliveryOrders(
      onlyInDelivery: false,
    );

    final active = combined.where(_isActive).toList();
    final deliveryOrders = assignedOrders.where(
      (o) => o.status == 'IN_DELIVERY',
    );

    final finishedMap = <int, OrderData>{
      for (final order in combined.where(_isFinished))
        _orderKey(order): order,
      for (final order in assignedOrders.where(_isFinished))
        _orderKey(order): order,
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

  int _orderKey(OrderData order) {
    return order.isCustomOrder ? -order.id : order.id;
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

  List<String> get _statusFilterOptions => const [
    'ALL',
    'SUBMITTED',
    'IN_PRODUCTION',
    'IN_PACKING',
    'IN_DELIVERY',
    'DELIVERED',
    'CANCELLED',
  ];

  bool _matchesIdFilter(OrderData order) {
    final query = _idFilter.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return order.id.toString().contains(query) ||
        order.displayNumber.toLowerCase().contains(query);
  }

  List<OrderData> _applyFilters(List<OrderData> source) {
    final filtered = source.where((order) {
      if (!_matchesIdFilter(order)) {
        return false;
      }
      if (_statusFilter != 'ALL' && order.status != _statusFilter) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return _sortNewestFirst ? -cmp : cmp;
    });

    return filtered;
  }

  Widget _buildFiltersBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        children: [
          TextField(
            controller: _idFilterController,
            onChanged: (value) {
              setState(() {
                _idFilter = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Filtruj po ID / numerze zamówienia',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: _statusFilterOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status == 'ALL' ? 'Wszystkie' : _statusLabel(status),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _statusFilter = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  initialValue: _sortNewestFirst,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Sortowanie',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Od najnowszych'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Od najstarszych'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _sortNewestFirst = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                _buildFiltersBar(),
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
                      _buildOrderList(_applyFilters(data.active)),
                      _buildOrderList(_applyFilters(data.finished)),
                      _buildOrderList(_applyFilters(data.delivery)),
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
              ? (order.description?.trim().isNotEmpty == true
                    ? order.description!.trim()
                    : 'Brak pozycji')
              : order.items.first.productName;
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
                    ProductThumbnail(
                      productNames: order.items.map((item) => item.productName),
                      accentColor: Colors.green,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.isCustomOrder ? 'Zlecenie specjalne' : 'Zamówienie'} ${order.displayNumber}',
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
