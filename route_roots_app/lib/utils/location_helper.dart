import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- HELPER 1: ADDRESS -> COORDINATES ---
Future<LatLng?> getCoordinates(String address) async {
  if (address.isEmpty) return null;
  final query = "$address, Pune"; 
  final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
  try {
    final response = await http.get(url, headers: {'User-Agent': 'com.routeroots.app/1.0'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
      }
    }
  } catch (e) { print("Error: $e"); }
  return null;
}

// --- HELPER 2: COORDINATES -> ADDRESS (Reverse Geocoding) ---
Future<String> getAddressFromLatLng(LatLng point) async {
  final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json');
  try {
    final response = await http.get(url, headers: {'User-Agent': 'com.routeroots.app/1.0'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['display_name'].split(',')[0] + ", " + (data['address']['city'] ?? "Pune");
    }
  } catch (e) { print("Error: $e"); }
  return "${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}";
}