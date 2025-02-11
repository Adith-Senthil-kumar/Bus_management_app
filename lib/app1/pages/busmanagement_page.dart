import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusmanagementPage extends StatefulWidget {
  @override
  _BusmanagementPageState createState() => _BusmanagementPageState();
}

class _BusmanagementPageState extends State<BusmanagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController busNumberController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String _searchQuery = "";

  // Fetch bus details
  Stream<QuerySnapshot> _fetchBusDetails() {
    return _firestore.collection('buses').snapshots();
  }

  // Add or update bus details
  Future<void> _addOrUpdateBus({String? documentId}) async {
    final Map<String, dynamic> busData = {
      'busNumber': busNumberController.text,
      'capacity': capacityController.text, // Save as string
      'licensePlate': licensePlateController.text,
    };

    try {
      if (documentId == null) {
        await _firestore.collection('buses').add(busData);
      } else {
        await _firestore.collection('buses').doc(documentId).update(busData);
      }
    } catch (e) {
      print('Error adding/updating bus: $e');
    }
  }

  // Delete bus detail
  Future<void> _deleteBus(String documentId) async {
    try {
      await _firestore.collection('buses').doc(documentId).delete();
    } catch (e) {
      print('Error deleting bus: $e');
    }
  }

  // Show add/edit bus dialog
  void _showAddBusDialog(BuildContext context, {DocumentSnapshot? document}) {
    if (document != null) {
      busNumberController.text = document['busNumber'];
      capacityController.text =
          document['capacity'].toString(); // Convert to string
      licensePlateController.text = document['licensePlate'];
    } else {
      busNumberController.clear();
      capacityController.clear();
      licensePlateController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(document == null ? 'Add Bus Details' : 'Edit Bus Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: busNumberController,
                decoration: InputDecoration(labelText: 'Bus Number'),
              ),
              TextField(
                controller: capacityController,
                decoration: InputDecoration(labelText: 'Capacity'),
                // Allows only numeric input
              ),
              TextField(
                controller: licensePlateController,
                decoration: InputDecoration(labelText: 'License Plate'),
              ),
            ],
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
                await _addOrUpdateBus(documentId: document?.id);
                busNumberController.clear();
                capacityController.clear();
                licensePlateController.clear();
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Bus Number or License Plate',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchBusDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No buses added yet.'));
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var busNumber = doc['busNumber'].toString().toLowerCase();
                  var licensePlate =
                      doc['licensePlate'].toString().toLowerCase();
                  return busNumber.contains(_searchQuery) ||
                      licensePlate.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final document = filteredDocs[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bus Number: ${document['busNumber']}',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Capacity: ${document['capacity']}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'License Plate: ${document['licensePlate']}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showAddBusDialog(context,
                                        document: document);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _deleteBus(document.id);
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 95, right: 5),
        child: FloatingActionButton(
          onPressed: () => _showAddBusDialog(context),
          backgroundColor: Color.fromRGBO(62, 142, 205, 1),
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
