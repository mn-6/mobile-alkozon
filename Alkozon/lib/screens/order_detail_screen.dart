import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/product_image_resolver.dart';
import 'order_navigation_map_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderData order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  static const List<String> _flow = [
    'SUBMITTED',
    'IN_PRODUCTION',
    'IN_PACKING',
    'IN_DELIVERY',
    'DELIVERED',
  ];

  late String _currentStatus;
  late List<String> _availableStatuses;
  bool _isSaving = false;

  bool get _isFinalStatus =>
      widget.order.status == 'DELIVERED' || widget.order.status == 'CANCELLED';

  bool get _isNavigationMode => widget.order.status == 'IN_DELIVERY';

  bool get _canChangeStatus =>
      !_isFinalStatus && !_isNavigationMode && _availableStatuses.length > 1;

  @override
  void initState() {
    super.initState();

    final initialStatus = widget.order.status;
    _availableStatuses = _nextStatusesFor(initialStatus);
    _currentStatus = _availableStatuses.contains(initialStatus)
        ? initialStatus
        : _availableStatuses.first;
  }

  List<String> _nextStatusesFor(String currentStatus) {
    if (currentStatus == 'CANCELLED') {
      return const ['CANCELLED'];
    }
    final index = _flow.indexOf(currentStatus);
    if (index < 0) {
      return const [
        'SUBMITTED',
        'IN_PRODUCTION',
        'IN_PACKING',
        'IN_DELIVERY',
        'DELIVERED',
      ];
    }
    return _flow.sublist(index);
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

  String _formatMoney(double amount) {
    return '${amount.toStringAsFixed(2)} PLN';
  }

  String _formatUnitPrice(double amount) {
    return '${amount.toStringAsFixed(2)} PLN / szt.';
  }

  String _deliveryAddressForNavigation() {
    final structured = widget.order.deliveryDetails;
    if (structured != null) {
      final parts = <String>[
        if ((structured.streetAddress ?? '').trim().isNotEmpty)
          structured.streetAddress!.trim(),
        if ((structured.postalCode ?? '').trim().isNotEmpty)
          structured.postalCode!.trim(),
        if ((structured.city ?? '').trim().isNotEmpty) structured.city!.trim(),
        if ((structured.country ?? '').trim().isNotEmpty)
          structured.country!.trim(),
      ];
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }
    return widget.order.deliveryAddress?.trim() ?? '';
  }

  Future<void> _openNavigation() async {
    final address = _deliveryAddressForNavigation();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak adresu do nawigacji.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderNavigationMapScreen(
          address: address,
          orderId: widget.order.id,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Future<void> _saveStatus() async {
    if (_isSaving) return;
    if (!_canChangeStatus) return;
    if (_currentStatus == widget.order.status) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await _orderService.patchStatus(
        id: widget.order.id,
        status: _currentStatus,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zmienić statusu: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Colors.greenAccent;
    final headerImagePath = ProductImageResolver.findAssetForNames(
      widget.order.items.map((item) => item.productName),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Szczegóły ${widget.order.displayNumber}',
          style: const TextStyle(
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.green.withOpacity(0.12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: headerImagePath != null
                        ? Image.asset(
                            headerImagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag_outlined,
                              size: 54,
                              color: Colors.green,
                            ),
                          )
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            size: 54,
                            color: Colors.green,
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
                        widget.order.items.isNotEmpty
                            ? widget.order.items.first.productName
                            : 'Brak pozycji',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Wartość: ${_formatMoney(widget.order.totalAmount)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              title: 'Dane zamówienia',
              rows: [
                MapEntry('ID', widget.order.id.toString()),
                MapEntry('Numer zamówienia', widget.order.displayNumber),
                MapEntry(
                  'Numer klienta',
                  widget.order.clientOrderNumber ?? '-',
                ),
                MapEntry('ID klienta', widget.order.customerId.toString()),
                MapEntry('Status', _statusLabel(widget.order.status)),
                MapEntry('Adres dostawy', widget.order.deliveryAddress ?? '-'),
                MapEntry('Utworzono', _formatDateTime(widget.order.createdAt)),
                MapEntry(
                  'Dostarczono',
                  widget.order.deliveredAt != null
                      ? _formatDateTime(widget.order.deliveredAt!)
                      : '-',
                ),
                MapEntry('Wartość', _formatMoney(widget.order.totalAmount)),
              ],
            ),
            if (widget.order.deliveryDetails != null) ...[
              const SizedBox(height: 18),
              _buildInfoCard(
                title: 'Szczegóły dostawy',
                rows: [
                  MapEntry(
                    'Odbiorca',
                    widget.order.deliveryDetails!.recipientName ?? '-',
                  ),
                  MapEntry(
                    'Ulica',
                    widget.order.deliveryDetails!.streetAddress ?? '-',
                  ),
                  MapEntry('Miasto', widget.order.deliveryDetails!.city ?? '-'),
                  MapEntry(
                    'Kod pocztowy',
                    widget.order.deliveryDetails!.postalCode ?? '-',
                  ),
                  MapEntry(
                    'Kraj',
                    widget.order.deliveryDetails!.country ?? '-',
                  ),
                  MapEntry(
                    'Uwagi',
                    widget.order.deliveryDetails!.deliveryNotes ?? '-',
                  ),
                  MapEntry(
                    'Płatność',
                    widget.order.deliveryDetails!.paymentMethod ?? '-',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Pozycje zamówienia:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            ...widget.order.items.map((item) {
              final itemImagePath = ProductImageResolver.findAssetForName(
                item.productName,
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: itemImagePath != null
                            ? Image.asset(
                                itemImagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              )
                            : const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.green,
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text('Produkt ID: ${item.productId}'),
                          Text('Ilość: ${item.quantity}'),
                          Text(
                            'Cena jednostkowa: ${_formatUnitPrice(item.unitPrice)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            if (_isNavigationMode) ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _openNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  label: const Text(
                    'Nawiguj',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dla zamówień w dostawie statusu nie można już zmienić. Użyj nawigacji, aby dotrzeć pod adres.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (_canChangeStatus) ...[
              const Text(
                'Zmień status zamówienia:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currentStatus,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down_circle_outlined,
                      color: Colors.green,
                    ),
                    items: _availableStatuses.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(_statusLabel(value)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _currentStatus = newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving || _currentStatus == widget.order.status
                      ? null
                      : _saveStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ZAPISZ ZMIANY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ] else ...[
              const Text(
                'To zamówienie ma status końcowy i nie można już zmienić jego statusu.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<MapEntry<String, String>> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.key,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
