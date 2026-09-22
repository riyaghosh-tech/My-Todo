import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() =>
      _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchController =
      TextEditingController();

  LatLng selectedPoint = const LatLng(23.3441, 85.3096);

  String selectedAddress = 'Ranchi, Jharkhand';
  bool isSearching = false;

  Future<void> searchPlace() async {
    final query = searchController.text.trim();

    if (query.isEmpty) return;

    setState(() => isSearching = true);

    try {
      final locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final location = locations.first;

        final point = LatLng(
          location.latitude,
          location.longitude,
        );

        mapController.move(point, 15);

        await updateAddress(point);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place not found. Try another search.'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => isSearching = false);
    }
  }

  Future<void> updateAddress(LatLng point) async {
    setState(() {
      selectedPoint = point;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final address = [
          place.name,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ]
            .where((part) => part != null && part.isNotEmpty)
            .toSet()
            .join(', ');

        if (mounted) {
          setState(() {
            selectedAddress =
                address.isEmpty ? 'Selected location' : address;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          selectedAddress =
              '${point.latitude.toStringAsFixed(4)}, '
              '${point.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF218C55);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onSubmitted: (_) => searchPlace(),
                    decoration: const InputDecoration(
                      hintText: 'Search place or address',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isSearching ? null : searchPlace,
                  icon: isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: selectedPoint,
                initialZoom: 12,
                onTap: (_, point) => updateAddress(point),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.todo',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedPoint,
                      width: 45,
                      height: 45,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(selectedAddress),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, selectedAddress);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
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