import 'package:busbuddy/login_pages/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart'; // Import firebase_core
import 'app1/main.dart' as app1;
import 'app2/main.dart' as app2;
import 'app3/main.dart' as app3;
import 'package:busbuddy/login_pages/login_page.dart'; // Your login page
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(BusBuddyApp());
}

class BusBuddyApp extends StatelessWidget {
  const BusBuddyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<User?>(
        future: _checkCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error checking authentication'));
          } else if (snapshot.hasData && snapshot.data != null) {
            // User is logged in, fetch user data from Firestore and navigate accordingly
            return _launchApp(snapshot.data!);
          } else {
            // User is not logged in, show login screen
            return BlocProvider(
              create: (context) => LoginBloc(),
              child: const BusBuddyLoginPage(),
            );
          }
        },
      ),
    );
  }

  // Check if a user is already logged in
  Future<User?> _checkCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  // Launch the app based on the user's level
  Widget _launchApp(User user) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching user data'));
        } else if (snapshot.hasData && snapshot.data!.exists) {
          int userLevel = snapshot.data!.get('level');
          switch (userLevel) {
            case 1:
              return app1.Level1app();
            case 2:
              return app2.Level2app();
            case 3:
              return app3.Level3app();
            default:
              return Scaffold(
                body: Center(child: Text('Invalid User Level')),
              );
          }
        } else {
          return const Center(child: Text('User data not found'));
        }
      },
    );
  }
}
