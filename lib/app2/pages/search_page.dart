import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_event.dart';

class SearchPage extends StatelessWidget {
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
        // Handle custom back navigation here
        context.read<NavigationBloc>().add(NavigateToHome1());
        Navigator.pop(context); // Remove this page from the navigation stack
        return Future.value(false); // Prevent the default back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Set the background color to white
        appBar: AppBar(
          title: Text('Search'),
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
              context.read<NavigationBloc>().add(NavigateToHome1());
              Navigator.pop(context); // Remove this page from the navigation stack
            },
          ),
        ),
        body: Center(
          child: Text(
            'search',
            style: TextStyle(fontSize: 24, color: Colors.black),
          ),
        ),
      ),
    );
  }
}