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
import 'package:busbuddy/app2/pages/home_page.dart';
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
  Future<bool> _onWillPop() async {
    // Optionally, navigate to the home page or show a confirmation dialog
    // context.read<NavigationBloc>().add(NavigateToHome());
    // Navigator.pop(context);
    // Or use a custom action, like showing a dialog:
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to exit the app?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Don't exit
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Exit app
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
    return false; // Prevent the app from closing automatically
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
      resizeToAvoidBottomInset: false, 
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      drawer: Drawer(
  backgroundColor: Colors.white,
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      // Header with dynamic size based on screen height
      Container(
        height: MediaQuery.of(context).size.height * 0.268, // Height of the header based on screen size
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
            final height = constraints.maxHeight;
            final iconSize = height * 0.35; // Icon size as 30% of header height
            final fontSize = height * 0.18; // Font size as 15% of header height

            return Padding(
              padding: EdgeInsets.all(height * 0.1), // Padding as 10% of header height
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: iconSize, // Dynamically sized icon
                  ),
                  SizedBox(height: height * 0.05), // Space between icon and text
                  Text(
                    'Bus Buddy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize, // Dynamically sized text
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // List Items below the header
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
      appBar: PreferredSize(
  preferredSize: Size.fromHeight(
      screenHeight * 0.234), // Custom height for the AppBar
  child: Container(
    decoration: BoxDecoration(
      gradient: gradient, // Apply the custom gradient
    ),
    child: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final iconSize = height * 0.15; // Icon size based on AppBar height
          final fontSize = height * 0.15; // Font size based on AppBar height
          final verticalPadding = height * 0.13; // Vertical padding

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height * 0.05, vertical: verticalPadding),
            child: Column(
              children: [
                // Row for menu, search, notification, and account icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align icons to the ends
                  children: [
                    // Left-side icons: Menu, Search, Notification
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
                          tooltip: 'Notifications',
                          onPressed: () {
                            context
                                .read<NavigationBloc>()
                                .add(NavigateToNotification());
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NotificationPage()),
                            );
                          },
                        ),
                      ],
                    ),
                    // Right-side icon: Account
                    IconButton(
                      icon: Icon(Icons.person, size: iconSize),
                      color: Colors.white,
                      tooltip: 'Account details',
                      onPressed: () {
                        context
                            .read<NavigationBloc>()
                            .add(NavigateToaccount());
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AccountPage()),
                        );
                      },
                    ),
                  ],
                ),
                // Centered Bus Icon and Title
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_bus, // Bus icon
                          color: Colors.white,
                          size: iconSize * 1.78, // Larger bus icon
                        ),
                        SizedBox(height: height * 0.01), // Space between icon and text
                        Text(
                          'BusBuddy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize, // Adjusted title size
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
    ),
  ),
),
      extendBody: true,
      
                  body: BlocBuilder<NavigationBloc, NavigationState>(
                    builder: (context, state) {
                      if (state is BusDetailsState) {
                        return BusDetailsPage();
                      } else if (state is HomeState) {
                        return HomePage();
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

  Widget _buildNavBarItem(
      IconData icon, String label, int index, int currentIndex) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            context.read<NavigationBloc>().add(NavigateToBusDetails());
            break;
          case 1:
            context.read<NavigationBloc>().add(NavigateToHome());
            break;
          case 2:
            context.read<NavigationBloc>().add(NavigateToLocation());
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
