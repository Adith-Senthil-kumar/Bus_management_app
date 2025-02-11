import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:busbuddy/app2/blocs/navigation_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_event.dart';
import 'package:provider/provider.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _editFeedbackId;

  // Fetch user's email
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

  // Update feedback
  Future<void> _updateFeedback(String feedbackId, String updatedFeedback) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).update({
        'feedback': updatedFeedback,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating feedback. Please try again.')),
      );
    }
  }

  // Delete feedback
  Future<void> _deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting feedback. Please try again.')),
      );
    }
  }

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
        context.read<NavigationBloc>().add(NavigateToHome());
        Navigator.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(right: 55.0),
            child: Center(
              child: Text(
                'Feedback',
                style: TextStyle(color: Colors.white),
              ),
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
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              context.read<NavigationBloc>().add(NavigateToHome());
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide your feedback:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your feedback here...',
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();

                    // Ensure user is logged in
                    if (_auth.currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('You must be logged in to submit feedback.')),
                      );
                      return;
                    }

                    String uid = _auth.currentUser!.uid;
                    try {
                      // Fetch user email
                      String userEmail = await _getUserEmail(uid);

                      // Check if feedback input is empty
                      if (_feedbackController.text.isNotEmpty) {
                        if (_editFeedbackId != null) {
                          // If we're editing an existing feedback, update it
                          await _updateFeedback(_editFeedbackId!, _feedbackController.text);
                        } else {
                          // Submit new feedback with level set to 2 by default
                          await _firestore.collection('feedback').add({
                            'feedback': _feedbackController.text,
                            'email': userEmail,
                            'level': 2,  // Set level to 2 by default
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Feedback submitted successfully!')),
                          );
                        }
                        _feedbackController.clear(); // Clear input after submission
                        setState(() => _editFeedbackId = null); // Reset edit state
                      } else {
                        // Show error if feedback is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Feedback cannot be empty!')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error submitting feedback. Please try again.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 40.0),
                  ),
                  child: Text(_editFeedbackId != null ? 'Update Feedback' : 'Submit Feedback'),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Previous Feedback:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('feedback').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error fetching feedback'));
                    }
                    if (snapshot.data?.docs.isEmpty ?? true) {
                      return Center(child: Text('No feedback available.'));
                    }

                    final feedbacks = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: feedbacks.length,
                      itemBuilder: (context, index) {
                        final feedback = feedbacks[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(8.0),
                              color: Colors.blue.shade50,
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
                                      : 'No timestamp available',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                SizedBox(height: 8.0),
                                if (feedback['email'] == _auth.currentUser?.email)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _feedbackController.text = feedback['feedback'];
                                          setState(() => _editFeedbackId = feedback.id);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteFeedback(feedback.id),
                                      ),
                                    ],
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
            ],
          ),
        ),
      ),
    );
  }
}