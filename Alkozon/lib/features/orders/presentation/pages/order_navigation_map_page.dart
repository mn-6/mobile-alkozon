import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:alkozon/core/di/injection_container.dart';
import 'package:alkozon/core/localization/user_message.dart';
import 'package:alkozon/core/widgets/app_snackbar.dart';
import 'package:alkozon/core/connectivity/connectivity_failure_handler.dart';
import 'package:alkozon/core/widgets/app_status_panel.dart';
class OrderNavigationMapScreen extends StatefulWidget {
  const OrderNavigationMapScreen({
    super.key,
    required this.address,
    required this.orderId,
    this.isCustomOrder = false,
  });

  final String address;
  final int orderId;
  final bool isCustomOrder;

  @override
  State<OrderNavigationMapScreen> createState() =>
      _OrderNavigationMapScreenState();
}

class _OrderNavigationMapScreenState extends State<OrderNavigationMapScreen> {
  final MapController _mapController = MapController();
  final _orderRepository = InjectionContainer.I.orderRepository;

  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentPoint;
  LatLng? _destinationPoint;
  List<LatLng> _routePoints = [];
  double? _distanceToTargetMeters;
  String? _error;
  bool _loading = true;
  bool _isCompletingDelivery = false;

  bool get _isCloseEnough =>
      _distanceToTargetMeters != null && _distanceToTargetMeters! <= 200;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    try {
      final position = await _getCurrentPosition();
      final destination = await _geocodeAddress(widget.address);
      final route = await _fetchRoute(position, destination);

      if (!mounted) return;
      setState(() {
        _currentPoint = position;
        _destinationPoint = destination;
        _routePoints = route;
        _distanceToTargetMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          destination.latitude,
          destination.longitude,
        );
        _loading = false;
      });

      _startLocationTracking();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentPoint == null || _destinationPoint == null) {
          return;
        }
        final bounds = LatLngBounds.fromPoints([
          _currentPoint!,
          _destinationPoint!,
          ..._routePoints,
        ]);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
        );
      });
    } catch (e) {
      if (!mounted) return;
      if (ConnectivityFailureHandler.report(e, retry: _loadRoute)) {
        setState(() {
          _error = null;
          _loading = true;
        });
        return;
      }
      setState(() {
        _error = UserMessage.fromError(e);
        _loading = false;
      });
    }
  }

  void _startLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10,
          ),
        ).listen((position) {
          if (!mounted || _destinationPoint == null) return;
          final current = LatLng(position.latitude, position.longitude);
          final distance = Geolocator.distanceBetween(
            current.latitude,
            current.longitude,
            _destinationPoint!.latitude,
            _destinationPoint!.longitude,
          );
          setState(() {
            _currentPoint = current;
            _distanceToTargetMeters = distance;
          });
        });
  }

  Future<void> _completeDelivery() async {
    if (_isCompletingDelivery) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Potwierdzenie'),
          content: const Text('Czy paczka została odebrana?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nie'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tak'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isCompletingDelivery = true;
    });

    try {
      if (widget.isCustomOrder) {
        await _orderRepository.patchCustomStatus(
          id: widget.orderId,
          status: 'DELIVERED',
        );
      } else {
        await _orderRepository.patchStatus(
          id: widget.orderId,
          status: 'DELIVERED',
        );
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      if (ConnectivityFailureHandler.report(e)) {
        return;
      }
      AppSnackbar.show(
        context,
        message: 'Nie udało się oznaczyć dostawy: ${UserMessage.fromError(e)}',
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingDelivery = false;
        });
      }
    }
  }

  Future<LatLng> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Włącz lokalizację w telefonie.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Brak zgody na dostęp do lokalizacji.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Uprawnienia lokalizacji są zablokowane w ustawieniach.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }

  Future<LatLng> _geocodeAddress(String address) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': address,
      'format': 'jsonv2',
      'limit': '1',
    });

    final response = await http.get(
      uri,
      headers: const {'User-Agent': 'Alkozon/1.0'},
    );

    if (response.statusCode != 200) {
      throw Exception('Nie udało się znaleźć adresu dostawy.');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    if (decoded.isEmpty) {
      throw Exception('Nie udało się znaleźć adresu dostawy.');
    }

    final data = decoded.first as Map<String, dynamic>;
    final lat = double.parse(data['lat'].toString());
    final lon = double.parse(data['lon'].toString());
    return LatLng(lat, lon);
  }

  Future<List<LatLng>> _fetchRoute(LatLng start, LatLng end) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Nie udało się pobrać trasy.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = decoded['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      return [start, end];
    }

    final geometry = routes.first['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? const [];
    if (coordinates.isEmpty) {
      return [start, end];
    }

    return coordinates.map((point) {
      final pair = point as List<dynamic>;
      return LatLng(
        double.parse(pair[1].toString()),
        double.parse(pair[0].toString()),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Nawigacja',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: AppStatusPanel(
                icon: Icons.map_outlined,
                title: 'Nie udało się wczytać nawigacji',
                message: _error!,
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cel trasy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.address,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      if (_distanceToTargetMeters != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Do celu: ${_distanceToTargetMeters!.toStringAsFixed(0)} m',
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(52.2297, 21.0122),
                          initialZoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.alkozon.app',
                          ),
                          if (_routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints,
                                  strokeWidth: 5,
                                  color: Colors.blueAccent,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (_currentPoint != null)
                                Marker(
                                  point: _currentPoint!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.green,
                                    size: 36,
                                  ),
                                ),
                              if (_destinationPoint != null)
                                Marker(
                                  point: _destinationPoint!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.redAccent,
                                    size: 38,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (_isCloseEnough)
                        Positioned(
                          left: 48,
                          right: 48,
                          bottom: 20,
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isCompletingDelivery
                                  ? null
                                  : _completeDelivery,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isCompletingDelivery
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Dostarczone!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
