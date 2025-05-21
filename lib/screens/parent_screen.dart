import 'package:flutter/material.dart';

import '../widgets/add_child_modal.dart';
import 'child_detail_screen.dart';
import 'login_screen.dart';

class ParentScreen extends StatefulWidget {
  final String username; // Hoşgeldiniz mesajı için

  const ParentScreen({required this.username});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  // Şimdilik sabit verilerle çocuk listesi
  final List<Map<String, String>> children = [
    {'name': 'Ahmet', 'avatar': 'assets/avatars/boy1.png'},
    {'name': 'Ada', 'avatar': 'assets/avatars/girl1.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple.shade100,
        onPressed: () {
          AddChildModal.show(context, (name, avatar, code, email, password) {
            setState(() {
              children.add({'name': name, 'avatar': avatar});
            });

            // Buraya veritabanı kaydı, Firebase kaydı gibi işlemler ekleyebilirsin.
          });
        },
        child: Icon(Icons.add, color: Colors.deepPurple),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Center(
              child: Text(
                'E D A\n(Ebeveyn)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Times New Roman',
                  color: Colors.indigo.shade900,
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Hoşgeldiniz, ${widget.username}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 20),

            // Çocuklar listesi başlığı
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Çocuklar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),

                  // Grid ile çocukları göster
                  GridView.builder(
                    shrinkWrap: true,
                    itemCount: children.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemBuilder: (context, index) {
                      final child = children[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChildDetailScreen(
                                    childName: child['name']!,
                                    avatarPath: child['avatar']!,
                                    parentUsername: widget.username,
                                  ),
                            ),
                          );
                          // TODO: Çocuğa özel ekrana yönlendir
                          print("Tıklandı: ${child['name']}");
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                index % 2 == 0
                                    ? Colors.orangeAccent
                                    : Colors.deepPurple.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundImage: AssetImage(child['avatar']!),
                              ),
                              SizedBox(height: 8),
                              Text(
                                child['name']!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 5),
                              Icon(Icons.more_vert, color: Colors.white70),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // 🔓 Çıkış Butonu
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.logout, color: Colors.grey.shade800),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
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
