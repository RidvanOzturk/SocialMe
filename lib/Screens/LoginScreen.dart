import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_me/Screens/FeedScreen.dart';



class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );


      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FeedScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş başarısız! Lütfen e-posta ve şifrenizi kontrol edin.'),
        ),
      );

    }
  }

  Future<void> _signUp() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      print("Kayıt başarılı!");

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FeedScreen()),
      );
    } catch (e) {
      print("Kayıt başarısız! Hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social Me Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'E-posta'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Şifre'),
              obscureText: true,
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _signIn,
              child: Text('Giriş Yap'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _signUp,
              child: Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}