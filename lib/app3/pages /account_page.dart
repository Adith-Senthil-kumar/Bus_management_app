import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app3/blocs/navigation_bloc.dart';
import 'package:busbuddy/app3/blocs/navigation_event.dart';

class AccountPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot?> _fetchDriverDetails(String email) async {
  try {
    QuerySnapshot querySnapshot;

    // Try fetching from cache first
    try {
      querySnapshot = await _firestore
          .collection('drivers')
          .where('driverEmail', isEqualTo: email)
          .limit(1)
          .get(const GetOptions(source: Source.cache));

      if (querySnapshot.docs.isNotEmpty) {
        print("Fetched driver details from cache");
        return querySnapshot.docs.first;
      }
    } catch (cacheError) {
      print("Cache miss, fetching from Firestore...");
    }

    // If cache fails, fetch fresh data from Firestore
    querySnapshot = await _firestore
        .collection('drivers')
        .where('driverEmail', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      print("Fetched driver details from Firestore");
      return querySnapshot.docs.first;
    } else {
      return null; // No matching document found
    }
  } catch (e) {
    debugPrint('Error fetching driver details: $e');
    return null;
  }
}
  Uint8List _decodeBase64(String base64String) {
    return base64Decode(base64String);
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email;

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
        context.read<NavigationBloc>().add(NavigateToHome2());
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              'Account Details',
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
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              context.read<NavigationBloc>().add(NavigateToHome2());
              Navigator.pop(context);
            },
          ),
        ),
        body: email == null
            ? Center(child: Text('No user is logged in.'))
            : FutureBuilder<DocumentSnapshot?>(
                future: _fetchDriverDetails(email),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error fetching account details.'));
                  }
                  if (snapshot.data == null) {
                    return Center(child: Text('No account details found.'));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final String? profilePicBase64 = data['profile_pic'];
                  Uint8List? profilePicBytes;

                  if (profilePicBase64 != null) {
                    profilePicBytes = _decodeBase64(profilePicBase64);
                  }

                  final sortedEntries = [
                    {
                      'key': 'Name',
                      'value': data['driverName'] ?? 'Not available'
                    },
                    {
                      'key': 'Email',
                      'value': data['driverEmail'] ?? 'Not available'
                    },
                    {
                      'key': 'Phone',
                      'value': data['driverPhone'] ?? 'Not available'
                    },
                    {
                      'key': 'License',
                      'value': data['driverLicense'] ?? 'Not available'
                    },
                  ];

                  return Column(
                    children: [
                      SizedBox(height: 20),
                      profilePicBytes != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blueAccent,
                              backgroundImage: MemoryImage(profilePicBytes),
                            )
                          : CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
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
                                  Divider(
                                      thickness: 1, color: Colors.grey[300]),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: sortedEntries.length,
                                      itemBuilder: (context, index) {
                                        final entry = sortedEntries[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${entry['key']}: ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  entry['value'].toString(),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1000,
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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