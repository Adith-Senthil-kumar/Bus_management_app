// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:math';

import 'package:busbuddy/app3/blocs/navigation_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app3/blocs/navigation_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:busbuddy/app3/blocs/navigation_state.dart';
import 'package:busbuddy/app3/pages /account_page.dart';
import 'package:busbuddy/app3/pages /contacts_page.dart';
import 'package:busbuddy/app3/pages /feedback_page.dart';
import 'package:busbuddy/app3/pages%20/home_page2.dart';
import 'package:busbuddy/app3/pages /notification_page.dart';
import 'package:busbuddy/app3/pages /passenger_page.dart';
import 'package:busbuddy/app3/pages /scanner.dart';
import 'package:busbuddy/app3/pages /settings_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavigationBloc()),
      ],
      child: Level3app(),
    ),
  );
}

class Level3app extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavigationBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter App with Buttons in AppBar',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: LocationCheckScreen(),
      ),
    );
  }
}

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Stream controllers
  Stream<Position>? _positionStream;
  Stream<bool>? _locationStatusStream;

  // Get location status stream
  Stream<bool> get locationStatusStream {
    _locationStatusStream ??= Stream.periodic(Duration(seconds: 5))
        .asyncMap((_) => checkLocationPermissionAndService());
    return _locationStatusStream!;
  }

  // Combined check for both location service and permissions
  Future<bool> checkLocationPermissionAndService() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // Check if permission is permanently denied
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Also check for background location permission for better tracking
    PermissionStatus backgroundPermission =
        await Permission.locationAlways.status;
    if (!backgroundPermission.isGranted) {
      // Just check without forcing the request here
      // We'll handle this separately in the UI
    }

    return true;
  }

  Future<bool> activeCheckLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // Request background location permission
  Future<bool> requestBackgroundLocationPermission() async {
    PermissionStatus status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  // Request location permission with better error handling
  Future<bool> requestLocationPermission() async {
    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Return false and let the UI handle this
      return false;
    }

    // Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Return false and let the UI handle this
      return false;
    }

    return true;
  }

  Future<void> updateLocationInFirestore(Position position) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not logged in.');
      return;
    }

    String userEmail = user.email!;

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot snapshot = await firestore
        .collection('drivers')
        .where('driverEmail', isEqualTo: userEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot driverDoc = snapshot.docs.first;

      GeoPoint location = GeoPoint(position.latitude, position.longitude);

      await driverDoc.reference.update({
        'location': location,
      });

      print('Location updated: ${position.latitude}, ${position.longitude}');
    } else {
      print('Driver with email $userEmail not found in Firestore.');
    }
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Start tracking location with error handling and retry mechanism
  Stream<Position> startLocationTracking({int distanceFilter = 10}) {
    _positionStream ??= Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).handleError((error) {
      print('Location tracking error: $error');
      // Retry after error with delay
      return Future.delayed(Duration(seconds: 5), () {
        return startLocationTracking(distanceFilter: distanceFilter);
      });
    });

    return _positionStream!;
  }
}

// Improved LocationCheckScreen
class LocationCheckScreen extends StatelessWidget {
  final LocationService _locationService = LocationService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _locationService.checkLocationPermissionAndService(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Checking location status...',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!) {
          // Location services and permissions are enabled, proceed to MainPage
          return MainPage();
        } else {
          // Location services or permissions are not enabled, show improved blocking UI
          return ImprovedLocationBlockingScreen();
        }
      },
    );
  }
}

// Improved UI for location blocking screen
class ImprovedLocationBlockingScreen extends StatelessWidget {
  final LocationService _locationService = LocationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3764A7),
              Color(0xFF152741),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 80,
                ),
                SizedBox(height: 30),
                Text(
                  'Location Access Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'BusBuddy needs access to your location to function properly. '
                  'We use your location to track bus routes and provide real-time updates.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                _buildActionButton(
                  context,
                  'Enable Location Permission',
                  Icons.check_circle,
                  () async {
                    bool permissionGranted =
                        await _locationService.requestLocationPermission();
                    if (permissionGranted) {
                      // Request background location as well
                      await _locationService
                          .requestBackgroundLocationPermission();

                      // Reload the screen to check location status again
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => LocationCheckScreen()),
                      );
                    } else {
                      // Show a message if permission is denied
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
  content: Text('Location permission is required to use BusBuddy.'),
  action: SnackBarAction(
    label: 'Open Settings',
    onPressed: () async {
      await openAppSettings();
    },
  ),
),
                      );
                    }
                  },
                ),
                SizedBox(height: 15),
                _buildActionButton(
                  context,
                  'Enable Location Services',
                  Icons.location_searching,
                  () async {
                    await _locationService.openLocationSettings();

                    // Wait a moment before checking again
                    await Future.delayed(Duration(seconds: 2));

                    bool serviceEnabled =
                        await Geolocator.isLocationServiceEnabled();
                    if (serviceEnabled) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => LocationCheckScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enable location services.'),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Why We Need Location Access'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(Icons.navigation, 'Navigation',
                                  'To show your current position on route maps'),
                              _buildInfoRow(
                                  Icons.access_time,
                                  'Real-time Updates',
                                  'To provide accurate arrival and departure times'),
                              _buildInfoRow(
                                  Icons.notifications,
                                  'Notifications',
                                  'To send alerts when you approach your stop'),
                              _buildInfoRow(
                                  Icons.people,
                                  'Passenger Information',
                                  'To let passengers know where the bus is'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Why do we need location access?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF3764A7),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        minimumSize: Size(double.infinity, 0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF3764A7), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

// Inside the _MainPageState class, update these methods to properly handle dialog dismissal

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LocationService _locationService = LocationService();
  bool _isLocationEnabled = false;
  bool _isDialogOpen = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _locationCheckTimer;
  // Add this to store the dialog context
  BuildContext? _dialogContext;
  @override
  
  void initState() {
    super.initState();
    _trackDriverLocation();
    _initializeLocation();
    listenToDriverLocation(); // Add this line
  }

  Future<void> _trackDriverLocation() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("User is not authenticated");
    return;
  }

  // Use the user's email instead of UID
  String? email = user.email;
  if (email == null) {
    print("User email is null");
    return;
  }

  print("Using user email: $email");

  // Ensure location permissions are granted
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    print("Location permission denied");
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      print("Location permission still denied after request");
      await openAppSettings(); // Open app settings to allow manual permission enabling
      return;
    }
  }

  // Check if location services are enabled
  bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isLocationServiceEnabled) {
    print("Location services are not enabled");
    await Geolocator.openLocationSettings(); // Open location settings to enable services
    return;
  }

  // Start tracking the driver's real-time location
  Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    ),
  ).listen((Position position) {
    print('New position: ${position.latitude}, ${position.longitude}');
    updateStopStatus(email, GeoPoint(position.latitude, position.longitude));
  }, onError: (error) {
    print('Location tracking error: $error');
  });
}

Future<void> updateStopStatus(String email, GeoPoint driverLocation) async {
  try {
    // Query the stops_status collection using the user's email
    QuerySnapshot stopStatusQuery = await FirebaseFirestore.instance
        .collection('stops_status')
        .where('driverEmail', isEqualTo: email)
        .get();

    if (stopStatusQuery.docs.isEmpty) {
      print('No stop status found for driver $email');
      return;
    } else {
      print('Found ${stopStatusQuery.docs.length} documents for driver $email');
    }

    for (var doc in stopStatusQuery.docs) {
      try {
        Map<String, dynamic> stopData = doc.data() as Map<String, dynamic>;

        // Check if 'stopsWithLocations' field exists and is a list
        if (!stopData.containsKey('stopsWithLocations') || !(stopData['stopsWithLocations'] is List)) {
          print('Invalid stop data structure for document ${doc.id}');
          continue;
        }

        List<dynamic> stops = List<dynamic>.from(stopData['stopsWithLocations']);
        bool nextStopUpdated = false;

        // Mark stops as reached if driver is close enough
        for (int i = 0; i < stops.length; i++) {
          if (stops[i] is Map && stops[i].containsKey('location')) {
            GeoPoint stopLocation = stops[i]['location'];

            double distance = calculateDistance(
              driverLocation.latitude,
              driverLocation.longitude,
              stopLocation.latitude,
              stopLocation.longitude,
            );

            print('Distance to stop ${stops[i]['name']}: $distance meters');

            // If driver is within 100m and stop is not already reached
            if (distance <= 100 && stops[i]['status'] != 'reached') {
              print('Marking stop ${stops[i]['name']} as reached');
              stops[i]['status'] = 'reached';

              // Find next stop after this one
              if (i + 1 < stops.length && stops[i + 1]['status'] != 'reached') {
                stops[i + 1]['status'] = 'next';
                nextStopUpdated = true;
              }

              // Update timestamp
              await doc.reference.update({
                'stopsWithLocations': stops,
                'lastUpdated': FieldValue.serverTimestamp()
              });

              break;
            }
          }
        }

        // If no next stop was set, find the first unreached stop and mark it as next
        if (!nextStopUpdated) {
          bool foundNext = false;
          for (int i = 0; i < stops.length; i++) {
            if (stops[i]['status'] != 'reached') {
              stops[i]['status'] = 'next';
              foundNext = true;

              await doc.reference.update({
                'stopsWithLocations': stops,
                'lastUpdated': FieldValue.serverTimestamp()
              });

              print('Set stop ${stops[i]['name']} as next');
              break;
            }
          }

          // If all stops are reached, reset route or mark as completed
          if (!foundNext) {
            print('All stops reached for route');
            await doc.reference.update({
              'routeCompleted': true,
              'lastUpdated': FieldValue.serverTimestamp()
            });
          }
        }
      } catch (e) {
        print('Error processing document ${doc.id}: $e');
      }
    }
  } catch (e) {
    print('Error updating stop status: $e');
  }
}

// Helper function for distance calculation
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    double dLat = degreesToRadians(lat2 - lat1);
    double dLon = degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(lat1)) *
            cos(degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _initializeLocation() async {
    // First check if location is available
    bool locationAvailable =
        await _locationService.checkLocationPermissionAndService();
    setState(() {
      _isLocationEnabled = locationAvailable;
    });

    if (locationAvailable) {
      _startLocationTracking();
    } else {
      _showLocationRequiredDialog();
    }

    // Start a timer to actively check location status
    _startLocationStatusMonitoring();
  }

  void _startLocationStatusMonitoring() {
    // Cancel existing timer if any
    _locationCheckTimer?.cancel();

    // Create a periodic timer that checks location status every second
    _locationCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      // Skip checking if app is in background to save battery

      bool isLocationEnabled =
          await _locationService.activeCheckLocationStatus();

      // Important: Only take action if there's a change
      if (_isLocationEnabled != isLocationEnabled) {
        print(
            "Location status changed: $_isLocationEnabled -> $isLocationEnabled");

        // Update state
        setState(() {
          _isLocationEnabled = isLocationEnabled;
        });

        // If location was disabled and is now enabled, close the dialog
        if (isLocationEnabled && _isDialogOpen && _dialogContext != null) {
          print("Closing dialog because location is now enabled");
          // Pop the dialog specifically
          if (Navigator.canPop(_dialogContext!)) {
            Navigator.of(_dialogContext!).pop();
          }

          setState(() {
            _isDialogOpen = false;
            _dialogContext = null;
          });

          // Start tracking again
          _startLocationTracking();
        }
        // If location was enabled and is now disabled, show dialog
        else if (!isLocationEnabled && !_isDialogOpen) {
          print("Showing dialog because location is now disabled");
          _showLocationRequiredDialog();
        }
      }
    });
  }

  void _startLocationTracking() {
    print("Starting location tracking");
    // Cancel existing subscription if any
    _positionSubscription?.cancel();

    // Start new subscription
    _positionSubscription =
        _locationService.startLocationTracking().listen((position) {
      _locationService.updateLocationInFirestore(position);
    }, onError: (error) {
      print('Location tracking error: $error');
      // If we get an error, check if it's due to location being disabled
      _checkLocationStatusAfterError();
    });
  }

  Future<void> _checkLocationStatusAfterError() async {
    bool isLocationEnabled = await _locationService.activeCheckLocationStatus();
    if (_isLocationEnabled != isLocationEnabled) {
      setState(() {
        _isLocationEnabled = isLocationEnabled;
      });

      if (!isLocationEnabled && !_isDialogOpen) {
        _showLocationRequiredDialog();
      }
    }
  }

  void _showLocationRequiredDialog() {
    if (!_isDialogOpen) {
      setState(() {
        _isDialogOpen = true;
      });

      // Use a custom dialog that maintains its own state
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // Store the dialog context
          _dialogContext = context;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return WillPopScope(
                // Prevent back button from dismissing dialog
                onWillPop: () async => false,
                child: AlertDialog(
                  title: Text('Location Required'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off,
                        color: Colors.red,
                        size: 50,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'BusBuddy needs access to your location to function properly.\n\n'
                        'Please enable location services to continue using the app.',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      FutureBuilder<bool>(
                        future: _locationService.activeCheckLocationStatus(),
                        builder: (context, snapshot) {
                          final bool isEnabled = snapshot.data ?? false;
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isEnabled ? Icons.check_circle : Icons.error,
                                  color: isEnabled ? Colors.green : Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  isEnabled
                                      ? 'Location enabled'
                                      : 'Location disabled',
                                  style: TextStyle(
                                    color: isEnabled
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await _locationService.requestLocationPermission();
                        // Update dialog UI
                        setDialogState(() {});
                      },
                      child: Text('Grant Permission'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _locationService.openLocationSettings();
                        // Update dialog UI
                        setDialogState(() {});
                      },
                      child: Text('Open Location Settings'),
                    ),
                    // Add manual close button for testing/emergency
                  ],
                ),
              );
            },
          );
        },
      ).then((_) {
        // This runs when the dialog is closed (by any means)
        setState(() {
          _isDialogOpen = false;
          _dialogContext = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _locationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gradient definition
    final gradient = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        Color(0xFF3764A7),
        Color(0xFF28497B),
        Color(0xFF152741),
      ],
      stops: [0.36, 0.69, 1.0],
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      drawer: _isLocationEnabled
          ? Drawer(
              backgroundColor: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Header Section
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth; // Full drawer width
                      final height =
                          (width * 0.5).clamp(150.0, 250.0); // Adjusted height
                      final iconSize = height * 0.3;
                      final fontSize = (height * 0.18).clamp(14.0, 24.0);

                      return Container(
                        width: double.infinity, // Ensures full width
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              Color(0xFF3764A7),
                              Color(0xFF28497B),
                              Color(0xFF152741),
                            ],
                            stops: [0.36, 0.69, 1.0],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: iconSize,
                            ),
                            SizedBox(height: height * 0.05),
                            FittedBox(
                              child: Text(
                                'Bus Buddy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Drawer List Items
                  ListTile(
                    leading: Icon(Icons.contacts, color: Colors.black),
                    title: Text('Contacts'),
                    onTap: () {
                      context.read<NavigationBloc>().add(NavigateTocontacts());
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ContactsPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.feedback, color: Colors.black),
                    title: Text('Feedback'),
                    onTap: () {
                      context.read<NavigationBloc>().add(NavigateTofeedback());
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FeedbackPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.black),
                    title: Text('Settings'),
                    onTap: () {
                      context.read<NavigationBloc>().add(NavigateTosetting());
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            )
          : null, // Disable drawer if location is not enabled
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // Default fixed height

        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 100,
            automaticallyImplyLeading: false,
            title: Text(
              'BusBuddy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.menu),
                  color: Colors.white,
                  tooltip: 'Menu',
                  onPressed: _isLocationEnabled
                      ? () {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      : null,
                ),
                IconButton(
                  icon: Icon(Icons.notifications),
                  color: Colors.white,
                  tooltip: 'Open notifications',
                  onPressed: _isLocationEnabled
                      ? () {
                          context
                              .read<NavigationBloc>()
                              .add(NavigateTonotification());
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NotificationPage()),
                          );
                        }
                      : null,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.person),
                color: Colors.white,
                tooltip: 'Account details',
                onPressed: _isLocationEnabled
                    ? () {
                        context.read<NavigationBloc>().add(NavigateToaccount());
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AccountPage()),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),

      extendBody: true,
      body: Stack(
        children: [
          BlocBuilder<NavigationBloc, NavigationState>(
            builder: (context, state) {
              if (state is accountState) {
                return AccountPage();
              } else if (state is Home2State) {
                return HomePage();
              } else if (state is passengerState) {
                return PassengerPage();
              } else if (state is contactsState) {
                return ContactsPage();
              } else if (state is feedbackState) {
                return FeedbackPage();
              } else if (state is scannerState) {
                return scannerPage();
              } else if (state is settingState) {
                return SettingsPage();
              } else if (state is notificationState) {
                return NotificationPage();
              } else {
                return Center(child: Text('Unknown State'));
              }
            },
          ),
          if (!_isLocationEnabled)
            ModalBarrier(
              color: Colors.black.withOpacity(0.5),
              dismissible: false,
            ),
        ],
      ),
      bottomNavigationBar: _isLocationEnabled
          ? BlocBuilder<NavigationBloc, NavigationState>(
              builder: (context, state) {
                int currentIndex = 1; // Default to HomeState

                if (state is scannerState) {
                  currentIndex = 0;
                } else if (state is passengerState) {
                  currentIndex = 2;
                }

                return Stack(
                  children: [
                    Positioned(
                      left: 30,
                      right: 30,
                      bottom: 20,
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 64, 142, 205),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavBarItem(
                                Icons.barcode_reader, "Route", 0, currentIndex),
                            VerticalDivider(
                              color: Colors.white.withOpacity(0.5),
                              thickness: 1,
                              width: 1,
                            ),
                            _buildNavBarItem(
                                Icons.home, "Home", 1, currentIndex),
                            VerticalDivider(
                              color: Colors.white.withOpacity(0.5),
                              thickness: 1,
                              width: 1,
                            ),
                            _buildNavBarItem(
                                Icons.person, "Passengers", 2, currentIndex),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          : null, // Disable bottom navigation if location is not enabled
    );
  }

  Widget _buildNavBarItem(
      IconData icon, String label, int index, int currentIndex) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          switch (index) {
            case 0:
              context.read<NavigationBloc>().add(NavigateToscanner());
              break;
            case 1:
              context.read<NavigationBloc>().add(NavigateToHome2());
              break;
            case 2:
              context.read<NavigationBloc>().add(NavigateTopassenger());
              break;
          }
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: currentIndex == index ? 50 : 0,
                    height: currentIndex == index ? 50 : 0,
                    decoration: BoxDecoration(
                      color: currentIndex == index
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    icon,
                    color: currentIndex == index ? Colors.black : Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void listenToDriverLocation() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: No authenticated user found.");
      return;
    }

    String userEmail = user.email!;
    print("Starting location listening for driver: $userEmail");

    // Get the driver's document ID based on their email
    FirebaseFirestore.instance
        .collection('drivers')
        .where('driverEmail', isEqualTo: userEmail)
        .limit(1)
        .get()
        .then((driverSnapshot) {
      if (driverSnapshot.docs.isEmpty) {
        print("Error: No driver found for email $userEmail.");
        return;
      }

      DocumentSnapshot driverDoc = driverSnapshot.docs.first;
      String driverId = driverDoc.id;
      print("Found driver ID: $driverId");

      // Listen for real-time driver location updates
      driverDoc.reference.snapshots().listen((driverUpdate) {
        try {
          var data = driverUpdate.data() as Map<String, dynamic>;
          if (data.containsKey('location')) {
            GeoPoint driverLocation = data['location'];
            print(
                "Driver location updated: ${driverLocation.latitude}, ${driverLocation.longitude}");
            updateStopStatus(userEmail, driverLocation);
          } else {
            print("No location field found in driver document");
          }
        } catch (e) {
          print("Error processing driver update: $e");
        }
      });
    }).catchError((error) {
      print("Error fetching driver document: $error");
    });

    
  }
}
