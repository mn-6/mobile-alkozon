import 'package:flutter/material.dart';

import 'package:alkozon/core/di/injection_container.dart';
import 'package:alkozon/core/localization/user_message.dart';
import 'package:alkozon/core/widgets/app_snackbar.dart';
import 'package:alkozon/features/inventory/domain/entities/inventory_item.dart';
import 'package:alkozon/core/widgets/product_thumbnail.dart';

class InventoryDetailScreen extends StatefulWidget {
  const InventoryDetailScreen({
    super.key,
    required this.item,
    required this.onInventoryChanged,
  });

  final InventoryItem item;
  final Future<void> Function() onInventoryChanged;

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _inventoryRepository = InjectionContainer.I.inventoryRepository;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  late InventoryItem _currentItem;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<bool> _confirmQuantityChange(bool add, int amount) async {
    final actionLabel = add ? 'Dodać' : 'Zużyć';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(actionLabel),
          content: Text('$actionLabel $amount sztuk ${_currentItem.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('NIE'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('TAK'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _requestQuantityChange(bool add) async {
    if (_isSaving) return;

    final amount = int.tryParse(_quantityController.text.trim());
    if (amount == null || amount <= 0) {
      AppSnackbar.show(
        context,
        message: 'Podaj poprawną ilość większą od zera.',
        success: false,
      );
      return;
    }

    if (!add && amount > _currentItem.quantity.toInt()) {
      AppSnackbar.show(
        context,
        message:
            'Nie możesz zużyć więcej niż obecny stan (${_currentItem.quantityLabel}).',
        success: false,
      );
      return;
    }

    final confirmed = await _confirmQuantityChange(add, amount);
    if (!confirmed || !mounted) return;
    await _changeQuantity(add, amount);
  }

  Future<void> _changeQuantity(bool add, int amount) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = add
          ? await _inventoryRepository.addQuantity(_currentItem, amount)
          : await _inventoryRepository.consumeQuantity(_currentItem, amount);
      if (!mounted) return;

      setState(() {
        _currentItem = updated;
      });
      await widget.onInventoryChanged();

      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: add ? 'Dodano $amount do stanu.' : 'Zużyto $amount ze stanu.',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Nie udało się zmienić stanu: ${UserMessage.fromError(e)}',
        success: false,
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
    final Color accentColor = _currentItem.isProduct
        ? Colors.orangeAccent
        : Colors.teal;
    final IconData icon = _currentItem.isProduct
        ? Icons.inventory_2_outlined
        : Icons.science_outlined;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentItem.name,
          style: const TextStyle(
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: ProductThumbnail(
                        productNames: [_currentItem.name],
                        size: 160,
                        borderRadius: 16,
                        accentColor: accentColor,
                        fallbackIcon: icon,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentItem.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _currentItem.detailEntries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final row = _currentItem.detailEntries[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
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
                          Text(
                            row.value,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ilość',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _requestQuantityChange(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Dodaj',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _requestQuantityChange(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Zużyj',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
