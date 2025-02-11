import 'dart:convert'; // For base64 encoding and decoding
import 'dart:typed_data'; // For Uint8List
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:flutter/material.dart'; // For Flutter widgets
import 'package:image_picker/image_picker.dart'; // For image picking

class DriversPage extends StatefulWidget {
  @override
  _DriversPageState createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController driverEmailController = TextEditingController();
  final TextEditingController driverPhoneController = TextEditingController();
  final TextEditingController driverLicenseController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  Uint8List? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDriverDialog(context);
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Drivers',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('drivers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final drivers = snapshot.data?.docs ?? [];
                final filteredDrivers = drivers.where((driver) {
                  final driverName =
                      driver['driverName'].toString().toLowerCase();
                  return driverName.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDrivers.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: 80.0),
                  itemBuilder: (context, index) {
                    final driver = filteredDrivers[index];
                    final driverName = driver['driverName'];
                    final driverEmail = driver['driverEmail'];
                    final driverPhone = driver['driverPhone'];
                    final driverLicense = driver['driverLicense'];
                    final profilePic = driver['profile_pic'];
                    final driverId = driver.id;

                    Uint8List? profilePicBytes;
                    if (profilePic != null) {
                      profilePicBytes = base64Decode(profilePic);
                    }

                    return 
  Padding(
  padding: const EdgeInsets.all(8.0),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.blue[50],
      border: Border.all(color: Colors.blue, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        // Left side content (Profile picture and icons) aligned to the left
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile picture at the top-left
              CircleAvatar(
                radius: 40,
                backgroundImage: profilePicBytes != null
                    ? MemoryImage(profilePicBytes)
                    : null,
                child: profilePicBytes == null
                    ? Icon(Icons.person)
                    : null,
              ),
              SizedBox(height: 8),
              // Edit and delete icons at the bottom-left
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmationDialog(
                          context, driverId, driverName, driverEmail);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _showEditDriverDialog(
                          context,
                          driverId,
                          driverName,
                          driverEmail,
                          driverPhone,
                          driverLicense,
                          profilePic);
                    },
                  ),
                  
                ],
              ),
            ],
          ),
        ),

        // Right side content (Driver details)
        Flexible(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver name, which will wrap if too long
                Text(
                  driverName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 0, 0),  // Title in blue
                  ),
                  overflow: TextOverflow.ellipsis,  // Handle overflow by truncating with ellipsis
                  maxLines: 1,  // Limit to one line
                ),
                SizedBox(height: 8),
                // Email, Phone, License with black text and blue titles
                Text(
                  'Email:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 17, 101, 169),  // Title in blue
                  ),
                ),
                Text(
                  driverEmail,
                  style: TextStyle(color: Colors.black),  // Data in black
                ),
                SizedBox(height: 8),
                Text(
                  'Phone:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 17, 101, 169),  // Title in blue
                  ),
                ),
                Text(
                  driverPhone,
                  style: TextStyle(color: Colors.black),  // Data in black
                ),
                SizedBox(height: 8),
                Text(
                  'License:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 17, 101, 169),  // Title in blue
                  ),
                ),
                Text(
                  driverLicense,
                  style: TextStyle(color: Colors.black),  // Data in black
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    driverNameController.clear();
    driverEmailController.clear();
    driverPhoneController.clear();
    driverLicenseController.clear();
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Driver'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _selectedImage != null
                        ? MemoryImage(_selectedImage!)
                        : null,
                    child:
                        _selectedImage == null ? Icon(Icons.add_a_photo) : null,
                  ),
                ),
                TextField(
                    controller: driverNameController,
                    decoration: InputDecoration(labelText: 'Driver Name')),
                TextField(
                    controller: driverEmailController,
                    decoration: InputDecoration(labelText: 'Driver Email'),
                    keyboardType: TextInputType.emailAddress),
                TextField(
                    controller: driverPhoneController,
                    decoration: InputDecoration(labelText: 'Driver Phone'),
                    keyboardType: TextInputType.phone),
                TextField(
                    controller: driverLicenseController,
                    decoration:
                        InputDecoration(labelText: 'Driver License Number')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                _addDriver();
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addDriver() async {
    final name = driverNameController.text;
    final email = driverEmailController.text;
    final phone = driverPhoneController.text;
    final license = driverLicenseController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        license.isEmpty ||
        _selectedImage == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('drivers').add({
        'driverName': name,
        'driverEmail': email,
        'driverPhone': phone,
        'driverLicense': license,
        'profile_pic':
            base64Encode(_selectedImage!),
        'location':GeoPoint(0,0),
         
      });

      _clearFields();
    } catch (e) {
      print('Error adding driver: $e');
    }
  }

  void _showEditDriverDialog(
      BuildContext context,
      String driverId,
      String driverName,
      String driverEmail,
      String driverPhone,
      String driverLicense,
      String? profilePic) {
    driverNameController.text = driverName;
    driverEmailController.text = driverEmail;
    driverPhoneController.text = driverPhone;
    driverLicenseController.text = driverLicense;
    _selectedImage = profilePic != null ? base64Decode(profilePic) : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Driver'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _selectedImage != null
                        ? MemoryImage(_selectedImage!)
                        : null,
                    child:
                        _selectedImage == null ? Icon(Icons.add_a_photo) : null,
                  ),
                ),
                TextField(
                    controller: driverNameController,
                    decoration: InputDecoration(labelText: 'Driver Name')),
                TextField(
                    controller: driverEmailController,
                    decoration: InputDecoration(labelText: 'Driver Email'),
                    keyboardType: TextInputType.emailAddress),
                TextField(
                    controller: driverPhoneController,
                    decoration: InputDecoration(labelText: 'Driver Phone'),
                    keyboardType: TextInputType.phone),
                TextField(
                    controller: driverLicenseController,
                    decoration:
                        InputDecoration(labelText: 'Driver License Number')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                _editDriver(driverId);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editDriver(String driverId) async {
    final name = driverNameController.text;
    final email = driverEmailController.text;
    final phone = driverPhoneController.text;
    final license = driverLicenseController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || license.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({
        'driverName': name,
        'driverEmail': email,
        'driverPhone': phone,
        'driverLicense': license,
        if (_selectedImage != null)
          'profile_pic':
              base64Encode(_selectedImage!), // Update image if selected
      });

      _clearFields();
    } catch (e) {
      print('Error editing driver: $e');
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String driverId,
      String driverName, String driverEmail) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete driver $driverName?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                _deleteDriver(driverId, driverEmail);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDriver(String driverId, String driverEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .delete();
      
    } catch (e) {
      print('Error deleting driver: $e');
    }
  }

  void _clearFields() {
    driverNameController.clear();
    driverEmailController.clear();
    driverPhoneController.clear();
    driverLicenseController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }
}
