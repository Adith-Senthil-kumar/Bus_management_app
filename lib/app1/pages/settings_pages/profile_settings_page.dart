import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For base64 decoding
import 'package:image_picker/image_picker.dart'; // Image Picker
import 'dart:io'; // For File

class ProfileSettingsPage extends StatefulWidget {
  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  String? _base64Image;
  String? _name;
  String? _phone;
  String? _email;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData(); // Fetch the data when the page is loaded
  }

  // Method to fetch profile data from Firestore
  Future<void> _fetchProfileData() async {
    try {
      var docSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .orderBy('timestamp', descending: true) // To get the latest document
          .limit(1)
          .get();

      if (docSnapshot.docs.isNotEmpty) {
        var docData = docSnapshot.docs[0].data();
        setState(() {
          _base64Image = docData['profile_picture'];
          _name = docData['name'];
          _phone = docData['phone'];
          _email = docData['email'];
          _nameController.text = _name ?? '';
          _phoneController.text = _phone ?? '';
          _emailController.text = _email ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print("No profile data found in Firestore.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching profile data: $e");
    }
  }

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      final bytes = imageFile.readAsBytesSync();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  // Method to update the profile data in Firestore
  Future<void> _updateProfileData() async {
    try {
      var docSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (docSnapshot.docs.isNotEmpty) {
        var docId = docSnapshot.docs[0].id;
        await FirebaseFirestore.instance.collection('admins').doc(docId).update({
          'profile_picture': _base64Image,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating profile.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(left: 63.0),
            child: Text(
              'Profile Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF3764A7),
                  Color(0xFF28497B),
                  Color(0xFF152741),
                ],
                stops: [0.36, 0.69, 1.0],
              ),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage, // Open image picker when tapped
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _base64Image == null
                              ? AssetImage('assets/placeholder.png')
                              : MemoryImage(base64Decode(_base64Image!)),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Editable name field
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'Name'),
                      ),
                      SizedBox(height: 10),
                      // Editable phone field
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(labelText: 'Phone'),
                      ),
                      SizedBox(height: 10),
                      // Editable email field
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Email'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateProfileData,
                        child: Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}