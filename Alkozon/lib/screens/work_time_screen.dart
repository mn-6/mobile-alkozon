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
            backgroundColor: Colors.grey.shade50,
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
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(2.0),
                child: Container(
                  color: Colors.blueAccent.withOpacity(0.5),
                  height: 2.0,
                ),
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
                      Tab(text: "Licznik", icon: Icon(Icons.timer)),
                      Tab(text: "Logi", icon: Icon(Icons.list_alt)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTimerTab(),
                      _buildHistoryTab(),
                    ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (timerService.startTime != null)
          Text(
            "Rozpoczęto: ${timerService.formatDateTime(timerService.startTime!)}",
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        const SizedBox(height: 15),
        Text(
          timerService.formatTime(timerService.seconds),
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              icon: timerService.isRunning ? Icons.pause : Icons.play_arrow,
              label: timerService.isRunning ? "PAUZA" : "START",
              color: Colors.blueAccent,
              onTap: () => timerService.toggleTimer(),
            ),
            const SizedBox(width: 45),
            _buildActionButton(
              icon: Icons.stop,
              label: "ZAKOŃCZ",
              color: Colors.redAccent,
              onTap: () {
                timerService.stopAndSaveWork();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesja została zapisana!'),
                    behavior: SnackBarBehavior.floating,
                  ),
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, size: 38, color: color),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final history = timerService.history;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Brak zapisanych logów",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: history.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ŁĄCZNY CZAS",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      item['duration'] ?? "00:00:00",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                Row(
                  children: [
                    const Icon(Icons.login, size: 18, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      "Start: ${item['start']}",
                      style: const TextStyle(color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Text(
                      "Koniec: ${item['end']}",
                      style: const TextStyle(color: Color(0xFF1E293B)),
                    ),
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