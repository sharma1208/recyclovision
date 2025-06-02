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
        //ValueListenable ensures automatic refresh
        valueListenable: scanBox
            .listenable(), //listens for changes in data and whenever change occurs, rebuilds UI
        builder: (context, Box<ScanRecord> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No scans yet.'));
          }

          return ListView.builder(
            //creates scrollable lists and only widgets for visible items
            itemCount: box.length, // # of saved scans
            itemBuilder: (context, index) {
              // index goes from 0 to box.length - 1
              final scan = box.getAt(
                index,
              )!; //fetches ScanRecord at the index, knowing it wont be null
              return ScanCard(
                //displays scan
                scanRecord: scan,
                onDelete: () => deleteScan(index),
              );
            },
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
          scanRecord.classificationResult.className ?? 'Unknown Material',
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
              _buildDetailRow('📝 Class Name:', result.className),
              _buildDetailRow('🔍 Material:', result.material),
              _buildDetailRow(
                '♻️ Recyclable:',
                result.recyclable ? 'Yes' : 'No',
              ),
              _buildDetailRow('🌱 Carbon Score:', result.carbonScore),
              const SizedBox(height: 10),
              _buildDetailRow('📅 Timestamp:', scanRecord.timestamp.toString()),
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
          Expanded(child: Text(value, softWrap: true)),
        ],
      ),
    );
  }
}
