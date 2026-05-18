import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'work_time_service.dart';

class WorkTimeScreen extends StatefulWidget {
  const WorkTimeScreen({super.key});

  @override
  State<WorkTimeScreen> createState() => _WorkTimeScreenState();
}

class _WorkTimeScreenState extends State<WorkTimeScreen>
    with WidgetsBindingObserver {
  bool _isProcessingScan = false;
  final WorkTimerService timerService = WorkTimerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    timerService.refreshFromBackend();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      timerService.refreshFromBackend();
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: timerService,
      builder: (context, child) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Monitor Pracy QR",
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.blueAccent.withOpacity(0.15),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(2.0),
                child: Container(color: Colors.blueAccent, height: 2.0),
              ),
            ),
            body: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: const TabBar(
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Color(0xFF64748B),
                    indicatorColor: Colors.blueAccent,
                    indicatorWeight: 4.0,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: "Licznik", icon: Icon(Icons.qr_code_scanner)),
                      Tab(text: "Logi", icon: Icon(Icons.list_alt)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [_buildTimerTab(), _buildHistoryTab()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerTab() {
    if (!timerService.isRunning && timerService.seconds == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              icon: Icons.camera_alt_outlined,
              label: "SKANUJ START",
              color: Colors.blueAccent,
              onTap: () => _openScanner(context),
            ),
            const SizedBox(height: 24),
            const Text(
              "Zeskanuj kod QR, aby rozpocząć",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "SESJA AKTYWNA",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          timerService.formatTime(timerService.seconds),
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 60),
        _buildActionButton(
          icon: Icons.stop_circle_outlined,
          label: "SKANUJ KONIEC",
          color: Colors.redAccent,
          onTap: () => _openScanner(context),
        ),
      ],
    );
  }

  void _openScanner(BuildContext screenContext) {
    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(modalContext).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Skanowanie kodu QR",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(modalContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  onDetect: (capture) async {
                    if (_isProcessingScan) return;

                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? code = barcode.rawValue;
                      if (code != null) {
                        setState(() {
                          _isProcessingScan = true;
                        });

                        final result = await timerService.processQrCode(code);
                        if (!mounted) return;

                        Navigator.pop(modalContext);

                        // Use screenContext (not modalContext) because modal is already
                        // popped and its context is deactivated.
                        ScaffoldMessenger.of(screenContext).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: result.success
                                ? Colors.green.shade700
                                : Colors.redAccent,
                          ),
                        );

                        if (mounted) {
                          setState(() {
                            _isProcessingScan = false;
                          });
                        }

                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final history = timerService.history;

    if (timerService.isHistoryLoading && history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (timerService.historyError != null && history.isEmpty) {
      return RefreshIndicator(
        onRefresh: timerService.refreshHistoryFromBackend,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.cloud_off, size: 56, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              timerService.historyError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: timerService.refreshHistoryFromBackend,
                child: const Text('Odśwież logi'),
              ),
            ),
          ],
        ),
      );
    }

    if (history.isEmpty) {
      return RefreshIndicator(
        onRefresh: timerService.refreshHistoryFromBackend,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          children: [
            const SizedBox(height: 120),
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Brak zapisanych logów",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: timerService.refreshHistoryFromBackend,
      child: ListView.builder(
        itemCount: history.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = history[index];
          final start = item.clockInAt.toLocal();
          final end = item.clockOutAt?.toLocal();
          final durationSeconds = (end ?? DateTime.now())
              .difference(start)
              .inSeconds
              .clamp(0, 365 * 24 * 3600);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                end == null
                    ? 'Sesja aktywna: ${timerService.formatTime(durationSeconds)}'
                    : 'Łącznie: ${timerService.formatTime(durationSeconds)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: end == null ? Colors.green : Colors.blueAccent,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Start: ${timerService.formatDateTime(start)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    end == null
                        ? 'Koniec: w toku'
                        : 'Koniec: ${timerService.formatDateTime(end)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
