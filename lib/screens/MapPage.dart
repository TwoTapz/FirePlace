import 'dart:async';
import 'dart:math';

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
  late Heatmap _defaultHeatmap;
  late Set<Heatmap> _heatmaps = {};
  late Icon _toggleBtnIcon;

  LatLng? _currentPosition;
  LatLngBounds? _cameraBounds;
  bool _isLoading = true;

  String _location = 'Locating...';
  String _errMessage = '';
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

  Heatmap getHeatmap(LatLng? position) {
    if (position == null) {
      return Heatmap(
        heatmapId: HeatmapId("emptyHeatmap"), 
        data: [], 
        radius: HeatmapRadius.fromPixels(0)
      );
    }
    double lat = position.latitude;
    double long = position.longitude;
    Random rng = Random();

    double dx_ = 0.00003;
    double dy_ = 0.00003;

    List<WeightedLatLng> heatMapData = [];
    for (int i = 0; i < 8; i++) {
      double weight = 15.0 + rng.nextInt(10);
      double dx = dx_ * (rng.nextInt(4)-i);
      double dy = dy_ * (rng.nextInt(4)-i);

      heatMapData.add(
        WeightedLatLng(LatLng(lat + dy, long - dx), weight: weight)
      );
      heatMapData.add(
        WeightedLatLng(LatLng(lat - dy, long + dx), weight: weight)
      );
    }

    // List<Color> gradientColors = [
    //   Color.fromARGB(0, 0, 255, 255),
    //   Color.fromARGB(1, 0, 255, 255),
    //   Color.fromARGB(1, 0, 191, 255),
    //   Color.fromARGB(1, 0, 127, 255),
    //   Color.fromARGB(1, 0, 63, 255),
    //   Color.fromARGB(1, 0, 0, 255),
    //   Color.fromARGB(1, 0, 0, 253),
    //   Color.fromARGB(1, 0, 0, 191),
    //   Color.fromARGB(1, 0, 0, 159),
    //   Color.fromARGB(1, 0, 0, 127),
    //   Color.fromARGB(1, 63, 0, 91),
    //   Color.fromARGB(1, 127, 0, 63),
    //   Color.fromARGB(1, 191, 0, 31),
    //   Color.fromARGB(1, 255, 0, 0),

    // ];

    // double startPoint = 1 / gradientColors.length;
    // List<HeatmapGradientColor> colors = [];
    // for (int i = 0; i < gradientColors.length; i++) {
    //   colors.add(HeatmapGradientColor(gradientColors[i], startPoint*i));
    // }

    print(heatMapData);

    Heatmap heatmap = Heatmap(
      heatmapId: HeatmapId("defaultHeatmap"),
      radius: HeatmapRadius.fromPixels(50),
      data: heatMapData,
      // gradient: HeatmapGradient(colors)
    );
    return heatmap;
  }

  Future<void> _toggleHeatmap() async {
    if (_heatmaps.isNotEmpty) {
      setState(() {
        _heatmaps = {};
        _toggleBtnIcon = Icon(Icons.device_thermostat);
      });
    } else {


      try {
        setState(() {
          _heatmaps = {_defaultHeatmap};
          _toggleBtnIcon = Icon(Icons.remove_red_eye);
        });
      } catch (e) {
        setState(() => _errMessage = 'Error: $e');
      }
    }
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
    double cameraRadius = 0.0005;

    LatLngBounds bounds = LatLngBounds(
      northeast: LatLng(lat + cameraRadius, long + cameraRadius), 
      southwest: LatLng(lat - cameraRadius, long - cameraRadius), 
    );
    LatLng location = LatLng(lat, long);

    Heatmap heatmap = getHeatmap(LatLng(lat, long));

    setState(() {
      _currentPosition = location;
      _cameraBounds = bounds;
      _defaultHeatmap = heatmap;
      _toggleBtnIcon = Icon(Icons.device_thermostat);
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
        flexibleSpace: PreferredSize(
          preferredSize: Size.fromHeight(50.0), 
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.location_pin, size: 30, color: Colors.black),
                  Text(_location, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
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
            zoom: 21.0
          ),
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: false,
          onCameraMove: (CameraPosition cameraPosition) {
          },
          mapType: MapType.satellite,
          cameraTargetBounds: CameraTargetBounds(
            _cameraBounds,
          ),
          minMaxZoomPreference: MinMaxZoomPreference(19, 25),
          heatmaps: _heatmaps,
        ),
      floatingActionButton: _isLoading ? null : FloatingActionButton(
        onPressed: () {
          _toggleHeatmap();
        },
        foregroundColor: Colors.white,
        backgroundColor: Colors.amber,
        shape: CircleBorder(),
        child: _toggleBtnIcon,
      ),
    );
  }
}
