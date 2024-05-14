import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddFeelScreen extends StatefulWidget {
  @override
  _AddFeelScreenState createState() => _AddFeelScreenState();
}

class _AddFeelScreenState extends State<AddFeelScreen> {
  final TextEditingController _feelController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _shareFeel(BuildContext context) async {
    String feel = _feelController.text.trim();
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (feel.isNotEmpty && userId.isNotEmpty) {
      CollectionReference feelsRef = FirebaseFirestore.instance.collection('feels');

      Map<String, dynamic> feelData = {
        'userId': userId,
        'feel': feel,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_image != null) {
        // Eğer bir resim seçilmişse, resmi Firebase Storage'a yükleyin
        String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        UploadTask uploadTask = FirebaseStorage.instance
            .ref(fileName)
            .putFile(_image!);

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        feelData['imageUrl'] = downloadUrl;
      }

      feelsRef.add(feelData).then((_) {
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
                suffixIcon: IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: _pickImage,
                ),
              ),
            ),
            SizedBox(height: 10),
            if (_image != null)
              Image.file(
                _image!,
                height: 150,
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
}
