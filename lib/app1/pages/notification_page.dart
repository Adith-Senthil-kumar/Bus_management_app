import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import DateFormat class
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';

class NotificationPage extends StatelessWidget {
  final TextEditingController sendTitleController = TextEditingController();
  final TextEditingController sendMessageController = TextEditingController();
  final TextEditingController editTitleController = TextEditingController();
  final TextEditingController editMessageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Gradient definition
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFF3764A7), // Gradient Color 1
        Color(0xFF28497B), // Gradient Color 2
        Color(0xFF152741), // Gradient Color 3
      ],
      stops: [0.36, 0.69, 1.0],
    );

    return WillPopScope(
      onWillPop: () async {
        context
            .read<NavigationBloc>()
            .add(NavigateToHome()); // Trigger bloc event
        Navigator.pop(context); // Handle back navigation
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Make the AppBar transparent
          elevation: 0, // Remove shadow
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: gradient, // Apply gradient to the AppBar
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),

          title: Padding(
            padding: const EdgeInsets.only(right: 50.0),
            child: Center(
              child: Text(
                'Notification',
                style: TextStyle(
                  color: Colors.white, // Set the title color to white
                  fontWeight: FontWeight.bold, // Optional: Make the title bold
                ),
              ),
            ),
          ),
        ),
        body: Container(
          color: Colors.white, // Set the background color to white
          child: Column(
            children: [
              // Send Notification Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: sendTitleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: sendMessageController,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final title = sendTitleController.text.trim();
                        final message = sendMessageController.text.trim();

                        if (title.isEmpty || message.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Title and Message cannot be empty')),
                          );
                          return;
                        }

                        try {
                          // Push notification to Firestore
                          await FirebaseFirestore.instance
                              .collection('notifications')
                              .add({
                            'title': title,
                            'message': message,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Notification sent successfully')),
                          );

                          // Clear fields
                          sendTitleController.clear();
                          sendMessageController.clear();

                          // Dismiss the keyboard
                          FocusScope.of(context).unfocus();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Failed to send notification: $e')),
                          );
                        }
                      },
                      child: Text('Send Notification'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF28497B),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No notifications available',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      );
                    }

                    final notifications = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification =
                            notifications[index].data() as Map<String, dynamic>;
                        final docId =
                            notifications[index].id; // Document ID for deletion
                        final title = notification['title'] ?? 'No Title';
                        final message = notification['message'] ?? 'No Message';
                        final timestamp =
                            (notification['timestamp'] as Timestamp?)?.toDate();

                        // Format the timestamp to display only the date
                        final formattedDate = timestamp != null
                            ? DateFormat('yyyy-MM-dd').format(timestamp)
                            : 'No Date';

                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: Colors.blue, width: 2), // Blue outline
                          ),
                          elevation: 4,
                          color: Colors.blue[50], // Light blue background
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black, // Title text color
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Text(
                                  message,
                                  style: TextStyle(
                                      color:
                                          Colors.black), // Subtitle text color
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Date: $formattedDate', // Display only the date
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: Colors.blue), // Edit icon in blue
                                  onPressed: () {
                                    // Handle the edit functionality here
                                    _showEditDialog(
                                        context, docId, title, message);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('notifications')
                                          .doc(docId)
                                          .delete();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Notification deleted successfully'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to delete notification: $e'),
                                        ),
                                      );
                                    }
                                  },
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
        ),
      ),
    );
  }

  // Function to show edit dialog
  void _showEditDialog(
      BuildContext context, String docId, String title, String message) {
    // Set initial values in the controllers for editing
    editTitleController.text = title;
    editMessageController.text = message;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Notification'),
          content: SingleChildScrollView(
            // Use SingleChildScrollView to ensure scrolling in case the keyboard appears
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editTitleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: editMessageController,
                  decoration: InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog on Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newTitle = editTitleController.text.trim();
                final newMessage = editMessageController.text.trim();

                if (newTitle.isEmpty || newMessage.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Title and Message cannot be empty')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  // Hide the keyboard before saving
                  FocusScope.of(context).unfocus();

                  // Update the notification in Firestore
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(docId)
                      .update({
                    'title': newTitle,
                    'message': newMessage,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Notification updated successfully')),
                  );

                  Navigator.pop(context); // Close the dialog after saving
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to update notification: $e')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
