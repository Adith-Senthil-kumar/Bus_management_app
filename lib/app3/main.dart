// ignore_for_file: depend_on_referenced_packages
import 'package:busbuddy/app3/blocs/navigation_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app3/blocs/navigation_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:busbuddy/app3/blocs/navigation_state.dart';
import 'package:busbuddy/app3/pages /account_page.dart';
import 'package:busbuddy/app3/pages /contacts_page.dart';
import 'package:busbuddy/app3/pages /feedback_page.dart';
import 'package:busbuddy/app3/pages /home_page.dart';
import 'package:busbuddy/app3/pages /notification_page.dart';
import 'package:busbuddy/app3/pages /passenger_page.dart';
import 'package:busbuddy/app3/pages /scanner.dart';
import 'package:busbuddy/app3/pages /settings_page.dart';
import 'package:geolocator/geolocator.dart';
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
        // Add more providers here if needed
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter App with Buttons in AppBar',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MainPage(),
      ),
    );
  }
}
Future<void> requestLocationPermission() async {
  // Check if location permission is granted
  PermissionStatus permission = await Permission.location.request();

  if (permission.isGranted) {
    // Permission granted, start tracking location
    startLocationTracking();
  } else {
    // Permission denied, show error or request again
    print('Location permission denied.');
  }
}

Future<void> startLocationTracking() async {
  // Check if location services are enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Request to enable location services
    await Geolocator.openLocationSettings();
    return;
  }

  // Continuously get the current position every few seconds
  Geolocator.getPositionStream(locationSettings: LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Minimum distance in meters to update location
  )).listen((Position position) async {
    // After getting position, update Firestore
    await updateLocationInFirestore(position);
  });
}



Future<void> updateLocationInFirestore(Position position) async {
  // Get the currently logged-in user's email from Firebase Authentication
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('User is not logged in.');
    return;
  }

  String userEmail = user.email!;  // Dynamically fetch the logged-in user's email

  // Get the reference to Firestore 'drivers' collection
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Query the 'drivers' collection to find the document where driverEmail matches
  QuerySnapshot snapshot = await firestore
      .collection('drivers')
      .where('driverEmail', isEqualTo: userEmail)
      .get();

  if (snapshot.docs.isNotEmpty) {
    // We found the matching document, get the document reference
    DocumentSnapshot driverDoc = snapshot.docs.first;

    // Create a GeoPoint from latitude and longitude
    GeoPoint location = GeoPoint(position.latitude, position.longitude);

    // Update the location field in Firestore
    await driverDoc.reference.update({
      'location': location,
    });

    print('Location updated: ${position.latitude}, ${position.longitude}');
  } else {
    // Document with the specified email was not found
    print('Driver with email $userEmail not found in Firestore.');
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
void initState() {
  super.initState();
  requestLocationPermission();
}

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
      drawer: Drawer(
        backgroundColor: Color(0xFFFFFFFF),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.268,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use constraints to calculate sizes
                  final height = constraints.maxHeight;
                  final width = constraints.maxWidth;
                  final iconSize =
                      height * 0.3; // Icon takes 40% of the header height
                  final fontSize =
                      height * 0.2; // Font size is 15% of header height
                  final spacing =
                      height * 0.05; // Spacing is 5% of header height

                  return Padding(
                    padding: EdgeInsets.all(
                        width * 0.01), // Adjust padding based on width
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: iconSize,
                        ),
                        SizedBox(height: spacing),
                        Text(
                          'Bus Buddy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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
              title: Text('FeedBack'),
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
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.234),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient, // Use your gradient here
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final iconSize =
                    height * 0.15; // Icons take 20% of AppBar height
                final fontSize =
                    height * 0.15; // Title font size is 25% of height
                final spacing = height * 0.13; // Spacing is 5% of height

                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: height * 0.05, vertical: spacing),
                  child: Column(
                    children: [
                      // Top row with Menu and Notification icons
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu, size: iconSize),
                            color: Colors.white,
                            tooltip: 'Menu',
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.notifications, size: iconSize),
                            color: Colors.white,
                            tooltip: 'Open notifications',
                            onPressed: () {
                              context
                                  .read<NavigationBloc>()
                                  .add(NavigateTonotification());
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => NotificationPage()),
                              );
                            },
                          ),
                        ],
                      ),
                      // Centered title with Bus Icon
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Icon(
                                Icons.directions_bus,
                                color: Colors.white,
                                size:
                                    iconSize * 1.78, // Bus icon slightly larger
                              ),
                              SizedBox(height: spacing * 0.01),
                              Text(
                                'BusBuddy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.person,
                    size: screenHeight * 0.04), // Adjust size dynamically
                color: Colors.white,
                tooltip: 'Account details',
                onPressed: () {
                  context.read<NavigationBloc>().add(NavigateToaccount());
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      extendBody: true,
      body: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          if (state is accountState) {
            return AccountPage();
          } else if (state is HomeState) {
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
      bottomNavigationBar: BlocBuilder<NavigationBloc, NavigationState>(
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
                      _buildNavBarItem(Icons.barcode_reader, "Route", 0, currentIndex),
                      VerticalDivider(
                        color: Colors.white.withOpacity(0.5),
                        thickness: 1,
                        width: 1,
                      ),
                      _buildNavBarItem(Icons.home, "Home", 1, currentIndex),
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
      ),
    );
  }

  Widget _buildNavBarItem(
      IconData icon, String label, int index, int currentIndex) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            context.read<NavigationBloc>().add(NavigateToscanner());
            break;
          case 1:
            context.read<NavigationBloc>().add(NavigateToHome());
            break;
          case 2:
            context.read<NavigationBloc>().add(NavigateTopassenger());
            break;
        }
      },
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
          SizedBox(height: 4),
        ],
      ),
    );
  }
}








