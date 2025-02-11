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
    return FutureBuilder<int>(
      future: _getTotalBusesCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return _buildKpiCard('Total Buses', snapshot.data.toString(), 'Total number of buses in the system');
        }
      },
    );
  }

  // Build Active Buses KPI Card with dynamic count from drivers collection
  Widget _buildActiveBusesKpiCard() {
    return FutureBuilder<int>(
      future: _getActiveBusesCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return _buildKpiCard('Active Buses', snapshot.data.toString(), 'Number of buses currently in operation');
        }
      },
    );
  }

  // Build Total Students KPI Card with dynamic count
  Widget _buildTotalStudentsKpiCard() {
    return FutureBuilder<int>(
      future: _getTotalStudentsCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return _buildKpiCard('Total Students', snapshot.data.toString(), 'Total number of students in the system');
        }
      },
    );
  }

  // Build Total Drivers KPI Card with dynamic count
  Widget _buildTotalDriversKpiCard() {
    return FutureBuilder<int>(
      future: _getTotalDriversCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return _buildKpiCard('Total Drivers', snapshot.data.toString(), 'Total number of drivers in the system');
        }
      },
    );
  }

  // Function to fetch total buses count from Firestore
  Future<int> _getTotalBusesCount() async {
    AggregateQuerySnapshot snapshot = await FirebaseFirestore.instance.collection('buses').count().get();
    return snapshot.count ?? 0; // Provide a default value of 0 if null
  }

  // Function to fetch active buses count from drivers collection in Firestore
  Future<int> _getActiveBusesCount() async {
    AggregateQuerySnapshot snapshot = await FirebaseFirestore.instance.collection('drivers').count().get();
    return snapshot.count ?? 0; // Provide a default value of 0 if null
  }

  // Function to fetch total students count from Firestore
  Future<int> _getTotalStudentsCount() async {
    AggregateQuerySnapshot snapshot = await FirebaseFirestore.instance.collection('students').count().get();
    return snapshot.count ?? 0; // Provide a default value of 0 if null
  }

  // Function to fetch total drivers count from Firestore
  Future<int> _getTotalDriversCount() async {
    AggregateQuerySnapshot snapshot = await FirebaseFirestore.instance.collection('drivers').count().get();
    return snapshot.count ?? 0; // Provide a default value of 0 if null
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