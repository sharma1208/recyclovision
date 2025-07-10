import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'models/scan_record.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ScanHistoryPage extends StatefulWidget {
  const ScanHistoryPage({super.key});

  @override
  State<ScanHistoryPage> createState() => _ScanHistoryPageState();
}

class _ScanHistoryPageState extends State<ScanHistoryPage> {
  late Box<ScanRecord> scanBox;

  @override
  void initState() {
    super.initState();
    scanBox = Hive.box<ScanRecord>('scanRecords'); //past scans stored locally
  }

  void deleteScan(int index) async {
    await scanBox.deleteAt(index);
    setState(() {}); // refresh the UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: Colors.green,
      ),
      body: ValueListenableBuilder(
        valueListenable: scanBox.listenable(),
        builder: (context, Box<ScanRecord> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No scans yet.'));
          }

          // Group records by carbonImpactUnrecycled
          final Map<String, List<ScanRecord>> groupedRecords = {
            'low': [],
            'medium': [],
            'high': [],
            'unknown': [],
          };

          for (int i = 0; i < box.length; i++) {
            final scan = box.getAt(i)!;
            final impact =
                scan.classificationResult.carbonImpactUnrecycled
                    ?.toLowerCase() ??
                'unknown';
            if (groupedRecords.containsKey(impact)) {
              groupedRecords[impact]!.add(scan);
            } else {
              groupedRecords['unknown']!.add(scan);
            }
          }

          // Sort within each group by most recent
          groupedRecords.forEach((_, list) {
            list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          });

          final Map<String, Color> headerColors = {
            'low': Colors.green,
            'medium': Colors.orange,
            'high': Colors.red,
            'unknown': Colors.grey,
          };

          return ListView(
            children: groupedRecords.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((entry) {
                  final label =
                      '${entry.key[0].toUpperCase()}${entry.key.substring(1)} Impact';
                  final color = headerColors[entry.key] ?? Colors.black;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(
                            label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          children: entry.value.map((record) {
                            final recordIndex = box.values.toList().indexOf(
                              record,
                            );
                            return ScanCard(
                              scanRecord: record,
                              onDelete: () => deleteScan(recordIndex),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          );
        },
      ),
    );
  }
}

class ScanCard extends StatelessWidget {
  final ScanRecord scanRecord;
  final VoidCallback onDelete;

  const ScanCard({Key? key, required this.scanRecord, required this.onDelete})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizedBox(width: 12);
    return Card(
      // Adds rounded corners and shadow
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Content of the card
      child: ListTile(
        // Title (e.g., scan name or material)
        title: Text(
          scanRecord.classificationResult.material ?? 'Unknown Material',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        // Subtitle (e.g., date scanned)
        subtitle: Text(
          'Scanned on: ${scanRecord.timestamp ?? 'Unknown date'}',
          style: const TextStyle(color: Colors.grey),
        ),

        // Trailing delete icon
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete, // Calls the onDelete callback
        ),

        // Optional: tap to show details
        onTap: () => _showDetailsDialog(context, scanRecord),

        // Example: show a detailed dialog (you can customize!)
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, ScanRecord scanRecord) {
    final result = scanRecord.classificationResult;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Scan Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          // Prevents overflow
          child: ListBody(
            children: [
              _buildDetailRow('🔍 Material:', result.material ?? 'Unknown'),
              _buildDetailRow(
                '♻️ Recyclable:',
                result.recyclable ? 'Yes' : 'No',
              ),
              _buildDetailRow(
                '📈 Recycling Rate:',
                result.recyclingrate != null
                    ? '${result.recyclingrate!.toStringAsFixed(1)}%'
                    : 'N/A',
              ),
              _buildDetailRow(
                '🌿 Recycled Carbon Score:',
                result.recycledCarbonScore != null
                    ? result.recycledCarbonScore!.toStringAsFixed(2)
                    : 'N/A',
              ),
              _buildDetailRow(
                '🔥 Carbon Score (without recycling):',
                result.unrecycledCarbonScore != null
                    ? result.unrecycledCarbonScore!.toStringAsFixed(2)
                    : 'N/A',
              ),
              _buildDetailRow(
                '✅ Carbon Impact (Recycled):',
                result.carbonImpactRecycled ?? 'N/A',
              ),
              _buildDetailRow(
                '⚠️ Carbon Impact (Not recycled):',
                result.carbonImpactUnrecycled ?? 'N/A',
              ),
              _buildDetailRow(
                '🧩 Has Subtypes:',
                result.hasSubtypes ? 'Yes' : 'No',
              ),
              const SizedBox(height: 10),
              _buildDetailRow('📅 Timestamp:', scanRecord.timestamp.toString()),

              if (result.notes != null && result.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  '📝 Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...result.notes!.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ", style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(note)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(child: Text(value ?? 'N/A', softWrap: true)),
        ],
      ),
    );
  }
}
