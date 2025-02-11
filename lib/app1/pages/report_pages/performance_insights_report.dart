import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PerformanceInsightsReport extends StatefulWidget {
  @override
  _PerformanceInsightsReportState createState() => _PerformanceInsightsReportState();
}

class _PerformanceInsightsReportState extends State<PerformanceInsightsReport> {
  bool _showBusDetails = true; // Initially showing bus details

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buttons to toggle between bus and driver details
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showBusDetails = true;
                    });
                  },
                  child: Text('Bus Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showBusDetails ? Color(0xFF3764A7) : Colors.grey, // Selected and Unselected colors
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showBusDetails = false;
                    });
                  },
                  child: Text('Driver Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_showBusDetails ? Color(0xFF3764A7) : Colors.grey, // Selected and Unselected colors
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Content based on button press (Bus Details or Driver Details)
            if (_showBusDetails) _buildBusDetailsSection() else _buildDriverDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusDetailsSection() {
    return FutureBuilder<List<Map<String, String>>>(
      future: _fetchBusDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No bus details available'));
        } else {
          return Column(
            children: snapshot.data!.map((busDetail) {
              return _buildBusPerformanceCard(busDetail['busNumber']!, busDetail['status']!);
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildDriverDetailsSection() {
    return FutureBuilder<List<Map<String, String>>>(
      future: _fetchDriverDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No driver details available'));
        } else {
          return Column(
            children: snapshot.data!.map((driverDetail) {
              return _buildDriverPerformanceCard(driverDetail['driverName']!, driverDetail['status']!);
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildBusPerformanceCard(String busNumber, String status) {
    return Card(
      elevation: 3,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Bus Number:', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(busNumber, style: TextStyle(fontSize: 16))),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Status:', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(status, style: TextStyle(fontSize: 16, color: Colors.blue))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverPerformanceCard(String driverName, String status) {
    return Card(
      elevation: 3,
      color: Colors.green[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Driver Name:', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(driverName, style: TextStyle(fontSize: 16))),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Status:', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(status, style: TextStyle(fontSize: 16, color: Colors.green))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, String>>> _fetchBusDetails() async {
    List<Map<String, String>> busDetails = [];
    QuerySnapshot busesSnapshot = await FirebaseFirestore.instance.collection('buses').get();
    QuerySnapshot assignedBusesSnapshot = await FirebaseFirestore.instance.collection('assignedbus').get();

    Set<String> assignedBusNumbers = assignedBusesSnapshot.docs.map((doc) => doc['busNumber'] as String).toSet();

    for (var doc in busesSnapshot.docs) {
      String busNumber = doc['busNumber'];
      String status = assignedBusNumbers.contains(busNumber) ? 'Active' : 'Not Active';
      busDetails.add({'busNumber': busNumber, 'status': status});
    }

    return busDetails;
  }

  Future<List<Map<String, String>>> _fetchDriverDetails() async {
    List<Map<String, String>> driverDetails = [];
    QuerySnapshot driversSnapshot = await FirebaseFirestore.instance.collection('drivers').get();
    QuerySnapshot assignedBusesSnapshot = await FirebaseFirestore.instance.collection('assignedbus').get();

    Set<String> assignedDriverNames = assignedBusesSnapshot.docs.map((doc) => doc['driverName'] as String).toSet();

    for (var doc in driversSnapshot.docs) {
      String driverName = doc['driverName'];
      String status = assignedDriverNames.contains(driverName) ? 'Active' : 'Not Active';
      driverDetails.add({'driverName': driverName, 'status': status});
    }

    return driverDetails;
  }
}