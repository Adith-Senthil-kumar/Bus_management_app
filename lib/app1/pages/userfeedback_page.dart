import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';

class UserfeedbackPage extends StatefulWidget {
  @override
  _UserfeedbackPageState createState() => _UserfeedbackPageState();
}

class _UserfeedbackPageState extends State<UserfeedbackPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 0; // 0 for Level 2 (Students), 1 for Level 3 (Drivers)

  Future<String> _getUserEmail(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['email'] ?? 'No email available';
      } else {
        return 'No email available';
      }
    } catch (e) {
      return 'Error fetching email';
    }
  }

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
          title: Padding(
            padding: const EdgeInsets.only(right: 55.0), // Add padding to the right of the title
            child: Center(
              child: Text(
                'Feedback',
                style: TextStyle(
                  color: Colors.white, // Set title color to white
                ),
              ),
            ),
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('feedback').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error fetching feedback.'));
              }
              if (snapshot.data?.docs.isEmpty ?? true) {
                return Center(child: Text('No feedback available.'));
              }

              final feedbacks = snapshot.data!.docs;

              // Separate feedbacks into Level 2 and Level 3
              final level2Feedbacks = feedbacks.where((feedback) => feedback['level'] == 2).toList();
              final level3Feedbacks = feedbacks.where((feedback) => feedback['level'] == 3).toList();

              // Select feedback based on the bottom navigation bar's selected index
              List<DocumentSnapshot> selectedFeedbacks = _selectedIndex == 0 ? level2Feedbacks : level3Feedbacks;

              return ListView(
                children: [
                  if (selectedFeedbacks.isNotEmpty)
                    ...selectedFeedbacks.map((feedback) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: FeedbackCard(feedback: feedback),
                      );
                    }).toList(),
                  if (selectedFeedbacks.isEmpty)
                    Center(child: Text('No feedback available for this section.')),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white, // Set background color to white
          selectedItemColor: Colors.blue, // Color for selected item
          unselectedItemColor: Colors.grey, // Color for unselected items
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car),
              label: 'Drivers',
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackCard extends StatelessWidget {
  final DocumentSnapshot feedback;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue), // Blue border
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
        color: Colors.blue.shade50, // Light blue background
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feedback['feedback'],
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8.0),
          Text(
            'From: ${feedback['email']}',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 8.0),
          Text(
            feedback['timestamp'] != null
                ? DateFormat('MM/dd/yyyy hh:mm a').format(
                    (feedback['timestamp'] as Timestamp).toDate())
                : '',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                try {
                  // Delete the feedback from Firestore
                  await _firestore.collection('feedback').doc(feedback.id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feedback deleted successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting feedback.')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}