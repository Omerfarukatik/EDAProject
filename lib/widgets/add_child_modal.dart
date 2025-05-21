import 'package:flutter/material.dart';

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
                        onPressed: () {
                          final String id =
                              DateTime.now().millisecondsSinceEpoch.toString();
                          if (_nameController.text.isNotEmpty &&
                              _emailController.text.isNotEmpty &&
                              _passwordController.text.isNotEmpty) {
                            onChildAdded(
                              id,
                              _nameController.text,
                              selectedAvatar,
                              _emailController.text,
                              _passwordController.text,
                            );
                            Navigator.pop(context);
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
