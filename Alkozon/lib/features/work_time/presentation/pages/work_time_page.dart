import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:alkozon/core/widgets/app_snackbar.dart';
import 'package:alkozon/core/widgets/app_status_panel.dart';
import 'package:alkozon/features/work_time/presentation/controllers/work_timer_notifier.dart';

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
    _bootstrapTimer();
  }

  Future<void> _bootstrapTimer() async {
    await timerService.ensureInitialized();
    await timerService.refreshFromBackend();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      timerService.onAppResumed();
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _showSnack(String message, {required bool success}) async {
    if (!mounted) return;
    AppSnackbar.show(context, message: message, success: success);
  }

  Future<void> _handleBreakAction(Future<QrActionResult> Function() action) async {
    if (timerService.isBreakActionInProgress) return;
    final result = await action();
    await _showSnack(result.message, success: result.success);
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
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
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
    if (!timerService.isRunning) {
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

    final onBreak = timerService.isOnBreak;
    final workColor = onBreak ? const Color(0xFF94A3B8) : const Color(0xFF1E293B);
    final breakColor = timerService.isCurrentBreakOverLimit
        ? Colors.redAccent
        : Colors.orange.shade700;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: onBreak ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              onBreak ? "PRZERWA" : "SESJA AKTYWNA",
              style: TextStyle(
                color: onBreak ? Colors.orange.shade800 : Colors.green,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          onBreak ? "Czas pracy (wstrzymany)" : "Czas pracy",
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          timerService.formatTime(timerService.workSeconds),
          style: TextStyle(
            fontSize: onBreak ? 48 : 72,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: workColor,
          ),
        ),
        if (onBreak) ...[
          const SizedBox(height: 28),
          Text(
            "Czas przerwy",
            style: TextStyle(
              color: breakColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timerService.formatTime(timerService.breakSeconds),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: breakColor,
            ),
          ),
          if (timerService.isCurrentBreakOverLimit)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "Przerwa przekroczyła 15 minut",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
        const SizedBox(height: 40),
        if (onBreak)
          _buildBreakControlButton(
            label: "KONIEC PRZERWY",
            icon: Icons.play_arrow_rounded,
            color: Colors.green,
            onTap: timerService.isBreakActionInProgress
                ? null
                : () => _handleBreakAction(timerService.endBreak),
          )
        else
          _buildBreakControlButton(
            label: "PRZERWA",
            icon: Icons.free_breakfast_outlined,
            color: Colors.orange.shade700,
            onTap: timerService.isBreakActionInProgress
                ? null
                : () => _handleBreakAction(timerService.startBreak),
          ),
        const SizedBox(height: 36),
        _buildActionButton(
          icon: Icons.stop_circle_outlined,
          label: "SKANUJ KONIEC",
          color: Colors.redAccent,
          onTap: onBreak ? null : () => _openScanner(context),
        ),
      ],
    );
  }

  Widget _buildBreakControlButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 220,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
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
                        if (!modalContext.mounted) return;

                        Navigator.pop(modalContext);

                        if (!screenContext.mounted) return;
                        AppSnackbar.show(
                          screenContext,
                          message: result.message,
                          success: result.success,
                        );

                        if (!mounted) return;
                        setState(() {
                          _isProcessingScan = false;
                        });

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
    required VoidCallback? onTap,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(50),
            child: Opacity(
              opacity: onTap == null ? 0.4 : 1,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
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
            AppStatusPanel(
              icon: Icons.cloud_off,
              title: 'Nie udało się pobrać historii',
              message: timerService.historyError!,
              actionLabel: 'Odśwież logi',
              onAction: timerService.refreshHistoryFromBackend,
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
              'Brak zapisanych logów',
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
          final stats = timerService.statsForLog(item);

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
                    ? 'Sesja aktywna'
                    : 'Zmiana zakończona',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: end == null ? Colors.green : Colors.blueAccent,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'Czas pracy: ${timerService.formatTime(stats.workSeconds)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Czas przerwy: ${timerService.formatTime(stats.breakSeconds)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Całkowity czas: ${timerService.formatTime(stats.totalSeconds)}',
                    style: const TextStyle(fontSize: 13),
                  ),
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
