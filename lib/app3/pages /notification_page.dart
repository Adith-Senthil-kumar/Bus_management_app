import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app3/blocs/navigation_bloc.dart';
import 'package:busbuddy/app3/blocs/navigation_event.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Gradient for the AppBar
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
        context.read<NavigationBloc>().add(NavigateToHome2());
        Navigator.pop(context); // Remove this page from the navigation stack
        return Future.value(false); // Prevent the default back action
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Set the background color to white
        appBar: AppBar(
         title: Padding(
            padding: const EdgeInsets.only(right: 45.0),
            child: Center(
              child: Text(
                'Notification',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: gradient, // Apply gradient to AppBar
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white), // Back button
            onPressed: () {
              // Handle back navigation
              context.read<NavigationBloc>().add(NavigateToHome2());
              Navigator.pop(context); // Navigate back
            },
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No notifications available',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              );
            }

            final notifications = snapshot.data!.docs;

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index].data() as Map<String, dynamic>;
                final title = notification['title'] ?? 'No Title';
                final message = notification['message'] ?? 'No Message';
                final timestamp = (notification['timestamp'] as Timestamp?)?.toDate();

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 5,  // Add shadow to make it stand out
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with bold text
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Message text with soft styling
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Date display formatted
                        if (timestamp != null)
                          Text(
                            DateFormat('yyyy-MM-dd').format(timestamp), // Only date displayed
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}