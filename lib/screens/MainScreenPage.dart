import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final String weatherApiKey = dotenv.env['GOOGLE_API_KEY']!;

final String geminiApiKey = dotenv.env['GEMINI_API_KEY']!;
final String geminiVersion = dotenv.env['GEMINI_VERSION']!;

class MainScreenPage extends StatefulWidget {
  const MainScreenPage({super.key});

  @override
  State<MainScreenPage> createState() => _MainScreenPageState();
}

class _MainScreenPageState extends State<MainScreenPage> {
  bool _isLoading = true;
  bool _isLoadingGemini = true;

  late Color _riskWheelColor;

  String _location = 'Locating...';
  dynamic _weather;
  dynamic _geminiAnalysis;
  String _date = '';
  String _time = '';

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
  return IntrinsicHeight(
    child: Stack(
      children: [
        Positioned(left: 0, child: Text(
          ideal,
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
        Align(child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),),
        Positioned(right: 0, child: Text(
          current,
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
      ],
    ),
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

  _getCurrentWeather(position);
  _getGeminiAnalysis(position);

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


Future<void> _getCurrentWeather(Position position) async {
  double latitude = position.latitude;
  double longitude = position.longitude;

  String url = 'https://weather.googleapis.com/v1/currentConditions:lookup?'
    'key=$weatherApiKey&'
    'location.latitude=$latitude&'
    'location.longitude=$longitude';
  try {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var weather = jsonDecode(response.body);
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } else {
      setState(() => _location = 'Error: couldn\'t fetch weather data');
    }
  } catch (e) {
    setState(() => _location = 'Error: $e');
  }
}


Future<void> _getGeminiAnalysis(Position position) async {
  Gemini.init(apiKey: geminiApiKey);
  double latitude = position.latitude;
  double longitude = position.longitude;
  
  String prompt = 'I want to safely create an open fire. '
    'Given latitude is $latitude and longitude is $longitude, '
    'give a risk percentage per 100%, a risk threat level ending in "Risk" and brief summary on your reasoning, mentioning the location but not the coordinates.';
  String format = 'Use this JSON schema:\n' 
    'Return = {'
      '\'risk\': number, '
      '\'level\': string, '
      '\'summary\': string'
    '}';
  prompt = '$prompt\n$format';
  
  Gemini.instance.prompt(
    parts: [
      Part.text(prompt),
    ]
  ).then((value) {
    String output = value?.output ?? '';
    output = output.replaceAll(RegExp(r"(json)|`"), "");
    dynamic analysis = jsonDecode(output);

    Color riskColor;
    if (analysis["risk"] > 65) {
      riskColor = Colors.red;
    } else if (analysis["risk"] > 40) {
      riskColor = Colors.orange;
    } else if (analysis["risk"] > 15) {
      riskColor = Colors.yellow;
    } else {
      riskColor = Colors.green;
    }

    setState(() {
      _geminiAnalysis = analysis;
      _riskWheelColor = riskColor;
      _isLoadingGemini = false;
    });
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: 
          SafeArea(
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
                      _isLoadingGemini ?
                      const Center(child:CircularProgressIndicator() ,)
                      :
                      Column(
                        children: [
                          Text(
                            "Humidity : ${_weather['relativeHumidity']}%", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24
                          )),
                          Text(
                            "Weather : ${_weather['weatherCondition']['description']['text']}", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24
                          )),
                          const SizedBox(height: 40),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: _geminiAnalysis["risk"]/100),
                            duration: const Duration(seconds: 2),
                            builder: (context, value, child) {
                              return SizedBox(
                                height: 200,
                                width: 200,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: 5,
                                      child: CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 3,
                                        backgroundColor: Colors.grey[300],
                                        color: _riskWheelColor,
                                      ),
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
                          const SizedBox(height: 30),
                          Text(_geminiAnalysis["level"], style: const TextStyle(fontSize: 20,)),
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
                          child: 
                            _isLoading ?
                            Center(child: CircularProgressIndicator())
                            :
                            Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Ideal', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Current', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),

                              const SizedBox(height: 20),

                              _buildRiskRow(
                                '>40%–50%', 
                                'Humidity', 
                                "${_weather['relativeHumidity']}%"
                              ),
                              const SizedBox(height: 16),

                              _buildRiskRow(
                                '0°C-27°C', 
                                'Temperature', 
                                "${_weather['temperature']['degrees']}°C"
                              ),
                              const SizedBox(height: 16),

                              _buildRiskRow(
                                '<8km/h-16km/h', 
                                'Wind Speed', 
                                "${_weather['wind']['speed']['value']}km/h"
                              ),
                            ],
                      ),
                    ),
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
                          child: 
                            _isLoadingGemini ?
                            Center(child: CircularProgressIndicator())
                            :
                            Text(
                              _geminiAnalysis['summary'],
                              style: const TextStyle(fontWeight: FontWeight.w500)
                            ),
                        ),
                      ),
                      
                ],
              ),
            ),
          ),
      )
    );
  }
}
