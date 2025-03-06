// ignore_for_file: depend_on_referenced_packages

import 'package:busbuddy/app2/pages/account_page.dart';
import 'package:busbuddy/app2/pages/contacts_page.dart';
import 'package:busbuddy/app2/pages/feedback_page.dart';
import 'package:busbuddy/app2/pages/notification_page.dart';
import 'package:busbuddy/app2/pages/search_page.dart';
import 'package:busbuddy/app2/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_event.dart';
import 'package:busbuddy/app2/blocs/navigation_state.dart';
import 'package:busbuddy/app2/pages/busdetails_page.dart';
import 'package:busbuddy/app2/pages/home_page1.dart';
import 'package:busbuddy/app2/pages/location_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> saveTokenToFirestore() async {
  // Get the current user
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('User not logged in');
    return;
  }

  // Get the FCM token
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null) {
    print('Failed to get FCM token');
    return;
  }

  // Save the token to Firestore
  try {
    await FirebaseFirestore.instance.collection('tokens').doc(user.uid).set({
      'email': user.email,
      'token': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('FCM token saved successfully');
  } catch (e) {
    print('Error saving FCM token: $e');
  }
}

// Call this function when the user logs in
void onUserLogin() {
  saveTokenToFirestore();
}

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavigationBloc()),
      ],
      child: Level2app(),
    ),
  );
}

class Level2app extends StatelessWidget {
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

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

  
  @override
  Widget build(BuildContext context) {
  

    // Gradient definition

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      drawer: Drawer(
  backgroundColor: Colors.white,
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      // Header with dynamic size using LayoutBuilder
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth; // Full width of the drawer
          final height = (width * 0.5).clamp(150.0, 250.0); // Adjusted height
          final iconSize = height * 0.3;
          final fontSize = (height * 0.18).clamp(14.0, 24.0); // Clamped font size

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
                FittedBox( // Prevents text overflow
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
      // List Items
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
          context.read<NavigationBloc>().add(NavigateTosettings());
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsPage()),
          );
        },
      ),
    ],
  ),
),
      appBar: buildAppBar(),
      extendBody: true,
      body: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          if (state is BusDetailsState) {
            return BusDetailsPage();
          } else if (state is Home1State) {
            return HomePage1();
          } else if (state is LocationState) {
            return LocationPage();
          } else if (state is ContactsState) {
            return ContactsPage();
          } else if (state is FeedbackState) {
            return FeedbackPage();
          } else if (state is SettingsState) {
            return SettingsPage();
          } else if (state is SearchState) {
            return SearchPage();
          } else if (state is NotificationState) {
            return NotificationPage();
          } else {
            return Center(child: Text('Unknown State'));
          }
        },
      ),
      bottomNavigationBar: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          int currentIndex = 1; // Default to HomeState

          if (state is BusDetailsState) {
            currentIndex = 0;
          } else if (state is LocationState) {
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
                          Icons.directions_bus, "Bus", 0, currentIndex),
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
                          Icons.location_on, "Location", 2, currentIndex),
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

  PreferredSize buildAppBar() {
  return PreferredSize(
    preferredSize: Size.fromHeight(50),
    child: Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 100,
          leading: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              IconButton(
                icon: Icon(Icons.menu),
                color: Colors.white,
                tooltip: 'Menu',
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              IconButton(
                icon: Icon(Icons.notifications),
                color: Colors.white,
                tooltip: 'Notifications',
                onPressed: () {
                  context.read<NavigationBloc>().add(NavigateToNotification());
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationPage()),
                  );
                },
              ),
            ],
          ),
          title: Text(
            'Bus Buddy',  // Replace with your desired text
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true, // Ensures the text is centered
          actions: [
            IconButton(
              icon: Icon(Icons.person),
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
  );
}

  Widget _buildNavBarItem(IconData icon, String label, int index, int currentIndex) {
  return Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        switch (index) {
          case 0:
            context.read<NavigationBloc>().add(NavigateToBusDetails());
            break;
          case 1:
            context.read<NavigationBloc>().add(NavigateToHome1());
            break;
          case 2:
            context.read<NavigationBloc>().add(NavigateToLocation());
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
}
