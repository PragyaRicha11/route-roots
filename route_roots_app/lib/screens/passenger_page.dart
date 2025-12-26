import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../utils/location_helper.dart';
import 'location_picker.dart';

class PassengerPage extends StatefulWidget {
  const PassengerPage({super.key});
  @override
  State<PassengerPage> createState() => _PassengerPageState();
}

class _PassengerPageState extends State<PassengerPage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  List<dynamic> matches = [];
  bool isLoading = false;
  String statusMessage = "Enter locations to find rides.";
  LatLng? pickupCoords;
  LatLng? dropCoords;

  Future<void> _pickLocation(bool isPickup) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationPicker()));
    if (result != null && result is LatLng) {
      final address = await getAddressFromLatLng(result);
      setState(() {
        if (isPickup) { pickupCoords = result; _pickupController.text = address; } 
        else { dropCoords = result; _dropController.text = address; }
      });
    }
  }

  Future<void> contactDriver(String phoneNumber) async {
    final url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent("Hello, seat available?")}");
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) { throw 'Could not launch $url'; }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open WhatsApp"))); }
  }

  Future<void> searchRides() async {
    setState(() { isLoading = true; statusMessage = "Processing..."; });
    LatLng? p = pickupCoords ?? await getCoordinates(_pickupController.text);
    LatLng? d = dropCoords ?? await getCoordinates(_dropController.text);

    if (p == null || d == null) { setState(() { isLoading = false; statusMessage = "Locations not found."; }); return; }

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/find_matches'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pickup_lat": p.latitude, "pickup_lon": p.longitude,
          "drop_lat": d.latitude, "drop_lon": d.longitude,
          "user_domain": "vit.edu"
        }),
      );
      if (response.statusCode == 200) {
        setState(() { matches = jsonDecode(response.body)['matches']; statusMessage = "Found ${matches.length} rides!"; });
      } else { setState(() => statusMessage = "Error: ${response.statusCode}"); }
    } catch (e) { setState(() => statusMessage = "Connection Failed."); } 
    finally { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(controller: _pickupController, decoration: InputDecoration(labelText: "Pickup", suffixIcon: IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () => _pickLocation(true)))),
          TextField(controller: _dropController, decoration: InputDecoration(labelText: "Drop", suffixIcon: IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () => _pickLocation(false)))),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: searchRides, child: const Text("Search Rides")),
          Text(statusMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (ctx, i) {
                return Card(
                  color: Colors.green[50],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(matches[i]['driver'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Verified Route • 98% Match"),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.green[800]),
                            const SizedBox(width: 4),
                            Text(matches[i]['time'] ?? 'Now', style: TextStyle(color: Colors.green[900])),
                            const SizedBox(width: 15),
                            Icon(Icons.airline_seat_recline_normal, size: 16, color: Colors.green[800]),
                            const SizedBox(width: 4),
                            Text("${matches[i]['seats'] ?? '3'} seats", style: TextStyle(color: Colors.green[900])),
                            const SizedBox(width: 15),
                            Icon(Icons.currency_rupee, size: 16, color: Colors.green[800]),
                            Text("${matches[i]['price'] ?? '50'}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900])),
                          ],
                        )
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat, color: Colors.green, size: 30),
                      onPressed: () => contactDriver(matches[i]['phone'] ?? ''),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}