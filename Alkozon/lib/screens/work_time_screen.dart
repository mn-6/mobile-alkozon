import 'dart:async';
import 'package:flutter/material.dart';
import 'work_time_service.dart';

class WorkTimeScreen extends StatefulWidget {
  const WorkTimeScreen({super.key});

  @override
  State<WorkTimeScreen> createState() => _WorkTimeScreenState();
}

class _WorkTimeScreenState extends State<WorkTimeScreen> {
  final WorkTimerService timerService = WorkTimerService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: timerService,
      builder: (context, child) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Monitor Pracy",
                style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.blueAccent.withOpacity(0.15),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(74.0),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.blueAccent, width: 2.0),
                    ),
                  ),
                  child: const TabBar(
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Color(0xFF64748B),
                    indicatorColor: Colors.blueAccent,
                    indicatorWeight: 4.0,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: "Licznik", icon: Icon(Icons.timer)),
                      Tab(text: "Logi", icon: Icon(Icons.list_alt)),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                _buildTimerTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (timerService.startTime != null)
          Text(
            "Rozpoczęto: ${timerService.formatDateTime(timerService.startTime!)}",
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500),
          ),
        const SizedBox(height: 10),
        Text(
          timerService.formatTime(timerService.seconds),
          style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              icon: timerService.isRunning ? Icons.pause : Icons.play_arrow,
              label: timerService.isRunning ? "PAUZA" : "START",
              color: Colors.blueAccent,
              onTap: () => timerService.toggleTimer(),
            ),
            const SizedBox(width: 40),
            _buildActionButton(
              icon: Icons.stop,
              label: "ZAKOŃCZ",
              color: Colors.redAccent,
              onTap: () {
                timerService.stopAndSaveWork();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesja została zapisana!')),
                );
              },
            ),
          ],
        ),
      ],
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final history = timerService.history;

    if (history.isEmpty) {
      return const Center(child: Text("Brak zapisanych logów"));
    }

    return ListView.builder(
      itemCount: history.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ŁĄCZNY CZAS",
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(item['duration'] ?? "00:00:00",
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.login, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text("Start: ${item['start']}"),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.logout, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text("Koniec: ${item['end']}"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}