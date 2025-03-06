import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:busbuddy/app2/blocs/navigation_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_event.dart';

class AccountPage extends StatelessWidget {
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

    // Get the current user's email
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No user is logged in.',
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        context.read<NavigationBloc>().add(NavigateToHome1());
        Navigator.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 50),
              Text(
                'Account Details',
                style: TextStyle(color: Colors.white),
              ),
            ],
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
              context.read<NavigationBloc>().add(NavigateToHome1());
              Navigator.pop(context);
            },
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .where('email', isEqualTo: userEmail)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No details found for this user.'));
            }

            // Data is available
            final student = snapshot.data!.docs.first;
            final data = student.data() as Map<String, dynamic>;

            

            // Define the desired order with human-readable labels
            final fieldLabels = {
              'name': 'Name',
              'roll_no': 'Roll No',
              'phone': 'Phone',
              'department': 'Department',
              'year_of_study': 'Year of Study',
              'email': 'Email',
              'address': 'Address',
              'assignedBusNumber': 'Assigned Bus Number',
            };

            final order = [
              'name',
              'roll_no',
              'phone',
              'department',
              'year_of_study',
              'email',
              'address',
              'assignedBusNumber'
            ];

            final sortedEntries = order
                .where((key) => data.containsKey(key))
                .map((key) => MapEntry(fieldLabels[key]!, data[key]!))
                .toList();

            return Column(
              children: [
                
                SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            Divider(thickness: 1, color: Colors.grey[300]),
                            Expanded(
                              child: ListView(
                                children: sortedEntries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${entry.key}: ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            entry.value.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1000,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
