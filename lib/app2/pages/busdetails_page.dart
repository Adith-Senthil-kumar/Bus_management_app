import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class BusDetailsPage extends StatefulWidget {
  @override
  _BusDetailsPageState createState() => _BusDetailsPageState();
}

class _BusDetailsPageState extends State<BusDetailsPage> {
  String searchQuery = '';

  // Function to fetch all assigned bus documents from the collection
  Future<List<Map<String, dynamic>>> getAllAssignedBusDetails() async {
    try {
      // Get all documents from the assignedbus collection
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('assignedbus').get();

      // Map the documents to a list of bus details
      List<Map<String, dynamic>> busDetailsList = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        busDetailsList.add({
          'busNumber': data['busNumber'],
          'routeName': data['routeName'],
          'driverName': data['driverName'],
          'driverPhone': data['driverPhone'],
        });
      }

      return busDetailsList;
    } catch (e) {
      throw "Error fetching bus details: $e";
    }
  }

  // Function to filter bus details based on route name
  List<Map<String, dynamic>> filterBusDetails(
      List<Map<String, dynamic>> busDetailsList) {
    if (searchQuery.isEmpty) {
      return busDetailsList;
    } else {
      return busDetailsList
          .where((bus) => bus['routeName']
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search by Route Name',
                hintText: 'Enter route name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // Displaying the bus details
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: getAllAssignedBusDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  var busDetailsList = snapshot.data!;
                  var filteredBusDetails = filterBusDetails(busDetailsList);
                  return ListView.builder(
                    itemCount: filteredBusDetails.length,
                    itemBuilder: (context, index) {
                      return _buildBusDetailBox(filteredBusDetails[index]);
                    },
                  );
                } else {
                  return Center(child: Text('No assigned buses found.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Function to build a custom box for displaying bus details
  Widget _buildBusDetailBox(Map<String, dynamic> busDetails) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bus Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          SizedBox(height: 8),
          _buildDetailRow('Bus Number', busDetails['busNumber']),
          _buildDetailRow('Route Name', busDetails['routeName']),
          _buildDetailRow('Driver Name', busDetails['driverName']),
          _buildDetailRow('Driver Phone', busDetails['driverPhone']),
        ],
      ),
    );
  }

  // Function to build a row for each bus detail
  Widget _buildDetailRow(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          Expanded(
            child: Text(
              detail,
              style: TextStyle(fontSize: 16, color: Colors.blue.shade700),
              overflow: TextOverflow.ellipsis, // Handle overflow if needed
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
