import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

import '../widgets/custom_toggle_tile.dart';
import 'DuyguAnalizEkrani.dart';
import 'MapLocationPage.dart';
import 'select_child_screen.dart';

const platform = MethodChannel('com.ibekazi.edaui/channel');
const platform_k = MethodChannel("keyboard_monitor_channel");
const usageServiceChannel = MethodChannel("firebase_usage_channel");

class ChildScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String avatarPath;

  const ChildScreen({
    Key? key,
    required this.childId,
    required this.childName,
    required this.avatarPath,
  }) : super(key: key);

  @override
  _ChildScreenState createState() => _ChildScreenState();
}

class _ChildScreenState extends State<ChildScreen> {
  bool ekranHareketi = false;
  bool tarayiciGecmisi = false;
  bool konumTakibi = false;
  bool gorselAnaliz = false;
  bool duyguAnaliz = false;

  Timer? usageTimer;

  @override
  void initState() {
    super.initState();
  }

  Future<void> startFirebaseUsageService() async {
    try {
      final parentId = FirebaseAuth.instance.currentUser?.uid;
      if (parentId == null) return;

      await usageServiceChannel.invokeMethod("startUsageService", {
        "parentId": parentId,
        "childId": widget.childId,
      });
    } catch (e) {
      print("Firebase kullanımı servisi başlatılamadı: $e");
    }
  }

  void _navigateToMapLocationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapLocationPage()),
    );
  }

  @override
  void dispose() {
    usageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'E D A\n(Çocuk)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Times New Roman',
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  SizedBox(height: 10),
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage(widget.avatarPath),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.childName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Özellikler',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  SizedBox(height: 20),
                  CustomToggleTile(
                    title: 'Ekran Hareketi ve Süresi',
                    value: ekranHareketi,
                    onChanged: (val) async {
                      setState(() => ekranHareketi = val);
                      if (val) {
                        try {
                          // 1. Android ayar ekranına yönlendir
                          const usagePlatform = MethodChannel(
                            'com.ekranhareketi/usage',
                          );
                          await usagePlatform.invokeMethod('openUsageSettings');

                          // 2. Foreground service başlat (FirebaseUsageService.kt)
                          const firebaseUsageChannel = MethodChannel(
                            "firebase_usage_channel",
                          );
                          final parentId =
                              FirebaseAuth.instance.currentUser!.uid;
                          await firebaseUsageChannel.invokeMethod(
                            "startUsageService",
                            {"parentId": parentId, "childId": widget.childId},
                          );

                          
                          
                        } catch (e) {
                          print("Ekran izni veya servis başlatılamadı: $e");
                        }
                      } else {
                        
                      }
                    },
                  ),

                  CustomToggleTile(
                    title: 'Tarayıcı Geçmişi',
                    value: tarayiciGecmisi,
                    onChanged: (val) => setState(() => tarayiciGecmisi = val),
                  ),
                  CustomToggleTile(
                    title: 'Konum Takibi',
                    value: konumTakibi,
                    onChanged: (val) => setState(() => konumTakibi = val),
                  ),
                  CustomToggleTile(
                    title: 'Görsel Analiz',
                    value: gorselAnaliz,
                    onChanged: (val) async {
                      setState(() => gorselAnaliz = val);
                      if (val) {
                        try {
                          await platform.invokeMethod('startProjection');
                        } catch (e) {
                          print("Servis başlatılamadı: $e");
                        }
                      } else {
                        try {
                          await platform.invokeMethod('stopService');
                        } catch (e) {
                          print("Servis durdurulamadı: $e");
                        }
                      }
                    },
                  ),
                  CustomToggleTile(
                    title: 'Duygu Analizi',
                    value: duyguAnaliz,
                    onChanged: (val) async {
                      setState(() => duyguAnaliz = val);
                      if (val) {
                        try {
                          await platform_k.invokeMethod(
                            "openAccessibilitySettings",
                          );
                        } catch (e) {
                          print("İzin sayfası açılamadı: $e");
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DuyguAnalizEkrani(),
                        ),
                      );
                    },
                    child: Text("Duygu Analizi Sayfasına Git"),
                  ),
                  ElevatedButton(
                    onPressed: _navigateToMapLocationPage,
                    child: Text("Konum Sayfasına Git"),
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await platform.invokeMethod('hideApp');
                          } catch (e) {
                            print("Uygulama gizlenemedi: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 20,
                          ),
                        ),
                        child: Text(
                          'Gizle',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await platform.invokeMethod('stopService');
                          } catch (e) {
                            print("Servis durdurulamadı: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 20,
                          ),
                        ),
                        child: Text(
                          'Durdur',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.logout, color: Colors.grey.shade800),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectChildScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
