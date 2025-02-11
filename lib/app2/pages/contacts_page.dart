import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_event.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this for phone dialing functionality

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  // To hold the contacts from Firestore
  List<DocumentSnapshot> _contacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts(); // Fetch contacts when the page is loaded
  }

  // Function to fetch contacts from Firestore
  Future<void> _fetchContacts() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('contacts').get();
    setState(() {
      _contacts = snapshot.docs;
    });
  }

  // Function to launch the phone dialer
  Future<void> _launchPhoneDialer(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number is not available.')),
      );
      return;
    }

    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch the phone app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gradient definition for the AppBar
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
            padding:
                const EdgeInsets.only(left: 85.0), // Added padding to the left
            child: Text(
              'Contacts',
              style: TextStyle(
                color: Colors.white, // White color for the title text
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
              Navigator.pop(
                  context); // Remove this page from the navigation stack
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _contacts.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    var contact = _contacts[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50, // Blue background color
                        border: Border.all(
                          color: Colors.blue.shade300, // Blue border
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact['position'] ?? 'No Position',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  contact['name'] ?? 'No Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              _launchPhoneDialer(contact['phone']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
