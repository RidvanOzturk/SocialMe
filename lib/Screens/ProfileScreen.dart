import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final CollectionReference _userRef = FirebaseFirestore.instance.collection('users');
  final CollectionReference _feelsRef = FirebaseFirestore.instance.collection('feels');
  List<DocumentSnapshot> _userFeels = [];

  @override
  void initState() {
    super.initState();
    _getUserFeels();
  }

  Future<void> _getUserFeels() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    QuerySnapshot feelsSnapshot = await _feelsRef.where('userId', isEqualTo: userId).get();
    setState(() {
      _userFeels = feelsSnapshot.docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Düzenle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'İsim ve Soyisim',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'İsim'),
            ),
            TextFormField(
              controller: _surnameController,
              decoration: InputDecoration(labelText: 'Soyisim'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveChanges();
              },
              child: Text('Kaydet'),
            ),
            SizedBox(height: 20),
            Text(
              'Yazılarınız',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _userFeels.isNotEmpty
                  ? ListView.builder(
                itemCount: _userFeels.length,
                itemBuilder: (context, index) {
                  String feel = _userFeels[index]['feel'];
                  Timestamp timestamp = _userFeels[index]['timestamp'];
                  DateTime date = timestamp.toDate();
                  String formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feel,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Gönderme Tarihi: $formattedDate',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
                  : Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Text(
                    'Henüz bir yazınız bulunmamaktadır.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    String name = _nameController.text.trim();
    String surname = _surnameController.text.trim();
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';


    _userRef.doc(userId).set({
      'name': name,
      'surname': surname,
    }).then((_) {
      // Kayıt başarılıysa
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profil başarıyla güncellendi.'),
        backgroundColor: Colors.green,
      ));
    }).catchError((error) {
      // Hata durumunda
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profil güncelleme hatası: $error'),
        backgroundColor: Colors.red,
      ));
    });
  }
}