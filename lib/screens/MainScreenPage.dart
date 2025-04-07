import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

class MainScreenPage extends StatefulWidget {
  const MainScreenPage({super.key});

  @override
  State<MainScreenPage> createState() => _MainScreenPageState();
}

class _MainScreenPageState extends State<MainScreenPage> {
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

Widget _buildRiskRow(String ideal, String label, String current) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(ideal, style: const TextStyle(fontWeight: FontWeight.w500)),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(current, style: const TextStyle(fontWeight: FontWeight.w500)),
    ],
  );
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

  Position position = await Geolocator.getCurrentPosition();

  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.location_pin, size: 30, color: Colors.black),
              Text(_location, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_date),
                      ],
                    ),
                    Column(
                      children: [
                        const Text("Time", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_time),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
              child: 
              Column(
                  children: [
                    const Text("Humidity : Apa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                    const Text("Weather : Apa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                    const SizedBox(height: 40),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: humidity),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return SizedBox(
                          height: 180,
                          width: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: value,
                                strokeWidth: 14,
                                backgroundColor: Colors.grey[300],
                                color: Colors.green,
                              ),
                              Text(
                                '${(value * 100).round()}%',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                )
              ),

              const SizedBox(height: 30),

              AnimatedSlide(
                offset: Offset(0, 0), // slide in from bottom
                duration: Duration(milliseconds: 800),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                    ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Ideal', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Current', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildRiskRow('30%-55%', 'Humidity', '22%'),
                          const SizedBox(height: 16),
                          _buildRiskRow('10°C–30°C', 'Temperature', '32°C'),
                          const SizedBox(height: 16),
                          _buildRiskRow('0–10km/h', 'Wind Speed', '14km/h'),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
