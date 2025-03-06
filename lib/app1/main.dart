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
import 'package:permission_handler/permission_handler.dart';

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
        // Show a dialog to confirm exit instead of going back
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Do you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset:
            false, // Ensures the body resizes when keyboard appears
        backgroundColor: Color.fromARGB(255, 40, 73, 123),

        drawer: Drawer(
          child: Container(
            color: Colors.white, // Background color
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header section with full width
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxWidth = constraints.maxWidth;
                      final double height = (maxWidth * 0.5)
                          .clamp(150.0, 250.0); // Clamped height
                      final double iconSize = height * 0.3;
                      final double fontSize = (height * 0.18)
                          .clamp(14.0, 24.0); // Clamped font size

                      return SizedBox(
                        width: double.infinity, // Ensures full width
                        height: height,
                        child: Container(
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
                          child: SafeArea(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                                SizedBox(
                                    height: height * 0.05), // Dynamic spacing
                                FittedBox(
                                  // Prevents text overflow
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
                          ),
                        ),
                      );
                    },
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
                    'User Feedback',
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
        ),
        appBar: PreferredSize(
          preferredSize:
              Size.fromHeight(kToolbarHeight), // Standard AppBar height
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient, // Your gradient here
            ),
            child: SafeArea(
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: Icon(Icons.menu),
                  color: Colors.white,
                  tooltip: 'Menu',
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                title: Text(
                  'BusBuddy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
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
                    Text('Unknown State',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Optionally provide a way to navigate back or refresh the state
                        Navigator.pop(
                            context); // Example: Go back to the previous screen
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

  Widget _buildNavBarItem(IconData icon, String label, int index, int currentIndex) {
  return Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
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
      child: Container(
        // Expand the entire width of the navbar item
        width: double.infinity,
        height: 70, // Match the navbar height
        alignment: Alignment.center,
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
