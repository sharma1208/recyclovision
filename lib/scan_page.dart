import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; //lets us make http requests
import 'dart:convert'; // lets us convert JSON strings into Dart maps
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_record.dart';
import 'scan_historypage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_scaffold.dart';

class ScanPage extends StatefulWidget {
  final String imagePath;
  const ScanPage({super.key, required this.imagePath});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  Map<String, dynamic>? scanResult; // Nullable because it starts empty
  bool isLoading = true; // Track loading state
  int recycledItemCount = 0;
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
    _loadRecycledCount();
    classifyImage(widget.imagePath).then((result) {
      setState(() {
        scanResult = result;
        isLoading = false;
      });
    });
  }

  Future<void> _loadRecycledCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        recycledItemCount = prefs.getInt('recycledItemCount') ?? 0;
      });
    } catch (e) {
      print("⚠️ Failed to load recycled count: $e");
    }
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
          recycledCarbonScore: parsed['recycled_carbon_score'] is double
              ? parsed['recycled_carbon_score']
              : null,
          unrecycledCarbonScore: parsed['unrecycled_carbon_score'] is double
              ? parsed['unrecycled_carbon_score']
              : null,
          carbonImpactRecycled: parsed['carbon_impact_rating_recycled'],
          carbonImpactUnrecycled: parsed['carbon_impact_rating_unrecycled'],
          recyclingrate: parsed['recycling_rate_percent'] is double
              ? parsed['recycling_rate_percent']
              : null,
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

  void _markItemAsRecycled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int count = prefs.getInt('recycledItemCount') ?? 0;
      count += 1;
      await prefs.setInt('recycledItemCount', count);

      setState(() {
        recycledItemCount = count;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item marked as recycled! Total: $count'),
          backgroundColor: Colors.green,
        ),
      );

      if (count % 10 == 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RecyclingMiniGameDialog(
            onGameComplete: () {
              // maybe reward user here, update state, etc.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mini-game complete! 🎉')),
              );
            },
          ),
        );
      }
    } catch (e) {
      print('❌ SharedPreferences error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving recycled item count.'),
          backgroundColor: Colors.red,
        ),
      );
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
          decorationColor: Colors.greenAccent,
          decorationThickness: 2,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showMiniGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("🎉 Reward Unlocked!"),
        content: Text("You've recycled 10 items! Here's a bonus mini game 🎮"),
        actions: [
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = scanResult?['notes'] as List<dynamic>? ?? [];

    return AppScaffold(
      title: 'Scan Results',
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              ) // show spinner while loading
            : scanResult == null
            ? Center(
                child: Text(
                  'No data found.',
                  style: TextStyle(color: Colors.white70),
                ),
              ) // fallback if something went wrong
            : Column(
                children: [
                  SizedBox(height: 5),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      color: Colors.grey[900],
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
                                  color: Colors.greenAccent[400],
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

                            if ((scanResult?['has_subtypes'] ?? false) &&
                                scanResult?['material'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Text(
                                      "Subtype: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: selectedSubtype,
                                        hint: Text("Choose subtype"),
                                        isExpanded: true,
                                        dropdownColor: Colors.grey[850],
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
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
                                          if (value != null) {
                                            setState(() {
                                              selectedSubtype = value;
                                            });
                                            submitSubtype(
                                              scanResult!['material'],
                                              value,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            sectionHeader("♻️ Recycling Details:"),
                            infoRow(
                              Icons.check_circle,
                              Colors.greenAccent,
                              'Recyclable',
                              (scanResult?['recyclable'] ?? false)
                                  ? "Yes"
                                  : "No",
                            ),
                            infoRow(
                              Icons.percent,
                              Colors.deepPurpleAccent,
                              'Recycling Rate',
                              '${(scanResult?['recycling_rate_percent'] is double) ? (scanResult!['recycling_rate_percent'] as double).toStringAsFixed(1) : scanResult?['recycling_rate_percent'] ?? '--'}%',
                            ),

                            SizedBox(height: 16),

                            sectionHeader("🌍 Carbon Impact:"),
                            infoRow(
                              Icons.cloud,
                              Colors.lightBlueAccent,
                              'Recycled Score',
                              scanResult?['recycled_carbon_score'] != null
                                  ? (scanResult!['recycled_carbon_score']
                                            as double)
                                        .toStringAsFixed(2)
                                  : 'Unknown',
                            ),
                            infoRow(
                              Icons.cloud_queue,
                              Colors.orangeAccent,
                              'Unrecycled Score',
                              scanResult?['unrecycled_carbon_score'] != null
                                  ? (scanResult!['unrecycled_carbon_score']
                                            as double)
                                        .toStringAsFixed(2)
                                  : 'Unknown',
                            ),
                            infoRow(
                              Icons.eco,
                              Colors.tealAccent,
                              'Impact (Recycled)',
                              scanResult?['carbon_impact_rating_recycled'] ??
                                  'Unknown',
                            ),
                            infoRow(
                              Icons.warning,
                              Colors.redAccent,
                              'Impact (Unrecycled)',
                              scanResult?['carbon_impact_rating_unrecycled'] ??
                                  'Unknown',
                            ),

                            SizedBox(height: 16),

                            sectionHeader("📝 Notes:"),
                            if (notes.isNotEmpty) ...[
                              ...notes.map(
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
                                      Expanded(
                                        child: Text(
                                          note.toString(),
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else
                              Text(
                                "No additional notes.",
                                style: TextStyle(color: Colors.white38),
                              ),

                            if (scanResult?['recycled_carbon_score'] != null &&
                                scanResult?['recycled_carbon_score'] !=
                                    'Unknown') ...[
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: Icon(Icons.check),
                                label: Text("Mark as Recycled"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent[700],
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _markItemAsRecycled,
                              ),
                            ],
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[700],
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Scan History'),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          'Recycled Item Streak',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        RecycledItemTracker(recycledCount: recycledItemCount),
                      ],
                    ),
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
          Text(
            '$label: ${value ?? "--"}',
            style: TextStyle(color: Colors.white70),
          ),
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
      recycledCarbonScore: parsed['recycled_carbon_score'] is double
          ? parsed['recycled_carbon_score']
          : null,
      unrecycledCarbonScore: parsed['unrecycled_carbon_score'] is double
          ? parsed['unrecycled_carbon_score']
          : null,
      carbonImpactRecycled: parsed['carbon_impact_rating_recycled'],
      carbonImpactUnrecycled: parsed['carbon_impact_rating_unrecycled'],
      recyclingrate: parsed['recycling_rate_percent'] is double
          ? parsed['recycling_rate_percent']
          : null,
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

class RecycledItemTracker extends StatelessWidget {
  final int recycledCount;
  final int goal; // e.g. 10 items before reward

  const RecycledItemTracker({
    Key? key,
    required this.recycledCount,
    this.goal = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> segments = [];

    for (int i = 0; i < goal; i++) {
      bool isFilled = i < (recycledCount % goal);
      segments.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? Colors.green : Colors.grey[300],
              border: Border.all(color: Colors.black12),
            ),
          ),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: segments);
  }
}

class RecyclingMiniGameDialog extends StatefulWidget {
  final VoidCallback onGameComplete;

  RecyclingMiniGameDialog({required this.onGameComplete});

  @override
  _RecyclingMiniGameDialogState createState() =>
      _RecyclingMiniGameDialogState();
}

class _RecyclingMiniGameDialogState extends State<RecyclingMiniGameDialog> {
  // Items to sort, each with correct bin
  final List<_RecyclableItem> items = [
    _RecyclableItem(name: "Plastic Bottle", emoji: "🥤", correctBin: "Plastic"),
    _RecyclableItem(name: "Newspaper", emoji: "📰", correctBin: "Paper"),
  ];

  // Track items sorted correctly
  final Set<int> correctlySortedIndices = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎉 Recycling Mini-Game!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Drag each item to the correct bin below.'),
          const SizedBox(height: 12),
          // Draggable items row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              if (correctlySortedIndices.contains(index)) {
                // If sorted correctly, hide or show checkmark
                return Column(
                  children: [
                    Text(
                      items[index].emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                  ],
                );
              }
              return Draggable<int>(
                data: index,
                feedback: Material(
                  color: Colors.transparent,
                  child: Text(
                    items[index].emoji,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: Text(
                    items[index].emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
                child: Text(
                  items[index].emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["Plastic", "Paper", "Metal"].map((binName) {
                return Container(
                  width: 90,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ), // add some margin
                  child: DragTarget<int>(
                    builder: (context, candidateData, rejectedData) {
                      final isActive = candidateData.isNotEmpty;
                      return Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green[200]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? Colors.green : Colors.grey,
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              binName == "Plastic"
                                  ? Icons.local_drink
                                  : binName == "Paper"
                                  ? Icons.menu_book
                                  : Icons.inbox,
                              size: 48,
                              color: Colors.black87,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              binName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onWillAccept: (index) =>
                        !correctlySortedIndices.contains(index!) &&
                        items[index].correctBin == binName,
                    onAccept: (index) {
                      setState(() {
                        correctlySortedIndices.add(index);
                      });
                      if (correctlySortedIndices.length == items.length) {
                        // Game complete!
                        Future.delayed(const Duration(milliseconds: 500), () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('🎉 Well done!'),
                              content: const Text(
                                'You sorted all items correctly! Keep recycling! ♻️',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pop(); // Close congrats
                                    Navigator.of(
                                      context,
                                    ).pop(); // Close game dialog
                                    widget.onGameComplete();
                                  },
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecyclableItem {
  final String name;
  final String emoji;
  final String correctBin;

  _RecyclableItem({
    required this.name,
    required this.emoji,
    required this.correctBin,
  });
}
