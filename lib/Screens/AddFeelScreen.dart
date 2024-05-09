import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFeelScreen extends StatelessWidget {
  final TextEditingController _feelController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hissinizi Ekle'),
      ),
      body: Container(
        color: Colors.blue,
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Özgürce ne düşünüyorsanız yazın:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _feelController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Düşüncelerinizi buraya yazın',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _shareFeel(context);
              },
              child: Text('Paylaş'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareFeel(BuildContext context) {
    String feel = _feelController.text.trim();
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (feel.isNotEmpty && userId.isNotEmpty) {

      CollectionReference feelsRef = FirebaseFirestore.instance.collection('feels');


      feelsRef.add({
        'userId': userId,
        'feel': feel,
        'timestamp': FieldValue.serverTimestamp(),
      }).then((_) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hissiniz başarıyla paylaşıldı.'),
          backgroundColor: Colors.green,
        ));
      }).catchError((error) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hissinizi paylaşırken bir hata oluştu: $error'),
          backgroundColor: Colors.red,
        ));
      });
    } else {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen bir his yazın.'),
        backgroundColor: Colors.red,
      ));
    }
  }
}