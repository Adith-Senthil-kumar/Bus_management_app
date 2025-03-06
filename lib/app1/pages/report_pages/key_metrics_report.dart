import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KeyMetricsReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bus Overview Section
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Key Metrics',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              _buildTotalBusesKpiCard(),
              SizedBox(height: 16),
              _buildActiveBusesKpiCard(),
              SizedBox(height: 16),
              _buildTotalStudentsKpiCard(),
              SizedBox(height: 16),
              _buildTotalDriversKpiCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Build Total Buses KPI Card with dynamic count
  Widget _buildTotalBusesKpiCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('buses').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return _buildKpiCard('Total Buses', snapshot.data?.size.toString() ?? '0', 'Total number of buses in the system');
        }
      },
    );
  }

  // Build Active Buses KPI Card with dynamic count from drivers collection
  Widget _buildActiveBusesKpiCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('assignedbus').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return _buildKpiCard('Active Buses', snapshot.data?.size.toString() ?? '0', 'Number of buses currently in operation');
        }
      },
    );
  }

  // Build Total Students KPI Card with dynamic count
  Widget _buildTotalStudentsKpiCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').where('present', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return _buildKpiCard('Total Students', snapshot.data?.size.toString() ?? '0', 'Total number of students in the system');
        }
      },
    );
  }

  // Build Total Drivers KPI Card with dynamic count
  Widget _buildTotalDriversKpiCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return _buildKpiCard('Total Drivers', snapshot.data?.size.toString() ?? '0', 'Total number of drivers in the system');
        }
      },
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle) {
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
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 20, color: Colors.blue)),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}