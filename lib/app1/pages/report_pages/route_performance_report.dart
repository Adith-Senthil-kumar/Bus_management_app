import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoutePerformanceReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Center(
            child: Text(
              'Bus  Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),

          // Display bus numbers and their assigned student count
          
          SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getBusNumbersWithAssignedStudentCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No data available.'));
              } else {
                final data = snapshot.data!;
                return Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final entry = data[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16.0),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bus Number
                              Text(
                                'Bus Number: ${entry['busNumber']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),

                              // Assigned Students Count
                              Text(
                                'Assigned Students: ${entry['assignedCount']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(height: 4),

                              // Remaining Seats
                              Text(
                                'Remaining Seats: ${entry['remainingSeats']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Function to fetch bus numbers from 'buses' collection and count students assigned to each bus
  Future<List<Map<String, dynamic>>> _getBusNumbersWithAssignedStudentCount() async {
    // Fetch bus numbers and capacities from 'buses' collection
    QuerySnapshot busSnapshot = await FirebaseFirestore.instance.collection('buses').get();
    // Fetch students' assigned bus numbers from 'students' collection
    QuerySnapshot studentSnapshot = await FirebaseFirestore.instance.collection('students').get();

    // Create a map to store busNumber and assigned student count
    Map<String, int> busNumberCountMap = {};

    // Count how many students are assigned to each bus number
    for (var studentDoc in studentSnapshot.docs) {
      String assignedBusNumber = studentDoc['assignedBusNumber'];
      if (assignedBusNumber.isNotEmpty) {
        if (busNumberCountMap.containsKey(assignedBusNumber)) {
          busNumberCountMap[assignedBusNumber] = busNumberCountMap[assignedBusNumber]! + 1;
        } else {
          busNumberCountMap[assignedBusNumber] = 1;
        }
      }
    }

    // Prepare a list to hold bus numbers with their assigned student count and remaining seats
    List<Map<String, dynamic>> busDataWithCountsAndSeats = [];

    // For each bus number from the 'buses' collection, find the count of assigned students and capacity
    for (var busDoc in busSnapshot.docs) {
      String busNumber = busDoc['busNumber'];
      String capacityString = busDoc['capacity'];  // Capacity is stored as a string
      
      // Convert capacity to an integer, default to 0 if conversion fails
      int capacity = int.tryParse(capacityString) ?? 0;
      
      // Get the count of students assigned to the bus
      int studentCount = busNumberCountMap[busNumber] ?? 0;
      int remainingSeats = capacity - studentCount; // Calculate remaining seats

      busDataWithCountsAndSeats.add({
        'busNumber': busNumber,
        'assignedCount': studentCount,
        'remainingSeats': remainingSeats,
      });
    }

    return busDataWithCountsAndSeats;
  }
}