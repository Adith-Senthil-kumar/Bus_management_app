import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class scannerPage extends StatefulWidget {
  @override
  _scannerPageState createState() => _scannerPageState();
}

class _scannerPageState extends State<scannerPage> {
  String scannedBarcode = 'No barcode scanned yet';

  Future<void> scanBarcode() async {
  try {
    var result = await BarcodeScanner.scan();
    String scannedCode = result.rawContent;

    // Check if the scannedCode matches any document in the Firestore collection
    var querySnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('roll_no', isEqualTo: scannedCode)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Get the document ID of the matching document
      var documentId = querySnapshot.docs.first.id;

      // Update the 'present' field to true
      await FirebaseFirestore.instance
          .collection('students')
          .doc(documentId)
          .update({'present': true});

      setState(() {
        scannedBarcode = 'Attendance marked for roll no: $scannedCode';
      });
    } else {
      setState(() {
        scannedBarcode = 'No matching roll number found.';
      });
    }
  } catch (e) {
    setState(() {
      scannedBarcode = 'Failed to get barcode.';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Barcode scanner button
              ElevatedButton(
  onPressed: scanBarcode,
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Set text color to white
  ),
  child: const Text('Scan Barcode'),
),
              const SizedBox(height: 16),
              // Display scanned barcode
              Text(
                'Scanned Barcode: $scannedBarcode',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}