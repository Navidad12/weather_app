import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController cityController = TextEditingController();
  
  // PLACEHOLDER FOR API KEY
  final String apiKey = '299d5ed0372b133ddd4db007cc53b60d';

  String cityName = "Search for a city";
  String temperature = "--";
  String description = "--";
  String iconCode = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getUserLocationAndWeather();
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<Map<String, dynamic>> getWeatherData(double lat, double lon) async {
    String url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Map<String, dynamic>> getWeatherByCity(String city) async {
    String url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<void> getUserLocationAndWeather() async {
    setState(() => isLoading = true);
    try {
      Position position = await getCurrentLocation();
      print("Lat: ${position.latitude}, Lon: ${position.longitude}");
      
      var weatherData = await getWeatherData(position.latitude, position.longitude);
      updateUI(weatherData);
    } catch (e) {
      print(e);
      setState(() {
        cityName = "Error getting location";
        isLoading = false;
      });
    }
  }

  Future<void> searchCityWeather() async {
    if (cityController.text.isEmpty) return;
    
    setState(() => isLoading = true);
    try {
      var weatherData = await getWeatherByCity(cityController.text);
      updateUI(weatherData);
    } catch (e) {
      print(e);
      setState(() {
        cityName = "City not found";
        temperature = "--";
        description = "--";
        iconCode = "";
        isLoading = false;
      });
    }
  }

  void updateUI(var decodedData) {
    setState(() {
      if (decodedData == null) {
        cityName = "Error";
        temperature = "--";
        return;
      }
      cityName = decodedData['name'];
      double temp = decodedData['main']['temp'];
      temperature = temp.toStringAsFixed(1);
      description = decodedData['weather'][0]['description'];
      iconCode = decodedData['weather'][0]['icon'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: getUserLocationAndWeather,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: cityController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                hintText: 'Enter City Name',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: searchCityWeather,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (isLoading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (iconCode.isNotEmpty)
                      Image.network(
                        'https://openweathermap.org/img/wn/$iconCode@2x.png',
                        scale: 0.5,
                      ),
                    Text(
                      '$temperature°C',
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: getUserLocationAndWeather,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Location"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            )
          ],
        ),
      ),
    );
  }
}