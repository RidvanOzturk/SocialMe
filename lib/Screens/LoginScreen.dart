import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_me/Screens/FeedScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  bool _isSignUp = false;

  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş başarılı! :)'),
        ),
      );

      Navigator.pushReplacement(
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Firestore'a kullanıcı bilgilerini ekleyelim
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text,
        'surname': _surnameController.text,
        'email': _emailController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt Başarılı!'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FeedScreen()),
      );
    } catch (e) {
      String errorMessage = 'Bir hata oluştu.';
      if (e is FirebaseAuthException) {
        if (e.code == 'weak-password') {
          errorMessage = 'Şifreniz en az 6 karakter olmalıdır.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Bu e-posta adresi zaten kullanımda.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social Me Login Page'),
        leading: null, // Geri butonunu kaldırmak için leading'i null yapıyoruz
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSignUp) ...[
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Ad'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _surnameController,
                decoration: InputDecoration(labelText: 'Soyad'),
              ),
              SizedBox(height: 16.0),
            ],
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
              onPressed: _isSignUp ? _signUp : _signIn,
              child: Text(_isSignUp ? 'Kayıt Ol' : 'Giriş Yap'),
            ),
            SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                });
              },
              child: Text(_isSignUp ? 'Giriş Yap' : 'Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}
