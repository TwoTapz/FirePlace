import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;

  LatLng? _currentPosition;
  bool _isLoading = true;

  String _location = 'Locating...';
  String _date = '';
  String _time = '';
  double humidity = 0.7; // Sample value

  @override
  void initState() {
    super.initState();
    _getCurrentDateTime();
    _getCurrentLocation();
  }

  void _getCurrentDateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    _date = DateFormat('dd MMMM yyyy').format(now);
    _time = DateFormat('hh.mm a').format(now);
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) {
      setState(() => _location = 'Location off');
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      setState(() => _location = 'Permission denied');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    double lat = position.latitude;
    double long = position.longitude;

    LatLng location = LatLng(lat, long);

    setState(() {
      _currentPosition = location;
      _isLoading = false;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        long,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _location = place.locality ?? 'Unknown location'; // Example: "Kajang"
        });
      } else {
        setState(() => _location = 'Location not found');
      }
    } catch (e) {
      setState(() => _location = 'Error: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_location),
      ),
      body: _isLoading ?
        const Center(
          child: CircularProgressIndicator(),
        )
        : 
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _currentPosition!,
            zoom: 16.0,
          ),
        )
    );
  }
}
