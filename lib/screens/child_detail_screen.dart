import 'package:edadeneme/screens/usage_screen.dart';
import 'package:flutter/material.dart';
import 'parent_screen.dart';

class ChildDetailScreen extends StatelessWidget {
  final String childName;
  final String avatarPath;
  final String parentUsername;

  const ChildDetailScreen({
    required this.childName,
    required this.avatarPath,
    required this.parentUsername,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tiles = [
      {
        'title': 'Kullanım Hareketleri',
        'gradient': LinearGradient(colors: [Colors.blue, Colors.purple]),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UsageScreen()),
   );
},
      },
      {
        'title': 'Tarayıcı geçmişi',
        'gradient': LinearGradient(colors: [Colors.pink, Colors.purpleAccent]),
        'onTap': () {},
      },
      {
        'title': 'Duygu Analizi',
        'gradient': LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        'onTap': () {},
      },
      {
        'title': 'Görsel Analiz',
        'gradient': LinearGradient(
          colors: [Colors.amber, Colors.grey.shade300],
        ),
        'onTap': () {},
      },
      {
        'title': 'Konum Takibi',
        'gradient': LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade300],
        ),
        'onTap': () {},
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Mavi üst kart
          Positioned(
            top: 120,
            left: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade700, Colors.deepPurple.shade300],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.white, size: 40),
                      SizedBox(height: 1),
                      Text(
                        'İstatistikler',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ParentScreen(username: parentUsername),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Icon(Icons.home, color: Colors.white, size: 40),
                        SizedBox(height: 1),
                        Text(
                          'Ana Menü',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Icon(Icons.settings, color: Colors.white, size: 40),
                      SizedBox(height: 1),
                      Text(
                        'Ayarlar',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(avatarPath),
                        radius: 40,
                      ),
                      SizedBox(height: 1),
                      Text(
                        childName,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Başlık üstte
          Positioned(
            top: 70,
            left: 20,
            child: Text(
              'E D A (Ebeveyn)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Times New Roman',
                color: Colors.indigo.shade900,
              ),
            ),
          ),

          // Merdiven gibi üst üste binen kartlar
          Positioned.fill(
            top: 270,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Stack(
                children: List.generate(tiles.length, (index) {
                  final tile = tiles[index];
                  return Positioned(
                    top: index * 108,
                    left: 0,
                    right: index * 27,
                    child: GestureDetector(
                      onTap: tile['onTap'],
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: tile['gradient'],
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/backgrounds/bg_${index + 1}.png',
                            ),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.15),
                              BlendMode.dstATop,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          tile['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
