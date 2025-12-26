import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPicker extends StatefulWidget {
  final LatLng? initialCenter;
  const LocationPicker({super.key, this.initialCenter});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(18.5204, 73.8567); 

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) _center = widget.initialCenter!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) _center = position.center!;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.routeroots.app',
              ),
            ],
          ),
          const Center(child: Icon(Icons.location_pin, color: Colors.red, size: 50)),
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
              onPressed: () => Navigator.pop(context, _center), 
              child: const Text("Confirm This Location", style: TextStyle(fontSize: 18)),
            ),
          )
        ],
      ),
    );
  }
}