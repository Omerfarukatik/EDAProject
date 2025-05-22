import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordAgainController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kayıt Ol')),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextField(
                  icon: Icons.person,
                  hintText: 'Ad Soyad',
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ad soyad gerekli';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                CustomTextField(
                  icon: Icons.lock,
                  hintText: 'Şifre',
                  obscureText: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                CustomTextField(
                  icon: Icons.lock,
                  hintText: 'Şifreyi Tekrar Girin',
                  obscureText: true,
                  controller: _passwordAgainController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifreyi tekrar girin';
                    } else if (value != _passwordController.text) {
                      return 'Şifreler uyuşmuyor';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                CustomTextField(
                  icon: Icons.email,
                  hintText: 'E-posta Adresi',
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta gerekli';
                    } else if (!RegExp(
                      r'^[^@]+@[^@]+\.[^@]+',
                    ).hasMatch(value)) {
                      return 'Geçerli bir e-posta girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                CustomTextField(
                  icon: Icons.phone,
                  hintText: 'Telefon Numarası',
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Telefon numarası gerekli';
                    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Sadece rakam giriniz';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // 🔘 Buton
                InkWell(
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        // Firebase Auth ile kullanıcı oluştur
                        final credential = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );

                        final uid = credential.user!.uid;

                        // Firestore'da parents/{uid} belgesini oluştur
                        await FirebaseFirestore.instance
                            .collection('parents')
                            .doc(uid)
                            .set({
                              'name': _usernameController.text.trim(),
                              'email': _emailController.text.trim(),
                              'phone': _phoneController.text.trim(),
                              'created_at': FieldValue.serverTimestamp(),
                            });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Kayıt başarılı, giriş sayfasına yönlendiriliyorsunuz',
                            ),
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        String message = 'Bir hata oluştu';
                        if (e.code == 'email-already-in-use') {
                          message = 'Bu e-posta zaten kullanılıyor';
                        } else if (e.code == 'weak-password') {
                          message = 'Şifre çok zayıf';
                        }

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF469FF9), Color(0xFF16224A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Kayıt Ol',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
