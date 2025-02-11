import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _landmarkController = TextEditingController();
  XFile? _landmarkPicture;

  Future<String?> getDriverId() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final String? email = user?.email;

      if (email == null) {
        throw Exception("User email is null");
      }

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('driverEmail', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      } else {
        throw Exception("No matching driver found");
      }
    } catch (e) {
      print("Error fetching driver ID: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAssignedBusDetails(String driverId) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('assignedbus')
          .where('driverId', isEqualTo: driverId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        throw Exception("No assigned bus found for the driver");
      }
    } catch (e) {
      print("Error fetching assigned bus details: $e");
      return null;
    }
  }

  // Convert image to Base64 string
  Future<String?> _convertImageToBase64(XFile image) async {
    try {
      final File file = File(image.path);
      final List<int> imageBytes = await file.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      print("Error converting image to Base64: $e");
      return null;
    }
  }

  // Save landmark and picture in Base64 to Firestore
  Future<void> _saveLandmarkToFirestore(String landmark, String base64Image) async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email;

    if (email != null) {
      final CollectionReference collection =
          FirebaseFirestore.instance.collection('landmark');
      
      final QuerySnapshot querySnapshot = await collection.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing document
        final DocumentReference docRef = querySnapshot.docs.first.reference;
        await docRef.set({
          'landmark': landmark,
          'landmark_picture': base64Image,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Create new document
        await collection.add({
          'email': email,
          'landmark': landmark,
          'landmark_picture': base64Image,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      print("Landmark saved or updated successfully");
    }
  } catch (e) {
    print("Error saving or updating landmark in Firestore: $e");
  }
}

  // Open the edit dialog with text and image picker
  void _showEditDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Landmark and Picture'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Landmark Text Field
                TextField(
                  controller: _landmarkController,
                  decoration: const InputDecoration(labelText: 'Landmark'),
                ),
                const SizedBox(height: 16),

                // Landmark Picture (Image Picker)
                GestureDetector(
  onTap: () async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _landmarkPicture = pickedFile;
      });
    }
  },
  child: Container(
    width: 200,
    height: 200, // Provide a height constraint
    decoration: BoxDecoration(
      color: Colors.blue[50], 
      border: Border.all(color: Colors.blue, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: _landmarkPicture == null
        ? const Icon(Icons.add_a_photo, color: Colors.blue)
        : Image.file(
            File(_landmarkPicture!.path),
            fit: BoxFit.cover,
          ),
  ),
),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final landmarkText = _landmarkController.text.trim();

                if (landmarkText.isEmpty || _landmarkPicture == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                // Convert image to Base64
                final base64Image = await _convertImageToBase64(_landmarkPicture!);

                if (base64Image != null) {
                  // Save landmark text and Base64 image to Firestore
                  await _saveLandmarkToFirestore(landmarkText, base64Image);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Landmark saved successfully")),
                  );
                }
              },
              child: const Text('Save'),
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
      body: FutureBuilder<String?>(
        future: getDriverId(),
        builder: (context, driverIdSnapshot) {
          if (driverIdSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (driverIdSnapshot.hasError) {
            return Center(child: Text('Error: ${driverIdSnapshot.error}'));
          } else if (!driverIdSnapshot.hasData || driverIdSnapshot.data == null) {
            return const Center(child: Text('No driver ID found'));
          }

          final String driverId = driverIdSnapshot.data!;
          return FutureBuilder<Map<String, dynamic>?>(
            future: getAssignedBusDetails(driverId),
            builder: (context, busDetailsSnapshot) {
              if (busDetailsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (busDetailsSnapshot.hasError) {
                return Center(child: Text('Error: ${busDetailsSnapshot.error}'));
              } else if (!busDetailsSnapshot.hasData || busDetailsSnapshot.data == null) {
                return const Center(child: Text('No assigned bus details found'));
              }

              final Map<String, dynamic> busDetails = busDetailsSnapshot.data!;
              final fieldsToDisplay = {
                'Bus Number': busDetails['busNumber'] ?? 'N/A',
                'Capacity': busDetails['capacity'] ?? 'N/A',
                'Route Name': busDetails['routeName'] ?? 'N/A',
                'Stops': (busDetails['stops'] as List<dynamic>?)?.join(', ') ?? 'N/A',
              };

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 16.0, // Horizontal spacing between items
                      runSpacing: 16.0, // Vertical spacing between rows
                      children: fieldsToDisplay.entries.map((entry) {
                        return Container(
                          width: MediaQuery.of(context).size.width / 2 - 24, // Half width minus padding
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.blue[50], // Light blue background
                            border: Border.all(color: Colors.blue, width: 2), // Blue border
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue, // Label color
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8), // Spacing between name and value
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black, // Value color
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20), // Spacing before the edit button
                    GestureDetector(
                      onTap: () => _showEditDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.blue[100], // Light blue background
                          border: Border.all(color: Colors.blue, width: 2), // Blue border
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Edit Landmark and Picture',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}