import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // CHANGED: The new map package
import 'package:latlong2/latlong.dart';       // CHANGED: The new coordinate class
import 'package:http/http.dart' as http;

// Your backend URL is still correct.
const String backendUrl = 'http://192.168.1.124:5000'; // Change to your actual IP

class LocationTrackingPage extends StatefulWidget {
  const LocationTrackingPage({super.key});

  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  // CHANGED: Use a MapController for flutter_map
  final MapController _mapController = MapController();
  Timer? _pollingTimer;

  // Your state variables, now using the `latlong2` LatLng class
  LatLng? _patientLocation;
  List<LatLng> _polygonPoints = [];
  bool _isOutsideFence = false;
  String _alertMessage = "Loading status...";

  // All your backend logic (initState, dispose, fetchData, etc.) remains IDENTICAL.
  // I've included it here for completeness.

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchPatientLocation();
      _checkAlertStatus();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    await _fetchPatientLocation();
    await _fetchSafeZone();
  }

  Future<void> _fetchPatientLocation() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/get_location'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _patientLocation = LatLng(data['latitude'], data['longitude']);
        });
        if (_patientLocation != null) {
          _mapController.move(_patientLocation!, 15.0);
        }
      }
    } catch (e) {
      print("Error fetching patient location: $e");
    }
  }

  Future<void> _fetchSafeZone() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/get_safe_zone'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> points = data['polygon'];
        setState(() {
          _polygonPoints = points
              .map((point) => LatLng(point['lat'], point['lng']))
              .toList();
        });
      }
    } catch (e) {
      print("Error fetching safe zone: $e");
    }
  }

  Future<void> _checkAlertStatus() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/check_alert'));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _isOutsideFence = data['is_outside'];
          _alertMessage = data['message'];
        });
      }
    } catch (e) {
      print("Error checking alert status: $e");
    }
  }

  Future<void> _saveSafeZone() async {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least 3 points.')));
      return;
    }
    final body = {
      'polygon': _polygonPoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    };
    final response = await http.post(
      Uri.parse('$backendUrl/set_safe_zone'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.statusCode == 200
              ? 'Safe zone saved!'
              : 'Failed to save safe zone.')));
    }
  }

  void _clearPolygon() {
    setState(() {
      _polygonPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Safe Zone'),
        backgroundColor:
        _isOutsideFence ? Colors.red.shade700 : Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Container(
            color: _isOutsideFence ? Colors.red.shade700 : Colors.green,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Text(_alertMessage,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          Expanded(
            // CHANGED: This is the new map widget implementation
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _patientLocation ?? const LatLng(12.9716, 77.5946),
                initialZoom: 14.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _polygonPoints.add(point);
                  });
                },
              ),
              children: [
                // Layer 1: The actual map image from OpenStreetMap
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.aizcare.app', // Good practice to include
                ),
                // Layer 2: The green polygon for the safe zone
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _polygonPoints,
                      color: Colors.green.withOpacity(0.5),
                      borderColor: Colors.green,
                      borderStrokeWidth: 2,
                      isFilled: true,
                    ),
                  ],
                ),
                // Layer 3: The markers for the patient and polygon corners
                MarkerLayer(
                  markers: [
                    if (_patientLocation != null)
                      Marker(
                        point: _patientLocation!,
                        child:
                        const Icon(Icons.person_pin, size: 40, color: Colors.blueAccent),
                      ),
                    for (final point in _polygonPoints)
                      Marker(
                        point: point,
                        child: const Icon(Icons.circle, size: 10, color: Colors.orange),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                    onPressed: _saveSafeZone,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Zone')),
                ElevatedButton.icon(
                    onPressed: _clearPolygon,
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}