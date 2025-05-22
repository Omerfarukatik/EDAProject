import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'child_screen.dart';
import 'login_screen.dart';

class SelectChildScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text("Kullanıcı oturumu bulunamadı.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("EDA (Çocuk)")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('parents')
                .doc(currentUser!.uid)
                .collection('children')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Kayıtlı çocuk bulunamadı."));
          }

          final children = snapshot.data!.docs;

          return ListView.builder(
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              final name = child['name'];
              final avatar = child['avatar'];
              final childId = child.id;

              return ListTile(
                leading: CircleAvatar(backgroundImage: AssetImage(avatar)),
                title: Text(name),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChildScreen(
                            childId: childId,
                            childName: name,
                            avatarPath: avatar,
                          ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
