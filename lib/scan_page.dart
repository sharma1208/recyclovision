import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; //lets us make http requests
import 'dart:convert'; // lets us convert JSON strings into Dart maps
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_record.dart';
import 'scan_historypage.dart';

class ScanPage extends StatefulWidget {
  final String imagePath;
  const ScanPage({super.key, required this.imagePath});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  Map<String, dynamic>? scanResult; // Nullable because it starts empty
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    classifyImage(widget.imagePath).then((result) {
      setState(() {
        scanResult = result;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Results Page')),
      body: SingleChildScrollView(
        child: isLoading
            ? CircularProgressIndicator() // show spinner while loading
            : scanResult == null
            ? Text('No data found.') // fallback if something went wrong
            : Column(
                children: [
                  SizedBox(height: 5),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),

                      elevation: 6,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 🧾 Title
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                'Scanned: ${scanResult?['class_name'] ?? 'Unknown'}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Padding(
                              padding: EdgeInsets.only(bottom: 5.0),
                              child: kIsWeb
                                  ? Icon(
                                      Icons.image,
                                      size: 100,
                                      color: Colors.grey,
                                    )
                                  : Image.file(File(widget.imagePath)),
                            ),

                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Text(
                                "Environmental Impact:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.green,
                                  decorationThickness: 2,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            // ✅ info rows using helper
                            infoRow(
                              Icons.check_circle,
                              Colors.green,
                              'Recyclable',
                              (scanResult?['recyclable'] ?? false)
                                  ? "Yes"
                                  : "No",
                            ),
                            infoRow(
                              Icons.cloud,
                              Colors.amber,
                              'Carbon Score',
                              scanResult?['carbonScore'] ?? 'Unknown',
                            ),
                            infoRow(
                              Icons.science,
                              Colors.blue,
                              'Material',
                              scanResult?['material'] ?? 'Unknown',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScanHistoryPage(),
                        ),
                      );
                    },
                    child: const Text('Scan History'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget infoRow(IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          SizedBox(width: 8),
          Text('$label: $value'),
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>> classifyImage(String imagePath) async {
  // 1. Set URL to Flask server endpoint
  final url = Uri.parse('http://192.168.1.30:5001/detect');
  // 2. Create POST request w file attached
  final request = http.MultipartRequest('POST', url);
  request.files.add(await http.MultipartFile.fromPath('image', imagePath));

  // 3. Send the request and wait for the response
  final response = await request.send();

  // 4. If it's successful (status 200), read and decode the response
  if (response.statusCode == 200) {
    final responseBody = await response.stream.bytesToString();
    final parsed = json.decode(responseBody);
    print('Server Response Parsed: $parsed');

    // Convert parsed map to ClassificationResult and ScanRecord
    final classification = ClassificationResult(
      className: parsed['class_name'],
      recyclable: parsed['recyclable'],
      material: parsed['material'],
      carbonScore: parsed['carbonScore'],
    );

    final scanRecord = ScanRecord(
      imagePath: imagePath,
      classificationResult: classification,
      timestamp: DateTime.now(),
    );

    // Save to Hive
    final box = await Hive.openBox<ScanRecord>('scanRecords');
    await box.add(scanRecord);

    return parsed;
  } else {
    // 5. Handle errors (like 500 or 404)
    print("Failed with status code: ${response.statusCode}");
    return {
      'class_name': 'Error',
      'recyclable': false,
      'carbonScore': 'Error',
      'material': 'Error',
    };
  }
}
