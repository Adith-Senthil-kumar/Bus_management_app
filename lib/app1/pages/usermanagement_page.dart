import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';
import 'package:busbuddy/app1/pages/driver_page.dart'; // Import your Drivers Page
import 'package:busbuddy/app1/pages/student_page.dart'; // Import your Students Page

class UsermanagementPage extends StatefulWidget {
  @override
  _UsermanagementPageState createState() => _UsermanagementPageState();
}

class _UsermanagementPageState extends State<UsermanagementPage> {
  int _selectedIndex = 0; // To track selected index for BottomNavigationBar

  @override
  Widget build(BuildContext context) {
    // Gradient definition
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFF3764A7), // Gradient Color 1
        Color(0xFF28497B), // Gradient Color 2
        Color(0xFF152741), // Gradient Color 3
      ],
      stops: [0.36, 0.69, 1.0],
    );

    return WillPopScope(
      onWillPop: () async {
        // Handle back navigation
        context.read<NavigationBloc>().add(NavigateToHome());
        Navigator.pop(context); // Remove this page from the navigation stack
        return Future.value(false); // Prevent the default back action
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true, // Center-align the title
          title: Text(
            'User Management', // AppBar title
            style: TextStyle(color: Colors.white), // Title color white
          ),
          backgroundColor: Colors.transparent, // Making the AppBar transparent
          elevation: 0, // Removing the shadow
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: gradient, // Apply gradient to the AppBar
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white), // Back button
            onPressed: () {
              // Handle back navigation
              context.read<NavigationBloc>().add(NavigateToHome());
              Navigator.pop(context); // Remove this page from the navigation stack
            },
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // Add Driver page here
            DriversPage(),
            // Add Students page here
            StudentsPage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex, // Set the current index
          onTap: (index) {
            setState(() {
              _selectedIndex = index; // Update the selected index
            });

            // Navigate based on the selected index
            if (index == 0) {
              context.read<NavigationBloc>().add(NavigateToDrivers());
            } else {
              context.read<NavigationBloc>().add(NavigateToStudents());
            }
          },
          backgroundColor: Colors.white, // Set the background color to white
          selectedItemColor: Colors.blue, // Set selected item color to blue
          unselectedItemColor: Colors.grey, // Set unselected item color to grey
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus),
              label: 'Drivers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Students',
            ),
          ],
        ),
      ),
    );
  }
}