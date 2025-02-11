import 'package:busbuddy/login_pages/login_bloc.dart';
import 'package:busbuddy/login_pages/login_page.dart';
import 'package:busbuddy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';
import 'package:busbuddy/app1/blocs/navigation_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_pages/profile_settings_page.dart';

import 'settings_pages/download_page.dart';


class SettingsPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFF3764A7),
        Color(0xFF28497B),
        Color(0xFF152741),
      ],
      stops: [0.36, 0.69, 1.0],
    );

    return WillPopScope(
      onWillPop: () async {
        // Handle back navigation when the back button is pressed
        context.read<NavigationBloc>().add(NavigateToHome());
        Navigator.pop(context); // Remove this page from the navigation stack
        return Future.value(false); // Prevent default back button action
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(
                left: 90.0), // Add padding to the left of the title
            child: Text(
              'Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: gradient,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Colors.white), // Make back button white
            onPressed: () {
              context.read<NavigationBloc>().add(NavigateToHome());
              Navigator.pop(
                  context); // Remove this page from the navigation stack
            },
          ),
        ),
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            ListTile(
              leading: Icon(Icons.person, color: Color(0xFF28497B)),
              title: Text('Profile Settings'),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileSettingsPage(),
                  ),
                );
              },
            ),
            Divider(),
            
            ListTile(
              leading: Icon(Icons.download, color: Color(0xFF28497B)),
              title: Text('Download'),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DownloadPage(),
                  ),
                );
              },
            ),
            
            
            Divider(),
            // Logout Option
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Handle logout logic (e.g., navigate to login screen or clear session)
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Logout logic: clear session data, navigate to login page, etc.

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Navigate back to the main app entry point (where the login page is)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const BusBuddyApp()),
    );
  }
}
