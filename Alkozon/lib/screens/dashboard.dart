import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/order_realtime_service.dart';
import 'notifications_screen.dart';
import 'work_time_screen.dart';
import 'inventory_screen.dart';
import 'order_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService.instance;
  String _userDisplayName = '';

  @override
  void initState() {
    super.initState();
    _loadUserDisplayName();
    _notificationService.initialize();
    _notificationService.onAuthenticated();
    OrderRealtimeService.instance.connectForCurrentUser(authService: _authService);
    Future<void>.delayed(Duration.zero, () {
      _notificationService.processPendingNavigation();
    });
  }

  Future<void> _loadUserDisplayName() async {
    final fullName = await _authService.getCurrentUserFullName();
    final email = await _authService.getCurrentUserEmail();
    final fallbackFromEmail = (email?.split('@').first ?? '').trim();
    final display = (fullName?.trim().isNotEmpty == true)
        ? fullName!.trim()
        : (fallbackFromEmail.isNotEmpty ? fallbackFromEmail : 'Pracowniku');

    if (mounted) {
      setState(() {
        _userDisplayName = display;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Panel główny",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _notificationService,
            builder: (context, _) {
              final unreadCount = _notificationService.unreadCount;
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF64748B),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dzień dobry, $_userDisplayName!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Text(
              "Wybierz moduł",
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    title: "Czas pracy",
                    icon: Icons.timer_outlined,
                    color: Colors.blueAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkTimeScreen(),
                        ),
                      );
                    },
                  ),

                  _buildMenuCard(
                    context,
                    title: "Stany magazynowe",
                    icon: Icons.inventory_2_outlined,
                    color: Colors.orangeAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InventoryScreen(),
                        ),
                      );
                    },
                  ),

                  _buildMenuCard(
                    context,
                    title: "Aktywne zamówienia",
                    icon: Icons.shopping_cart_outlined,
                    color: Colors.greenAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrdersScreen(),
                        ),
                      );
                    },
                  ),

                  _buildMenuCard(
                    context,
                    title: "Twój profil",
                    icon: Icons.person_outline,
                    color: Colors.purpleAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style:
          ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(color.withOpacity(0.05)),
          ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
