import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'models/scan_record.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_scaffold.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    scanBox = Hive.box<ScanRecord>('scanRecords');
  }

  void deleteScan(int index) async {
    await scanBox.deleteAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Scan History',
      backgroundColor: Colors.black,
      body: ValueListenableBuilder(
        valueListenable: scanBox.listenable(),
        builder: (context, Box<ScanRecord> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text(
                'No scans yet.',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            );
          }

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

          groupedRecords.forEach((_, list) {
            list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          });

          final Map<String, Color> headerColors = {
            'low': Colors.greenAccent,
            'medium': Colors.orangeAccent,
            'high': Colors.redAccent,
            'unknown': Colors.grey,
          };

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: groupedRecords.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((entry) {
                  final label =
                      '${entry.key[0].toUpperCase()}${entry.key.substring(1)} Impact';
                  final color = headerColors[entry.key] ?? Colors.white;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          collapsedTextColor: color,
                          textColor: color,
                          iconColor: color,
                          collapsedIconColor: color,
                          title: Text(
                            label,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          children: entry.value
                              .map((record) {
                                final recordIndex = box.values.toList().indexOf(
                                  record,
                                );
                                return ScanCard(
                                  scanRecord: record,
                                  onDelete: () => deleteScan(recordIndex),
                                );
                              })
                              .toList()
                              .animate(delay: 200.ms)
                              .fade(duration: 600.ms)
                              .slideY(begin: 0.1),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.grey[850],
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        title: Text(
          scanRecord.classificationResult.material ?? 'Unknown Material',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'Scanned on: ${scanRecord.timestamp?.toLocal().toString().split('.')[0] ?? 'Unknown'}',
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: onDelete,
          tooltip: 'Delete this scan',
        ),
        onTap: () => _showDetailsDialog(context, scanRecord),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, ScanRecord scanRecord) {
    final result = scanRecord.classificationResult;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.greenAccent[200],
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal scroll wrapping the details row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize
                        .min, // IMPORTANT to prevent infinite width error
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            '🔍 Material:',
                            result.material ?? 'Unknown',
                          ),
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
                                ? result.unrecycledCarbonScore!.toStringAsFixed(
                                    2,
                                  )
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
                          _buildDetailRow(
                            '📅 Timestamp:',
                            scanRecord.timestamp?.toLocal().toString() ?? 'N/A',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (result.notes != null && result.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '📝 Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.greenAccent[200],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...result.notes!.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "• ",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.greenAccent,
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              note,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize
            .min, // Prevent infinite width error in horizontal scroll
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            // Use Flexible with loose fit, NOT Expanded
            fit: FlexFit.loose,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
