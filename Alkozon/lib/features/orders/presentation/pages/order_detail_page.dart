import 'package:flutter/material.dart';
import 'package:alkozon/core/di/injection_container.dart';
import 'package:alkozon/core/localization/user_message.dart';
import 'package:alkozon/core/connectivity/connectivity_failure_handler.dart';
import 'package:alkozon/core/widgets/app_snackbar.dart';
import 'package:alkozon/features/orders/domain/entities/order.dart';
import 'package:alkozon/core/widgets/horizontal_scroll_text.dart';
import 'package:alkozon/core/widgets/product_thumbnail.dart';
import 'package:alkozon/features/orders/presentation/pages/order_navigation_map_page.dart';
import 'package:alkozon/features/orders/presentation/utils/custom_order_preferences_formatter.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderData order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderRepository = InjectionContainer.I.orderRepository;
  final _inventoryRepository = InjectionContainer.I.inventoryRepository;
  static const List<String> _flow = [
    'SUBMITTED',
    'IN_PRODUCTION',
    'IN_PACKING',
    'IN_DELIVERY',
    'DELIVERED',
  ];
  bool _isSaving = false;

  bool get _isFinalStatus =>
      widget.order.status == 'DELIVERED' || widget.order.status == 'CANCELLED';

  bool get _isNavigationMode => widget.order.status == 'IN_DELIVERY';

  String? get _nextStatus {
    if (_isFinalStatus || _isNavigationMode) return null;
    final index = _flow.indexOf(widget.order.status);
    if (index < 0 || index >= _flow.length - 1) return null;
    return _flow[index + 1];
  }

  bool get _canAdvanceStatus => _nextStatus != null;

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
      AppSnackbar.show(
        context,
        message: 'Brak adresu do nawigacji.',
        success: false,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderNavigationMapScreen(
          address: address,
          orderId: widget.order.id,
          isCustomOrder: widget.order.isCustomOrder,
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

  Future<bool> _confirmStandardAdvance(String nextStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Potwierdzenie'),
        content: Text(
          'Przenieść zamówienie ${widget.order.displayNumber} na etap ${_statusLabel(nextStatus)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Nie'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tak'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<bool> _confirmCustomProductionAdvance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Produkt specjalny'),
        content: const Text(
          'Uwaga! Produkt specjalny. Przed zmianą statusu upewnij się, '
          'że ręcznie zmieniłeś ilość zużytych produktów w zakładce Stany Magazynowe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Potwierdź'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  bool get _shouldDeductInventory =>
      !widget.order.isCustomOrder &&
      widget.order.status == 'SUBMITTED';

  Future<void> _deductInventoryForProduction() async {
    for (final item in widget.order.items) {
      await _inventoryRepository.consumeProductById(
        productId: item.productId,
        quantity: item.quantity,
      );
    }
  }

  Future<void> _advanceStatus(String nextStatus) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_shouldDeductInventory && nextStatus == 'IN_PRODUCTION') {
        await _deductInventoryForProduction();
      }

      final updated = widget.order.isCustomOrder
          ? await _orderRepository.patchCustomStatus(
              id: widget.order.id,
              status: nextStatus,
            )
          : await _orderRepository.patchStatus(
              id: widget.order.id,
              status: nextStatus,
            );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      if (!ConnectivityFailureHandler.report(e)) {
        AppSnackbar.show(
          context,
          message:
              'Nie udało się zmienić statusu: ${UserMessage.fromError(e)}',
          success: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _onNextStepPressed() async {
    final nextStatus = _nextStatus;
    if (nextStatus == null || _isSaving) return;

    final isCustomProductionStep = widget.order.isCustomOrder &&
        widget.order.status == 'SUBMITTED' &&
        nextStatus == 'IN_PRODUCTION';

    final confirmed = isCustomProductionStep
        ? await _confirmCustomProductionAdvance()
        : await _confirmStandardAdvance(nextStatus);

    if (!confirmed || !mounted) return;
    await _advanceStatus(nextStatus);
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Colors.greenAccent;
    final nextStatus = _nextStatus;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.order.isCustomOrder ? 'Szczegóły zlecenia' : 'Szczegóły'} ${widget.order.displayNumber}',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeColor.withValues(alpha: 0.15),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: themeColor.withValues(alpha: 0.5), height: 2.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumbnail(
                  productNames:
                      widget.order.items.map((item) => item.productName),
                  size: 140,
                  borderRadius: 16,
                  accentColor: Colors.green,
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
                            : (widget.order.description?.trim().isNotEmpty ==
                                    true
                                ? widget.order.description!.trim()
                                : 'Brak pozycji'),
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
                if (widget.order.isCustomOrder)
                  MapEntry(
                    'Typ',
                    'Zlecenie specjalne',
                  ),
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
            if (widget.order.isCustomOrder) ...[
              const SizedBox(height: 18),
              _buildInfoCard(
                title: 'Opis zlecenia specjalnego',
                rows: [
                  MapEntry(
                    'Opis',
                    widget.order.description?.trim().isNotEmpty == true
                        ? widget.order.description!.trim()
                        : '-',
                  ),
                  MapEntry(
                    'Przypisane do',
                    widget.order.assignedToId?.toString() ?? '-',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildPreferencesCard(
                CustomOrderPreferencesFormatter.displayRows(
                  widget.order.preferences,
                ),
              ),
            ],
            if (widget.order.deliveryDetails != null &&
                !widget.order.isCustomOrder) ...[
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
            if (!widget.order.isCustomOrder) ...[
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
                      ProductThumbnail(
                        productNames: [item.productName],
                        size: 52,
                        borderRadius: 10,
                        accentColor: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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
            ],
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
            ] else if (_canAdvanceStatus) ...[
              Container(
                width: double.infinity,
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
                      'Aktualny etap: ${_statusLabel(widget.order.status)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Następny etap: ${_statusLabel(nextStatus!)}',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _onNextStepPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                  label: Text(
                    _isSaving ? 'Przenoszenie...' : 'Kolejny krok',
                    style: const TextStyle(
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

  Widget _buildPreferencesCard(List<MapEntry<String, String>> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Preferencje zamówienia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              'Brak zapisanych preferencji.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.key,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.value,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
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
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: HorizontalScrollText(
                        text: row.value,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                        ),
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
