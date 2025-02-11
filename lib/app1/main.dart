import 'package:busbuddy/app1/pages/account_page.dart';
import 'package:busbuddy/app1/pages/contact_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_state.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/pages/busmanagement_page.dart';
import 'package:busbuddy/app1/pages/home_page.dart';
import 'package:busbuddy/app1/pages/notification_page.dart';
import 'package:busbuddy/app1/pages/reports_page.dart';
import 'package:busbuddy/app1/pages/routemanagement_page.dart';
import 'package:busbuddy/app1/pages/settings_page.dart';
import 'package:busbuddy/app1/pages/tracking_page.dart';
import 'package:busbuddy/app1/pages/userfeedback_page.dart';
import 'package:busbuddy/app1/pages/usermanagement_page.dart';
import 'package:busbuddy/app1/pages/contact_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';




void main() {
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavigationBloc()),
      ],
      child: Level1app(),
    ),
    
  );
}

class Level1app extends StatelessWidget {
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
    return WillPopScope(
      onWillPop: () async {
        final currentState = context.read<NavigationBloc>().state;
        if (currentState is! HomeState) {
          context.read<NavigationBloc>().add(NavigateToHome());
          return false; // Prevents the app from popping
        }
        return true; // Allows the app to exit if already on the home page
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset:
            false, // Ensures the body resizes when keyboard appears
        backgroundColor: Color.fromARGB(255, 40, 73, 123),
        drawer: Drawer(
          child: Container(
            color: Colors.white, // Set the background of the ListView to white
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Top gradient section
                Container(
                  height: MediaQuery.of(context).size.height *
                      0.268, // Dynamic header height
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
                      final iconSize =
                          height * 0.35; // Icon size 40% of the header height
                      final fontSize =
                          height * 0.18; // Font size 18% of the header height
                      final spacing =
                          height * 0.05; // Spacing between icon and text

                      return Padding(
                        padding: EdgeInsets.all(
                            height * 0.1), // Padding based on height
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
                // List Items below the header
                _buildDrawerItem(
                  context,
                  Icons.notification_add,
                  'Notification management',
                  () {
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
                _buildDrawerItem(
                  context,
                  Icons.map,
                  'Tracking',
                  () {
                    context.read<NavigationBloc>().add(NavigateTotracking());
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TrackingPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.feedback,
                  'User FeedBack',
                  () {
                    context.read<NavigationBloc>().add(NavigateTofeedback());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserfeedbackPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.report,
                  'Reports',
                  () {
                    context.read<NavigationBloc>().add(NavigateToreport());
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.person,
                  'User management',
                  () {
                    context.read<NavigationBloc>().add(NavigateTouser());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UsermanagementPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.contacts,
                  'Contacts management',
                  () {
                    context.read<NavigationBloc>().add(NavigateTocontact());
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ContactPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  Icons.settings,
                  'Settings',
                  () {
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
        ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.234), // Custom height
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient, // Your gradient here
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final iconSize =
                      height * 0.15; // Icon size as 15% of the AppBar height
                  final fontSize =
                      height * 0.15; // Font size as 18% of the AppBar height
                  final verticalPadding =
                      height * 0.13; // Vertical padding as 10% of AppBar height

                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: height * 0.05, vertical: verticalPadding),
                    child: Column(
                      children: [
                        // Row to manage the layout of both the menu and account icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween, // Distribute space between menu and account icons
                          children: [
                            // Menu Button at the top (on the left)
                            IconButton(
                              icon: Icon(Icons.menu, size: iconSize),
                              color: Colors.white,
                              tooltip: 'Menu',
                              onPressed: () {
                                _scaffoldKey.currentState?.openDrawer();
                              },
                            ),
                            // Account Button at the top (on the right)
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
                        // Centered content (bus icon and title)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_bus, // Bus icon
                                color: Colors.white,
                                size: iconSize *
                                    1.78, // Icon size doubled for bus icon
                              ),
                              SizedBox(
                                  height: height *
                                      0.01), // Adjust spacing based on height
                              Text(
                                'BusBuddy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      fontSize, // Font size adjusted based on height
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
    // Based on the state, return the appropriate page
    if (state is BusState) {
      return BusmanagementPage();
    } else if (state is HomeState) {
      return HomePage();
    } else if (state is AccountState) {
      return AccountPage();
    } else if (state is NotificationState) {
      return NotificationPage();
    } else if (state is SettingsState) {
      return SettingsPage();
    } else if (state is ReportState) {
      return ReportsPage();
    } else if (state is RouteState) {
      return RoutemanagementPage();
    } else if (state is TrackingState) {
      return TrackingPage();
    } else if (state is FeedbackState) {
      return UserfeedbackPage();
    } else if (state is UserState) {
      return UsermanagementPage();
    } else if (state is ContactState) {
      return ContactPage();
    } else {
      // A more robust fallback for unknown states
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 50),
            SizedBox(height: 20),
            Text('Unknown State', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Optionally provide a way to navigate back or refresh the state
                Navigator.pop(context); // Example: Go back to the previous screen
              },
              child: Text('Go Back'),
            ),
          ],
        ),
      );
    }
  },
),
        bottomNavigationBar: BlocBuilder<NavigationBloc, NavigationState>(
          builder: (context, state) {
            int currentIndex = 1; // Default to HomeState

            if (state is BusState) {
              currentIndex = 0;
            } else if (state is RouteState) {
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
                      color: Color.fromRGBO(64, 142, 205, 1),
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
                            Icons.route_outlined, "Location", 2, currentIndex),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String label, Function onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(label),
      onTap: () => onTap(),
    );
  }

  Widget _buildNavBarItem(
      IconData icon, String label, int index, int currentIndex) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            context.read<NavigationBloc>().add(NavigateToBus());
            break;
          case 1:
            context.read<NavigationBloc>().add(NavigateToHome());
            break;
          case 2:
            context.read<NavigationBloc>().add(NavigateToroute());
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


Future<void> requestManageExternalStoragePermission() async {
  var status = await Permission.manageExternalStorage.request();
  if (status.isGranted) {
    // Permission granted, proceed with file handling
    print('Permission granted');
  } else {
    // Permission denied, show message or redirect user to settings
    openAppSettings();
  }
}