import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class StudentsPage extends StatefulWidget {
  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String? imageBase64;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search by name or email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('students').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final students = snapshot.data?.docs ?? [];

                final filteredStudents = students.where((student) {
                  final name = student['name'].toLowerCase();
                  final email = student['email'].toLowerCase();
                  final query = searchQuery.toLowerCase();
                  return name.contains(query) || email.contains(query);
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
  
  padding: EdgeInsets.only(bottom: 80.0),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final imageString = student['imageBase64'];
                    final image = imageString != null
                        ? CircleAvatar(
                            backgroundImage: MemoryImage(base64Decode(imageString)),
                            radius: 30,
                          )
                        : CircleAvatar(
                            child: Icon(Icons.person, size: 30),
                            radius: 30,
                          );
                    return Padding(
  padding: const EdgeInsets.all(8.0),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.blue[50],
      border: Border.all(color: Colors.blue, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    ),
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        // Left side content (Image and icons)
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image (Profile picture)
              CircleAvatar(
                backgroundImage: student['imageBase64'] != null
                    ? MemoryImage(base64Decode(student['imageBase64']))
                    : null,
                radius: 50,
                child: student['imageBase64'] == null
                    ? Icon(Icons.person, size: 30, color: Colors.grey)
                    : null,
              ),
              SizedBox(height: 2.0),
              // Icon buttons (Edit, Assign Bus, Delete)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.directions_bus),
                    color: Colors.green,
                    onPressed: () {
                      _showAssignBusDialog(context, student.id);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    color: Colors.orange,
                    onPressed: () {
                      _showEditStudentDialog(context, student);
                    },
                  ),
                  
                  IconButton(
                    icon: Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () {
                      _deleteStudent(student.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Right side content (Student details)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Text - Blue color for the name
              Text(
                student['name'] ?? 'No Name',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800], // Title in blue
                ),
              ),
              SizedBox(height: 8.0),
              // Regular Text - Black color for other details
              Text(
                'Email: ${student['email'] ?? 'No Email'}',
                style: TextStyle(color: Colors.black),
              ),
              Text(
                'Phone: ${student['phone'] ?? 'No Phone'}',
                style: TextStyle(color: Colors.black),
              ),
              Text(
                'Roll No: ${student['roll_no'] ?? 'No Roll No'}',
                style: TextStyle(color: Colors.black),
              ),
              Text(
                'Department: ${student['department'] ?? 'No Department'}',
                style: TextStyle(color: Colors.black),
              ),
              Text(
                'Year: ${student['year_of_study'] ?? 'No Year'}',
                style: TextStyle(color: Colors.black),
              ),
              Text(
                'Address: ${student['address'] ?? 'No Address'}',
                style: TextStyle(color: Colors.black),
              ),
              Text(
                'Assigned Bus: ${student['assignedBusNumber'] ?? 'None'}',
                style: TextStyle(color: Colors.black),
              ),
            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddStudentDialog(context);
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        imageBase64 = base64Encode(bytes);
      });
    }
  }

  void _showAddStudentDialog(BuildContext context) {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    rollNoController.clear();
    departmentController.clear();
    yearController.clear();
    addressController.clear();
    imageBase64 = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: imageBase64 == null
                      ? CircleAvatar(
                          child: Icon(Icons.person, size: 60),
                          radius: 50,
                        )
                      : CircleAvatar(
                          backgroundImage: MemoryImage(base64Decode(imageBase64!)),
                          radius: 60,
                        ),
                ),
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
                TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
                TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone')),
                TextField(controller: rollNoController, decoration: InputDecoration(labelText: 'Roll No')),
                TextField(controller: departmentController, decoration: InputDecoration(labelText: 'Department')),
                TextField(controller: yearController, decoration: InputDecoration(labelText: 'Year of Study')),
                TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                _addStudent();
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // The rest of the code remains unchanged (e.g., `_editStudent`, `_deleteStudent`, `_assignBusToStudent`, etc.)

  Future<void> _showEditStudentDialog(BuildContext context, DocumentSnapshot student) async {
    nameController.text = student['name'];
    emailController.text = student['email'];
    phoneController.text = student['phone'];
    rollNoController.text = student['roll_no'];
    departmentController.text = student['department'];
    yearController.text = student['year_of_study'];
    addressController.text = student['address'];
    imageBase64 = student['imageBase64'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                onTap: _pickImage,
                child: imageBase64 == null
                    ? CircleAvatar(
                        child: Icon(Icons.person, size: 30),
                        radius: 30,
                      )
                    : CircleAvatar(
                        backgroundImage: MemoryImage(base64Decode(imageBase64!)),
                        radius: 30,
                      ),
              ),
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
                TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
                TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone')),
                TextField(controller: rollNoController, decoration: InputDecoration(labelText: 'Roll No')),
                TextField(controller: departmentController, decoration: InputDecoration(labelText: 'Department')),
                TextField(controller: yearController, decoration: InputDecoration(labelText: 'Year of Study')),
                TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                _editStudent(student.id);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addStudent() async {
  final name = nameController.text;
  final email = emailController.text;
  final phone = phoneController.text;
  final rollNo = rollNoController.text;
  final department = departmentController.text;
  final year = yearController.text;
  final address = addressController.text;

  if (name.isEmpty || email.isEmpty || imageBase64 == null) return;

  try {
    await FirebaseFirestore.instance.collection('students').add({
      'name': name,
      'email': email,
      'phone': phone,
      'roll_no': rollNo,
      'department': department,
      'year_of_study': year,
      'address': address,
      'imageBase64': imageBase64,
      'assignedBusId': 'None',
      'assignedBusNumber': 'None',
      'present': false, // New field added
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student added successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error adding student: $e')),
    );
  }
}
  Future<void> _editStudent(String studentId) async {
    final name = nameController.text;
    final email = emailController.text;
    final phone = phoneController.text;
    final rollNo = rollNoController.text;
    final department = departmentController.text;
    final year = yearController.text;
    final address = addressController.text;

    if (name.isEmpty || email.isEmpty || imageBase64 == null) return;

    try {
      await FirebaseFirestore.instance.collection('students').doc(studentId).update({
        'name': name,
        'email': email,
        'phone': phone,
        'roll_no': rollNo,
        'department': department,
        'year_of_study': year,
        'address': address,
        'imageBase64': imageBase64,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Student updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating student: $e')));
    }
  }

  Future<void> _deleteStudent(String studentId) async {
  bool? confirmDelete = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Delete Student'),
        content: Text('Are you sure you want to delete this student? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmDelete == true) {
    try {
      await FirebaseFirestore.instance.collection('students').doc(studentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Student deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting student: $e')));
    }
  }
}

  Future<List<QueryDocumentSnapshot>> fetchBuses() async {
    try {
      final busesSnapshot = await FirebaseFirestore.instance.collection('assignedbus').get();
      return busesSnapshot.docs;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching buses: $e')));
      return [];
    }
  }

  void _showAssignBusDialog(BuildContext context, String studentId) async {
    final buses = await fetchBuses();
    String? selectedBusId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign Bus'),
          content: DropdownButtonFormField<String>(
            value: selectedBusId,
            items: buses.map((bus) {
              return DropdownMenuItem<String>(
                value: bus.id,
                child: Text(bus['busNumber'] ?? 'No Bus Number'),
              );
            }).toList(),
            onChanged: (value) {
              selectedBusId = value;
            },
            decoration: InputDecoration(labelText: 'Select a bus'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                if (selectedBusId != null) {
                  _assignBusToStudent(studentId, selectedBusId!);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a bus')));
                }
              },
              child: Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignBusToStudent(String studentId, String busId) async {
    try {
      final busSnapshot = await FirebaseFirestore.instance.collection('assignedbus').doc(busId).get();

      if (busSnapshot.exists) {
        final busData = busSnapshot.data();
        final busNumber = busData?['busNumber'] ?? 'Unknown';

        await FirebaseFirestore.instance.collection('students').doc(studentId).update({
          'assignedBusId': busId,
          'assignedBusNumber': busNumber,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bus assigned successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bus not found')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning bus: $e')));
    }
  }
}