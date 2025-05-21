import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../widgets/custom_textfield.dart';
import 'parent_screen.dart';
import 'child_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  'assets/logo.png',
                  height: 250,
                  width: 250,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 20),

              CustomTextField(
                icon: Icons.person,
                hintText: 'Kullanıcı adı/Email',
                controller: _usernameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kullanıcı adınız hatalı';
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
                    return 'Şifreniz hatalı';
                  }
                  return null;
                },
              ),

              SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Şifremi Unuttum?',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),
              _buildSignInButton(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Hesabınız yok mu? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Kayıt ol',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return InkWell(
      onTap: () {
        if (_formKey.currentState!.validate()) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Rol Seç'),
                content: Text('Bu hesapla nasıl giriş yapmak istiyorsunuz?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ParentScreen(
                                username: _usernameController.text,
                              ),
                        ),
                      );
                    },
                    child: Text('Ebeveyn'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ChildScreen()),
                      );
                    },
                    child: Text('Çocuk'),
                  ),
                ],
              );
            },
          );
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
              'Giriş yap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
