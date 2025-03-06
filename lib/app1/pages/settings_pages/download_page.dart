import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isDownloading = false;

  Future<bool> _checkAndRequestPermissions() async {
    // Android-specific permission handling
    if (Platform.isAndroid) {
      // For Android 13 (SDK 33) and above
      if (await Permission.photos.status.isDenied) {
        await Permission.photos.request();
      }

      // For Android 12 and below
      if (await Permission.storage.status.isDenied) {
        await Permission.storage.request();
      }

      // Special handling for manage external storage on older Android versions
      if (await Permission.manageExternalStorage.status.isDenied) {
        await Permission.manageExternalStorage.request();
      }

      // Check final status
      return await Permission.storage.isGranted || 
             await Permission.manageExternalStorage.isGranted ||
             await Permission.photos.isGranted;
    }

    // For iOS or other platforms
    return true;
  }

  Future<void> downloadCollection(String collectionName) async {
    // Check permissions
    bool hasPermission = await _checkAndRequestPermissions();
    
    if (!hasPermission) {
      // Show detailed permission dialog
      _showPermissionDialog();
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      // Fetch documents from Firestore collection
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await firestore.collection(collectionName).get();

      // Convert documents to CSV format
      List<List<dynamic>> csvData = [];
      List<String> headers = []; 
      
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;

        if (headers.isEmpty) {
          headers = data.keys.toList();
          csvData.add(headers);
        }

        List<dynamic> row = headers.map((header) {
          var value = data[header];
          return value is Timestamp 
            ? value.toDate().toIso8601String() 
            : value;
        }).toList();
        
        csvData.add(row);
      }

      // Convert the data to CSV
      String csvString = const ListToCsvConverter().convert(csvData);

      // Determine file path
      final Directory? downloadsDirectory = Platform.isAndroid 
        ? Directory('/storage/emulated/0/Download')  // Direct path for Android
        : await getApplicationDocumentsDirectory();

      if (downloadsDirectory == null) {
        _showErrorDialog('Could not access storage directory');
        return;
      }

      // Ensure directory exists
      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      // Create file
      final file = File('${downloadsDirectory.path}/$collectionName.csv');
      
      // Write the file
      await file.writeAsString(csvString);

      // Show download success dialog
      _showDownloadSuccessDialog(file);
    } catch (e) {
      print('Download error: $e');
      _showErrorDialog('Error downloading collection: $e');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permissions Required'),
        content: const Text(
          'This app needs storage permissions to download files. '
          'Please go to app settings and grant storage permissions.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showDownloadSuccessDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Successful'),
        content: Text('File saved to: ${file.path}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareFile(file);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File not found: ${file.path}')),
        );
        return;
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Download from Firestore Collection',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing file: $e')),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        const Color(0xFF3764A7),
        const Color(0xFF28497B),
        const Color(0xFF152741),
      ],
      stops: const [0.36, 0.69, 1.0],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Download Collections',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: fetchCollections(),
        builder: (context, snapshot) {
          if (_isDownloading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Downloading collection...'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text('Error fetching collections: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } 
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.collections_bookmark_outlined, size: 60),
                  SizedBox(height: 16),
                  Text('No collections found'),
                ],
              ),
            );
          }

          final collections = snapshot.data!;
          return ListView.separated(
            itemCount: collections.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  collections[index],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.blue),
                  onPressed: () => downloadCollection(collections[index]),
                ),
                leading: const Icon(Icons.file_copy_outlined),
              );
            },
          );
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
        return List<String>.from(doc.data()?['collections'] ?? []);
      } 
      
      return [];
    } catch (e) {
      print('Error fetching collections: $e');
      return [];
    }
  }
}