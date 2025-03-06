import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AccountPage extends StatelessWidget {
  Future<Map<String, dynamic>> _fetchUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No user logged in');
  }

  try {
    // Try reading from cache first
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('admins')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get(const GetOptions(source: Source.cache));

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
  } catch (e) {
    print('Cache miss, fetching from server...');
  }

  // If cache fails, fetch fresh data
  QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.data();
  } else {
    throw Exception('Admin not found');
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
            padding: const EdgeInsets.only(
                left: 16.0), // Padding added to the left of the title
            child: Text(
              'Account Details',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
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
        body: FutureBuilder<Map<String, dynamic>>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              var adminData = snapshot.data!;
             

              

              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      
                      SizedBox(height: 16),
                      Text(
                        adminData['name'] ?? 'No Name',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildDetailBox(
                          'Email', adminData['email'] ?? 'No Email'),
                      _buildDetailBox(
                          'Phone', adminData['phone'] ?? 'No Phone'),
                    ],
                  ),
                ),
              );
            } else {
              return Center(child: Text('No data found'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildDetailBox(String title, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          Text(
            '$title:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
