import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart'; // Import the CSV package

class DownloadPage extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> requestManageExternalStoragePermission() async {
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      print('Permission granted');
    } else {
      openAppSettings();
    }
  }

  Future<void> downloadCollection(String collectionName) async {
    await requestManageExternalStoragePermission(); // Request permission before downloading
    try {
      // Fetch documents from Firestore collection
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await firestore.collection(collectionName).get();

      // Convert documents to CSV format
      List<List<dynamic>> csvData = [];
      List<String> headers = []; // Extract headers from the first document
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        // Add document id as a separate field
        data['id'] = doc.id;

        if (headers.isEmpty) {
          // Get headers from the first document
          headers = data.keys.toList();
          csvData.add(headers); // Add headers as the first row in the CSV
        }

        // Handle field values
        List<dynamic> row = [];
        for (var header in headers) {
          var value = data[header];
          if (value is Timestamp) {
            value = value.toDate().toIso8601String(); // Convert timestamp to string
          }
          row.add(value);
        }
        csvData.add(row); // Add row to the CSV data
      }

      // Convert the data to CSV
      String csvString = const ListToCsvConverter().convert(csvData);

      // Save CSV to Downloads directory
      final directory = await getExternalStorageDirectory();
      final downloadsDirectory = Directory('/storage/emulated/0/Download'); // Use the standard Downloads folder path
      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      final file = File('${downloadsDirectory.path}/$collectionName.csv');
      await file.writeAsString(csvString);

      print('Collection downloaded successfully as CSV to ${file.path}');
    } catch (e) {
      print('Error downloading collection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 80.0), // Padding to the left of the title
          child: Text(
            'Download',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: gradient, // Set the gradient here
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // White back button
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: fetchCollections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching collections'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No collections found'));
          } else {
            final collections = snapshot.data!;
            return ListView.builder(
              itemCount: collections.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(collections[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.download),
                    onPressed: () {
                      downloadCollection(collections[index]);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<String>> fetchCollections() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await firestore.collection('metadata').get();
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
        List<String> collections = List<String>.from(doc.data()?['collections'] ?? []);
        return collections;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching collections: $e');
      return [];
    }
  }
}