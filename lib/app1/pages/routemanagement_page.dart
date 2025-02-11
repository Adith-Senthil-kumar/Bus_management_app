import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoutemanagementPage extends StatefulWidget {
  @override
  _RoutemanagementPageState createState() => _RoutemanagementPageState();
}

class _RoutemanagementPageState extends State<RoutemanagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for text fields
  final TextEditingController routeNameController = TextEditingController();
  final TextEditingController searchController = TextEditingController(); // Search controller
  List<TextEditingController> stopControllers = []; // List to store stop controllers
  String searchQuery = ''; // Variable to store the current search query

  // Method to fetch route details from Firestore with search filtering
  Stream<QuerySnapshot> _fetchRouteDetails() {
    if (searchQuery.isEmpty) {
      return _firestore.collection('routes').snapshots(); // No filter
    } else {
      return _firestore.collection('routes')
          .where('routeName', isGreaterThanOrEqualTo: searchQuery)
          .where('routeName', isLessThanOrEqualTo: searchQuery + '\uf8ff') // Handle search query range
          .snapshots();
    }
  }

  // Method to add or update route details in Firestore
  Future<void> _addOrUpdateRoute({String? documentId}) async {
    final Map<String, dynamic> routeData = {
      'routeName': routeNameController.text,
      'stops': stopControllers
          .map((controller) => controller.text)
          .where((stop) => stop.isNotEmpty)
          .toList(),
    };

    try {
      if (documentId == null) {
        // Add new route
        await _firestore.collection('routes').add(routeData);
      } else {
        // Update existing route
        await _firestore.collection('routes').doc(documentId).update(routeData);
      }
      print('Route details successfully added/updated');
    } catch (e) {
      print('Error adding/updating route: $e');
    }
  }

  // Method to delete a route detail
  Future<void> _deleteRoute(String documentId) async {
    try {
      await _firestore.collection('routes').doc(documentId).delete();
      print('Route successfully deleted');
    } catch (e) {
      print('Error deleting route: $e');
    }
  }

  // Method to show the dialog
  void _showAddRouteDialog(BuildContext context, {String? documentId, Map<String, dynamic>? routeData}) {
    if (routeData != null) {
      // Pre-fill the fields with the selected route details
      routeNameController.text = routeData['routeName'];
      stopControllers.clear();

      // Add controllers for each existing stop
      for (String stop in routeData['stops']) {
        stopControllers.add(TextEditingController(text: stop));
      }
    } else {
      // Clear the fields for a new route
      routeNameController.clear();
      stopControllers.clear();
      stopControllers.add(TextEditingController()); // Add initial stop field
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(documentId == null ? 'Add Route Details' : 'Edit Route Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Route Name Input
                    TextField(
                      controller: routeNameController,
                      decoration: InputDecoration(
                        labelText: 'Route Name',
                      ),
                    ),
                    SizedBox(height: 10),
                    // Dynamically display the stop fields
                    Column(
                      children: [
                        for (int i = 0; i < stopControllers.length; i++)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: stopControllers[i],
                                  decoration: InputDecoration(
                                    labelText: 'Stop ${i + 1}',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setStateDialog(() {
                                    // Remove the selected stop
                                    stopControllers.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Button to add another stop
                    ElevatedButton(
                      onPressed: () {
                        setStateDialog(() {
                          // Add a new stop controller
                          stopControllers.add(TextEditingController());
                        });
                      },
                      child: Text('Add Another Stop'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Save or edit the route details
                    await _addOrUpdateRoute(documentId: documentId);

                    // Clear text from controllers (do not dispose here)
                    routeNameController.clear();
                    for (var controller in stopControllers) {
                      controller.clear();
                    }
                    stopControllers.clear();

                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose controllers properly
    routeNameController.dispose();
    searchController.dispose();
    for (var controller in stopControllers) {
      controller.dispose();
    }
    stopControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: screenHeight * 0.80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
      hintText: 'Search by Route Name',
      border: OutlineInputBorder(),
      contentPadding:
          EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _fetchRouteDetails(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No routes added yet.'));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final document = snapshot.data!.docs[index];
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Route Name: ${document['routeName']}',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Stops: ${document['stops'].join(', ')}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: -10,
                                  right: -10,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          // Open the dialog to edit route details
                                          _showAddRouteDialog(context, documentId: document.id, routeData: document.data() as Map<String, dynamic>);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          // Delete the route
                                          _deleteRoute(document.id); // Make sure document.id is passed correctly
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
          Positioned(
            bottom: 110,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _showAddRouteDialog(context);
              },
              backgroundColor: const Color.fromRGBO(62, 142, 205, 1),
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}