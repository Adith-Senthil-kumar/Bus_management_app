import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  // To hold the contacts from Firestore
  List<DocumentSnapshot> _contacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts(); // Fetch contacts when the page is loaded
  }

  Future<void> _fetchContacts() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Try reading from cache first
    QuerySnapshot snapshot = await firestore
        .collection('contacts')
        .get(const GetOptions(source: Source.cache));

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _contacts = snapshot.docs;
      });
      return; // Stop here if cache has data
    }
  } catch (e) {
    print('Cache miss, fetching from server...');
  }

  // If cache fails, fetch fresh data
  QuerySnapshot snapshot = await firestore
      .collection('contacts')
      .get();

  setState(() {
    _contacts = snapshot.docs;
  });
}

  // Function to add a new contact to Firestore
  Future<void> _addContact(String position, String name, String phone) async {
    if (position.isNotEmpty && name.isNotEmpty && phone.isNotEmpty) {
      try {
        // Add a new document to the 'contacts' collection
        await FirebaseFirestore.instance.collection('contacts').add({
          'position': position,
          'name': name,
          'phone': phone,
        });

        // Fetch updated contact list from Firestore
        _fetchContacts();
      } catch (e) {
        // Handle any errors that occur
        print('Error adding contact: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add contact')),
        );
      }
    } else {
      // Show a message if the fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all fields')),
      );
    }
  }

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

  // Function to edit a contact in Firestore
  Future<void> _editContact(
      String contactId, String position, String name, String phone) async {
    if (position.isNotEmpty && name.isNotEmpty && phone.isNotEmpty) {
      try {
        // Update the document in the 'contacts' collection
        await FirebaseFirestore.instance
            .collection('contacts')
            .doc(contactId)
            .update({
          'position': position,
          'name': name,
          'phone': phone,
        });

        // Fetch updated contact list from Firestore
        _fetchContacts();
      } catch (e) {
        // Handle any errors that occur
        print('Error updating contact: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update contact')),
        );
      }
    } else {
      // Show a message if the fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all fields')),
      );
    }
  }

  // Function to delete a contact from Firestore
  Future<void> _deleteContact(String contactId) async {
    try {
      // Delete the document from the 'contacts' collection
      await FirebaseFirestore.instance
          .collection('contacts')
          .doc(contactId)
          .delete();

      // Fetch updated contact list from Firestore
      _fetchContacts();
    } catch (e) {
      // Handle any errors that occur
      print('Error deleting contact: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete contact')),
      );
    }
  }

  // Function to show the contact add/edit dialog
  void _showAddEditContactDialog(
      {String? contactId, String? position, String? name, String? phone}) {
    TextEditingController _positionController =
        TextEditingController(text: position);
    TextEditingController _nameController = TextEditingController(text: name);
    TextEditingController _phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(contactId == null ? 'Add Contact' : 'Edit Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _positionController,
                decoration: InputDecoration(
                  labelText: 'Position',
                ),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                ),
              ),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String position = _positionController.text.trim();
                String name = _nameController.text.trim();
                String phone = _phoneController.text.trim();

                if (contactId == null) {
                  _addContact(position, name, phone);
                } else {
                  _editContact(contactId, position, name, phone);
                }

                Navigator.pop(context); // Close the dialog
              },
              child: Text(contactId == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gradient definition for the AppBar
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
        // Handle the back button behavior and navigate to Home
        context.read<NavigationBloc>().add(NavigateToHome());
        Navigator.pop(context);
        return Future.value(false); // Prevent default back action
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(left: 85.0),
            child: Text(
              'Contacts',
              style: TextStyle(
                color: Colors.white,
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
              // Navigate back to Home
              context.read<NavigationBloc>().add(NavigateToHome());
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display list of contacts
              _contacts.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        var contact = _contacts[index];
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(
                              color: Colors.blue.shade300,
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
                                    SizedBox(height: 4),
                                    Text(
                                      contact['phone'] ?? 'No Phone',
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon:
                                        Icon(Icons.phone, color: Colors.green),
                                    onPressed: () {
                                      _launchPhoneDialer(contact['phone']);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      _showAddEditContactDialog(
                                        contactId: contact.id,
                                        position: contact['position'],
                                        name: contact['name'],
                                        phone: contact['phone'],
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteContact(contact.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    )),
            ],
          ),
        ),
        // Floating Action Button to open the dialog
        floatingActionButton: Stack(
          children: [
            Positioned(
              bottom:
                  60, // Adjust the vertical position (increase this value to move it up)
              right: 0, // Right offset
              child: FloatingActionButton(
                onPressed: () {
                  _showAddEditContactDialog(contactId: null);
                },
                child: Icon(Icons.add, color: Colors.white),
                backgroundColor: const Color.fromARGB(255, 72, 124, 203),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
