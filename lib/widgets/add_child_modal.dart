import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddChildModal {
  static void show(
    BuildContext context,
    Function(
      String id,
      String name,
      String avatar,
      String email,
      String password,
    )
    onChildAdded,
  ) {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    List<String> avatarList = [
      'assets/avatars/boy1.png',
      'assets/avatars/girl1.png',
      'assets/avatars/boy2.png',
      'assets/avatars/girl2.png',
    ];

    String selectedAvatar = avatarList[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Çocuk Ekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    Text('İsim'),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(hintText: 'Çocuğun adı'),
                    ),

                    SizedBox(height: 10),
                    Text('E-mail'),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(hintText: 'E-posta adresi'),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    SizedBox(height: 10),
                    Text('Şifre'),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(hintText: 'Şifre'),
                      obscureText: true,
                    ),

                    SizedBox(height: 15),
                    Text('Avatar Seç'),
                    SizedBox(height: 10),

                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: avatarList.length,
                        itemBuilder: (context, index) {
                          String avatar = avatarList[index];
                          return GestureDetector(
                            onTap:
                                () => setState(() => selectedAvatar = avatar),
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 8),
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      selectedAvatar == avatar
                                          ? Colors.deepPurple
                                          : Colors.transparent,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                backgroundImage: AssetImage(avatar),
                                radius: 30,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Oturum açmış bir ebeveyn bulunamadı.',
                                ),
                              ),
                            );
                            return;
                          }

                          final String name = _nameController.text.trim();
                          final String email = _emailController.text.trim();
                          final String password =
                              _passwordController.text.trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lütfen tüm alanları doldurun'),
                              ),
                            );
                            return;
                          }

                          try {
                            // Firestore'a çocuk ekle
                            await FirebaseFirestore.instance
                                .collection('parents')
                                .doc(currentUser.uid)
                                .collection('children')
                                .add({
                                  'name': name,
                                  'email': email,
                                  'avatar': selectedAvatar,
                                  'created_at': FieldValue.serverTimestamp(),
                                });

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Çocuk başarıyla eklendi'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata oluştu: $e')),
                            );
                          }
                        },

                        child: Text('Ekle'),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
