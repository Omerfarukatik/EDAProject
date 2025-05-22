import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsageScreen extends StatefulWidget {
  final String childId;
  const UsageScreen({required this.childId});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  String selectedRange = 'Günlük';
  final List<String> ranges = ['Günlük', 'Haftalık', 'Aylık'];
  List<Map<String, dynamic>> entries = [];
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    fetchUsageData();
  }

  Future<void> fetchUsageData() async {
    final parentId = FirebaseAuth.instance.currentUser?.uid;
    if (parentId == null) return;

    final now = DateTime.now();
    final cutoff =
        selectedRange == 'Günlük'
            ? now.subtract(Duration(days: 1))
            : selectedRange == 'Haftalık'
            ? now.subtract(Duration(days: 7))
            : now.subtract(Duration(days: 30));

    final query =
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(widget.childId)
            .collection('screentime')
            .where('timestamp', isGreaterThanOrEqualTo: cutoff)
            .orderBy('timestamp', descending: true)
            .get();

    int totalMinutes = 0;
    final fetched = <Map<String, dynamic>>[];

    for (final doc in query.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      final appName = data['appName'] ?? 'Bilinmeyen';
      final minutes = (data['duration_minutes'] as num?)?.toInt() ?? 0;
      final icon = data['icon'] ?? '';

      totalMinutes += minutes;

      fetched.add({
        'appName': appName,
        'minutes': minutes,
        'timestamp': timestamp,
        'icon': icon,
      });
    }

    setState(() {
      entries = fetched;
      totalDuration = Duration(minutes: totalMinutes);
    });
  }

  String formatDuration(Duration d) =>
      "${d.inHours} sa ${d.inMinutes.remainder(60)} dk";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kullanım Takibi")),
      body: Column(
        children: [
          SizedBox(height: 16),
          Text(
            "Toplam Süre (${selectedRange})",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(formatDuration(totalDuration), style: TextStyle(fontSize: 22)),
          SizedBox(height: 16),
          DropdownButton<String>(
            value: selectedRange,
            items:
                ranges
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  selectedRange = v;
                });
                fetchUsageData();
              }
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final e = entries[index];
                final ts = e['timestamp'] as DateTime?;
                final iconBytes =
                    e['icon'].isNotEmpty ? base64Decode(e['icon']) : null;

                return ListTile(
                  leading:
                      iconBytes != null
                          ? CircleAvatar(
                            backgroundImage: MemoryImage(iconBytes),
                          )
                          : CircleAvatar(child: Icon(Icons.apps)),
                  title: Text(e['appName']),
                  subtitle: Text("${e['minutes']} dk | ${ts?.toLocal()}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
