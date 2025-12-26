import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../utils/location_helper.dart';
import 'location_picker.dart';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});
  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController(text: "3");
  final TextEditingController _priceController = TextEditingController(text: "50");
  TimeOfDay selectedTime = TimeOfDay.now();

  bool isLoading = false;
  String statusMessage = "";
  List<LatLng> routePoints = [];
  LatLng? startCoords;
  LatLng? endCoords;

  Future<void> _pickLocation(bool isStart) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationPicker()));
    if (result != null && result is LatLng) {
      final address = await getAddressFromLatLng(result);
      setState(() {
        if (isStart) { startCoords = result; _startController.text = address; } 
        else { endCoords = result; _endController.text = address; }
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> postRide() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { setState(() => statusMessage = "Not logged in"); return; }
    setState(() { isLoading = true; statusMessage = "Calculating..."; routePoints = []; });

    LatLng? s = startCoords ?? await getCoordinates(_startController.text);
    LatLng? e = endCoords ?? await getCoordinates(_endController.text);

    if (s == null || e == null) { setState(() { isLoading = false; statusMessage = "Invalid locations."; }); return; }

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/create_ride'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "driver_id": user.id,
          "start_lat": s.latitude, "start_lon": s.longitude,
          "end_lat": e.latitude, "end_lon": e.longitude,
          "departure_time": selectedTime.format(context),
          "available_seats": int.tryParse(_seatsController.text) ?? 3,
          "price": double.tryParse(_priceController.text) ?? 50.0,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['route_geometry'] != null) {
          final coordinates = data['route_geometry']['coordinates'] as List;
          setState(() {
            routePoints = coordinates.map((p) => LatLng(p[1], p[0])).toList();
            statusMessage = "Success! Route posted.";
          });
        }
      } else { setState(() => statusMessage = "Failed: ${response.body}"); }
    } catch (err) { setState(() => statusMessage = "Error: $err"); } 
    finally { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(controller: _startController, decoration: InputDecoration(labelText: "Start Point", suffixIcon: IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () => _pickLocation(true)))),
              TextField(controller: _endController, decoration: InputDecoration(labelText: "Destination", suffixIcon: IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () => _pickLocation(false)))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(selectedTime.format(context)),
                      onPressed: _pickTime,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: TextField(controller: _seatsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Seats", border: OutlineInputBorder())),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price ₹", border: OutlineInputBorder())),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: postRide, child: const Text("Post My Ride")),
              if (isLoading) const LinearProgressIndicator(),
              Text(statusMessage, style: TextStyle(color: Colors.green[800])),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(initialCenter: const LatLng(18.5204, 73.8567), initialZoom: 12.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.routeroots.app'),
              PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 4.0, color: Colors.blue)]),
              if (routePoints.isNotEmpty) MarkerLayer(markers: [
                 Marker(point: routePoints.first, child: const Icon(Icons.location_on, color: Colors.green)),
                 Marker(point: routePoints.last, child: const Icon(Icons.flag, color: Colors.red)),
              ])
            ],
          ),
        ),
      ],
    );
  }
}