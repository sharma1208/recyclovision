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
  Map<String, List<String>> subtypeOptions = {
    "plastic": ["HDPE", "PET", "PP", "LDPE", "LLDPE", "PS", "PVC"],
    "metal": ["aluminum cans", "aluminum ingot", "steel cans", "copper wire"],
    "paper": [
      "magazines/third-class mail",
      "newspaper",
      "office paper",
      "phone books",
      "textbooks",
      "mixed paper (general)",
      "mixed paper (primarily residential)",
      "mixed paper (primarily from offices)",
    ],
  };
  String? selectedSubtype;

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

  //Same logic as classifyimage, just now updating with subtypes based on drop
  //down selections. Update Hive as well.
  Future<void> submitSubtype(String material, String subtype) async {
    print("📤 Submitting subtype: $subtype for material: $material");
    final url = Uri.parse('http://192.168.1.21:5001/subtype');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"material": material, "subtype": subtype}),
      );

      print("📥 Subtype response status: ${response.statusCode}");
      print("📄 Subtype response body: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        print('Subtype Response Parsed: $parsed');

        // Update the UI
        setState(() {
          scanResult = parsed;
        });

        // Update Hive (overwrite the most recent record)
        final classification = ClassificationResult(
          material: parsed['material'],
          recyclable: parsed['recyclable'],
          recycledCarbonScore: parsed['recycled_carbon_score'],
          unrecycledCarbonScore: parsed['unrecycled_carbon_score'],
          carbonImpactRecycled: parsed['carbon_impact_rating_recycled'],
          carbonImpactUnrecycled: parsed['carbon_impact_rating_unrecycled'],
          recyclingrate: parsed['recycling_rate_percent'],
          hasSubtypes: parsed['has_subtypes'],
          notes: List<String>.from(parsed['notes'] ?? []),
        );

        final box = await Hive.openBox<ScanRecord>('scanRecords');

        // Get the latest record
        final lastKey = box.keys.last;
        final lastRecord = box.get(lastKey);

        if (lastRecord != null) {
          final updatedRecord = ScanRecord(
            imagePath: lastRecord.imagePath,
            classificationResult: classification,
            timestamp: lastRecord.timestamp,
          );

          await box.put(lastKey, updatedRecord);
          print('Hive record updated with subtype details.');
        }
      } else {
        print("Subtype request failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in submitSubtype: $e");
    }
  }

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: Colors.green,
          decorationThickness: 2,
        ),
      ),
    );
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
                                'Scanned: ${scanResult?['material'] ?? 'Unknown'}',
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
                            sectionHeader("♻️ Recycling Details:"),
                            infoRow(
                              Icons.check_circle,
                              Colors.green,
                              'Recyclable',
                              (scanResult?['recyclable'] ?? false)
                                  ? "Yes"
                                  : "No",
                            ),
                            infoRow(
                              Icons.percent,
                              Colors.deepPurple,
                              'Recycling Rate',
                              '${(scanResult?['recycling_rate_percent'] is double) ? (scanResult!['recycling_rate_percent'] as double).toStringAsFixed(1) : scanResult?['recycling_rate_percent'] ?? '--'}%',
                            ),

                            SizedBox(height: 16),

                            sectionHeader("🌍 Carbon Impact:"),
                            infoRow(
                              Icons.cloud,
                              Colors.blue,
                              'Recycled Score',
                              scanResult?['recycled_carbon_score'] ?? 'Unknown',
                            ),
                            infoRow(
                              Icons.cloud_queue,
                              Colors.orange,
                              'Unrecycled Score',
                              scanResult?['unrecycled_carbon_score'] ??
                                  'Unknown',
                            ),
                            infoRow(
                              Icons.eco,
                              Colors.teal,
                              'Impact (Recycled)',
                              scanResult?['carbon_impact_rating_recycled'] ??
                                  'Unknown',
                            ),
                            infoRow(
                              Icons.warning,
                              Colors.red,
                              'Impact (Unrecycled)',
                              scanResult?['carbon_impact_rating_unrecycled'] ??
                                  'Unknown',
                            ),

                            SizedBox(height: 16),

                            sectionHeader("📝 Notes:"),
                            scanResult?['notes'] != null &&
                                    (scanResult?['notes'] as List).isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: List<Widget>.from(
                                      (scanResult?['notes'] as List<dynamic>)
                                          .map(
                                            (note) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4.0,
                                                left: 12.0,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.circle,
                                                    size: 6,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Expanded(child: Text(note)),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ),
                                  )
                                : Text("No additional notes."),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                  if ((scanResult?['has_subtypes'] ?? false) &&
                      scanResult?['material'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select subtype:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedSubtype,
                            hint: Text("Choose subtype"),
                            items:
                                (subtypeOptions[scanResult!['material']
                                            .toString()
                                            .toLowerCase()] ??
                                        [])
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedSubtype = value;
                              });
                            },
                          ),
                          SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: selectedSubtype != null
                                ? () => submitSubtype(
                                    scanResult!['material'],
                                    selectedSubtype!,
                                  )
                                : null,
                            icon: Icon(Icons.send),
                            label: Text("Submit Subtype"),
                          ),
                        ],
                      ),
                    ),
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

  Widget infoRow(IconData icon, Color iconColor, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          SizedBox(width: 8),
          Text('$label: ${value ?? "--"}'),
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>> classifyImage(String imagePath) async {
  print("🚀 Starting upload and POST for image: $imagePath");
  // 1. Set URL to Flask server endpoint
  final url = Uri.parse('http://192.168.1.21:5001/detect');
  // 2. Create POST request w file attached
  final request = http.MultipartRequest('POST', url);
  request.files.add(await http.MultipartFile.fromPath('image', imagePath));
  print("📡 Sending request to backend...");
  // 3. Send the request and wait for the response
  final response = await request.send();
  print("📥 Received response with status: ${response.statusCode}");
  // 4. If it's successful (status 200), read and decode the response
  if (response.statusCode == 200) {
    final responseBody = await response.stream.bytesToString();
    final parsed = json.decode(responseBody);
    print('Server Response Parsed: $parsed');

    // Convert parsed map to ClassificationResult and ScanRecord
    final classification = ClassificationResult(
      material: parsed['material'],
      recyclable: parsed['recyclable'],
      recycledCarbonScore: parsed['recycled_carbon_score'],
      unrecycledCarbonScore: parsed['unrecycled_carbon_score'],
      carbonImpactRecycled: parsed['carbon_impact_rating_recycled'],
      carbonImpactUnrecycled: parsed['carbon_impact_rating_unrecycled'],
      recyclingrate: parsed['recycling_rate_percent'],
      hasSubtypes: parsed['has_subtypes'],
      notes: List<String>.from(parsed['notes'] ?? []),
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
      'material': 'Error',
      'recyclable': false,
      'recycled_carbon_score': null,
      'unrecycled_carbon_score': null,
      'carbon_impact_rating_recycled': 'Error',
      'carbon_impact_rating_unrecycled': 'Error',
      'recycling_rate_percent': null,
      'has_subtypes': false,
      'notes': ['Error occurred'],
    };
  }
}
