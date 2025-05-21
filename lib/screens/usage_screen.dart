import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';

class UsageScreen extends StatefulWidget {
  @override
  _UsageScreenState createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  static const platform = MethodChannel('com.ekranhareketi/usage');

  Duration totalDuration = Duration.zero;
  List<Map<String, dynamic>> appUsages = [];

  String selectedRange = 'Günlük';
  final List<String> ranges = ['Günlük', 'Haftalık', 'Aylık'];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchUsageData(selectedRange);
    _timer = Timer.periodic(
      Duration(minutes: 15),
      (_) => fetchUsageData(selectedRange),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> openUsageAccessSettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.USAGE_ACCESS_SETTINGS',
    );
    await intent.launch();
  }

  Future<void> fetchUsageData(String filter) async {
    try {
      final result = await platform.invokeMethod('getUsageStats', {
        "range": filter,
      });
      final totalMs = (result['totalTime'] as num).toInt();
      final appsRaw = List.from(result['apps']);
      final List<Map<String, dynamic>> apps =
          appsRaw.map((item) {
            return {
              "appName": item["appName"] as String,
              "duration": (item["duration"] as num).toInt(),
              "icon": item["icon"] as String,
            };
          }).toList();

      setState(() {
        totalDuration = Duration(milliseconds: totalMs);
        appUsages = apps;
      });
    } catch (e) {
      print("Veri alınamadı: $e");
    }
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return "${hours.toString().padLeft(2, '0')} sa ${minutes.toString().padLeft(2, '0')} dk ${seconds.toString().padLeft(2, '0')} sn";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text('Kullanım Takibi')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İzin butonu
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: openUsageAccessSettings,
              icon: Icon(Icons.lock_open),
              label: Text("İzin Ver"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Süre kutusu
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Toplam Kullanım Süresi",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  formatDuration(totalDuration),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Zaman aralığı filtresi
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Zaman Aralığı:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                DropdownButton<String>(
                  value: selectedRange,
                  items:
                      ranges
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRange = value;
                      });
                      fetchUsageData(value);
                    }
                  },
                ),
              ],
            ),
          ),

          // Uygulama listesi
          Expanded(
            child: ListView.builder(
              itemCount: appUsages.length,
              itemBuilder: (context, index) {
                final app = appUsages[index];
                final duration = Duration(milliseconds: app['duration'] as int);
                final iconBase64 = app['icon'] as String;
                final iconBytes = base64Decode(iconBase64);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading:
                        iconBase64.isNotEmpty
                            ? CircleAvatar(
                              backgroundImage: MemoryImage(iconBytes),
                              radius: 24,
                            )
                            : CircleAvatar(child: Icon(Icons.apps), radius: 24),
                    title: Text(
                      app['appName'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(formatDuration(duration)),
                  ),
                );
              },
            ),
          ),
        ],
     ),
);
}
}