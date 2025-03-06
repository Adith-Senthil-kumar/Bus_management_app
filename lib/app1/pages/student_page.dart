import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Added sorting options
  String sortBy = "none";
  // Filter by specific year
  String? filterYear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search and Sort Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search field
                Expanded(
                  flex: 3,
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
                SizedBox(width: 8),
                // Sort dropdown
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: SizedBox(),
                      value: sortBy,
                      hint: Text("Sort by"),
                      items: [
                        DropdownMenuItem(
                            value: "none", child: Text("All Years")),
                        DropdownMenuItem(value: "year1", child: Text("Year 1")),
                        DropdownMenuItem(value: "year2", child: Text("Year 2")),
                        DropdownMenuItem(value: "year3", child: Text("Year 3")),
                        DropdownMenuItem(value: "year4", child: Text("Year 4")),
                        DropdownMenuItem(
                            value: "yearAsc", child: Text("Year (1→4)")),
                        DropdownMenuItem(
                            value: "yearDesc", child: Text("Year (4→1)")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          sortBy = value!;
                          // Set filterYear based on selection
                          if (value.startsWith("year") && value.length == 5) {
                            filterYear =
                                value.substring(4); // Extract the year number
                          } else {
                            filterYear = null; // No specific year filter
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('students').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final students = snapshot.data?.docs ?? [];

                // Filter students based on search query
                var filteredStudents = students.where((student) {
                  final name = student['name'].toString().toLowerCase();
                  final email = student['email'].toString().toLowerCase();
                  final query = searchQuery.toLowerCase();

                  // Apply both search and year filter if applicable
                  bool matchesSearch =
                      name.contains(query) || email.contains(query);

                  if (filterYear != null) {
                    String studentYear =
                        student['year_of_study']?.toString() ?? '';
                    return matchesSearch && studentYear == filterYear;
                  }

                  return matchesSearch;
                }).toList();

                // Sort students based on selected sort option
                if (sortBy == "yearAsc") {
                  filteredStudents.sort((a, b) {
                    final yearA =
                        int.tryParse(a['year_of_study']?.toString() ?? '0') ??
                            0;
                    final yearB =
                        int.tryParse(b['year_of_study']?.toString() ?? '0') ??
                            0;
                    return yearA.compareTo(yearB);
                  });
                } else if (sortBy == "yearDesc") {
                  filteredStudents.sort((a, b) {
                    final yearA =
                        int.tryParse(a['year_of_study']?.toString() ?? '0') ??
                            0;
                    final yearB =
                        int.tryParse(b['year_of_study']?.toString() ?? '0') ??
                            0;
                    return yearB.compareTo(yearA);
                  });
                }

                return filteredStudents.isEmpty
                    ? Center(child: Text('No students found'))
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.only(bottom: 80.0),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                border:
                                    Border.all(color: Colors.blue, width: 2.0),
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

                                        SizedBox(height: 2.0),
                                        // Icon buttons (Edit, Assign Bus, Delete)
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.directions_bus),
                                              color: Colors.green,
                                              onPressed: () {
                                                _showAssignBusDialog(
                                                    context, student.id);
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              color: Colors.orange,
                                              onPressed: () {
                                                _showEditStudentDialog(
                                                    context, student);
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title Text - Blue color for the name
                                        Text(
                                          student['name'] ?? 'No Name',
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .blue[800], // Title in blue
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        // Year highlighted with bold text
                                        Text(
                                          'Year: ${student['year_of_study'] ?? 'No Year'}',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                                          'Stop: ${student['stop'] ?? 'No stop'}',
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min, // Keeps the buttons tight together
        children: [
          FloatingActionButton(
            onPressed: () {
              _showAddStudentDialog(context);
            },
            child: Icon(Icons.add, color: Colors.white),
            backgroundColor: Colors.blue,
          ),
          SizedBox(height: 10), // Space between buttons
          FloatingActionButton(
            onPressed: () {
              _clearAssignedBusFields(); 
            },
            child: Icon(Icons.delete, color: Colors.white),
            backgroundColor: Colors.red, // Indicating a delete action
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    rollNoController.clear();
    departmentController.clear();
    yearController.clear();
    addressController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name')),
                TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email')),
                TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone')),
                TextField(
                    controller: rollNoController,
                    decoration: InputDecoration(labelText: 'Roll No')),
                TextField(
                    controller: departmentController,
                    decoration: InputDecoration(labelText: 'Department')),
                // Year dropdown with only 1-4 options
                DropdownButtonFormField<String>(
                  value: null,
                  items: [
                    DropdownMenuItem(value: "1", child: Text("Year 1")),
                    DropdownMenuItem(value: "2", child: Text("Year 2")),
                    DropdownMenuItem(value: "3", child: Text("Year 3")),
                    DropdownMenuItem(value: "4", child: Text("Year 4")),
                  ],
                  onChanged: (value) {
                    yearController.text = value ?? '';
                  },
                  decoration: InputDecoration(labelText: 'Year of Study'),
                ),
                TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Stop')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
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

  Future<void> _showEditStudentDialog(
      BuildContext context, DocumentSnapshot student) async {
    nameController.text = student['name'];
    emailController.text = student['email'];
    phoneController.text = student['phone'];
    rollNoController.text = student['roll_no'];
    departmentController.text = student['department'];
    yearController.text = student['year_of_study'];
    addressController.text = student['Stop'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name')),
                TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email')),
                TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone')),
                TextField(
                    controller: rollNoController,
                    decoration: InputDecoration(labelText: 'Roll No')),
                TextField(
                    controller: departmentController,
                    decoration: InputDecoration(labelText: 'Department')),
                // Year dropdown with only 1-4 options
                DropdownButtonFormField<String>(
                  value: yearController.text,
                  items: [
                    DropdownMenuItem(value: "1", child: Text("Year 1")),
                    DropdownMenuItem(value: "2", child: Text("Year 2")),
                    DropdownMenuItem(value: "3", child: Text("Year 3")),
                    DropdownMenuItem(value: "4", child: Text("Year 4")),
                  ],
                  onChanged: (value) {
                    yearController.text = value ?? '';
                  },
                  decoration: InputDecoration(labelText: 'Year of Study'),
                ),
                TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Stop')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
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

    if (name.isEmpty || email.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('students').add({
        'name': name,
        'email': email,
        'phone': phone,
        'roll_no': rollNo,
        'department': department,
        'year_of_study': year,
        'stop': address,
        'assignedBusId': 'None',
        'assignedBusNumber': 'None',
        'present': false,
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

  Future<void> _clearAssignedBusFields() async {
    try {
      // Get all documents from the "students" collection
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('students').get();

      // Iterate through each document and update the fields
      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        await document.reference.update({
          'assignedBusId': '', // Set to empty string
          'assignedBusNumber': '' // Set to empty string
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('All students unassigned from buses successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing assigned buses: $e')),
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

    if (name.isEmpty || email.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .update({
        'name': name,
        'email': email,
        'phone': phone,
        'roll_no': rollNo,
        'department': department,
        'year_of_study': year,
        'stop': address,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating student: $e')));
    }
  }

  Future<void> _deleteStudent(String studentId) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Student'),
          content: Text(
              'Are you sure you want to delete this student? This action cannot be undone.'),
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
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Student deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting student: $e')));
      }
    }
  }

  Future<List<QueryDocumentSnapshot>> fetchBuses() async {
    try {
      final busesSnapshot =
          await FirebaseFirestore.instance.collection('assignedbus').get();
      return busesSnapshot.docs;
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching buses: $e')));
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
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                if (selectedBusId != null) {
                  _assignBusToStudent(studentId, selectedBusId!);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a bus')));
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
      final busSnapshot = await FirebaseFirestore.instance
          .collection('assignedbus')
          .doc(busId)
          .get();

      if (busSnapshot.exists) {
        final busData = busSnapshot.data();
        final busNumber = busData?['busNumber'] ?? 'Unknown';

        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .update({
          'assignedBusId': busId,
          'assignedBusNumber': busNumber,
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Bus assigned successfully')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Bus not found')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error assigning bus: $e')));
    }
  }
}
