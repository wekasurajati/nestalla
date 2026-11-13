import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class MapLocation {
  final double latitude;
  final double longitude;

  const MapLocation({required this.latitude, required this.longitude});
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late final MapController _mapController;
  LatLng _center = const LatLng(-6.2, 106.8); // Default: Jakarta
  bool _mapReady = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Lokasi tidak aktif'),
            content: const Text(
              'Aktifkan layanan lokasi (GPS) pada perangkat Anda untuk menandai lokasi secara otomatis.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() => _isLoadingLocation = false);
                },
                child: const Text('Saya Mengerti'),
              ),
            ],
          ),
        );
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          if (!mounted) return;
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (!mounted) return;
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_center, 15);
      } else {
        if (!mounted) return;
        setState(() => _isLoadingLocation = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tandai Lokasi'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: ~InteractiveFlag.rotate,
              ),
              onMapReady: () => setState(() => _mapReady = true),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                tileProvider: NetworkTileProvider(
                  headers: {
                    'User-Agent': 'Nestalla/1.0 (flutter_map)',
                  },
                ),
                maxZoom: 16,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFF1B3C72),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!_mapReady || _isLoadingLocation)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.pop(MapLocation(
                    latitude: _center.latitude,
                    longitude: _center.longitude,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3C72),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Simpan Lokasi'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
