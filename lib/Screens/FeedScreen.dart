import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_me/Screens/AddFeelScreen.dart';
import 'package:social_me/Screens/ProfileScreen.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Map<String, dynamic>? _userData;

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserData() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getFeelsStream() {
    return FirebaseFirestore.instance
        .collection('feels')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return userDoc.data();
  }

  @override
  void initState() {
    super.initState();
    _getUserData().then((userData) {
      setState(() {
        _userData = userData.data();
      });
    });
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ANA SAYFA'),
        leading: null, // Geri dönme butonunu kaldırmak için leading'i null yapıyoruz
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userData != null)
              Text(
                'Merhaba, ${_userData!['name'] ?? 'İsim'} ${_userData!['surname'] ?? 'Soyisim'}!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getFeelsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  } else {
                    List<QueryDocumentSnapshot<Map<String, dynamic>>> feels =
                        snapshot.data?.docs ?? [];
                    return ListView.builder(
                      itemCount: feels.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> feelData = feels[index].data();
                        DateTime date = (feelData['timestamp'] as Timestamp)
                            .toDate()
                            .add(Duration(hours: 3)); // UTC+3 (Türkiye saati)
                        String formattedDate =
                            DateFormat.yMd().add_Hm().format(date);

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _getUserDetails(feelData['userId']),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (userSnapshot.hasError) {
                              return Center(child: Text('Hata: ${userSnapshot.error}'));
                            } else {
                              Map<String, dynamic>? userData = userSnapshot.data;
                              String currentUserId =
                                  FirebaseAuth.instance.currentUser?.uid ?? '';
                              bool isLiked = feelData['beğenenlerListesi'] != null &&
                                  feelData['beğenenlerListesi'].contains(currentUserId);

                              return GestureDetector(
                                onTap: feelData.containsKey('imageUrl')
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ImageScreen(
                                              imageUrl: feelData['imageUrl'],
                                              imageDescription: feelData['description'] ?? '',
                                              addedText: feelData['feel'] ?? '',
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Card(
                                  child: Stack(
                                    children: [
                                      ListTile(
                                        title: Text(feelData['feel'] ?? ''),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () async {
                                                        String userId = FirebaseAuth
                                                                .instance.currentUser?.uid ??
                                                            '';
                                                        DocumentReference<
                                                                Map<String, dynamic>>
                                                            feelRef =
                                                            FirebaseFirestore.instance
                                                                .collection('feels')
                                                                .doc(feels[index].id);
                                                        await FirebaseFirestore.instance
                                                            .runTransaction(
                                                                (transaction) async {
                                                          DocumentSnapshot<
                                                                  Map<String, dynamic>>
                                                              feel =
                                                              await transaction
                                                                  .get(feelRef);
                                                          if (feel.exists) {
                                                            List<dynamic>? likers =
                                                                feel.data()?[
                                                                    'beğenenlerListesi'];
                                                            int likes =
                                                                feel.data()?[
                                                                        'beğeniSayısı'] ??
                                                                    0;

                                                            if (likers != null &&
                                                                likers.contains(userId)) {
                                                              // Kullanıcı zaten beğenmiş, beğenisini kaldır
                                                              likers.remove(userId);
                                                              transaction.update(feelRef, {
                                                                'beğenenlerListesi': likers,
                                                                'beğeniSayısı': likes - 1,
                                                              });
                                                              ScaffoldMessenger.of(context)
                                                                  .showSnackBar(SnackBar(
                                                                content: Text(
                                                                    'Beğeniyi Kaldırdın.'),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ));
                                                            } else {
                                                              // Kullanıcı beğenmemiş, beğeni ekle
                                                              if (likers == null) {
                                                                likers = [userId];
                                                              } else {
                                                                likers.add(userId);
                                                              }
                                                              transaction.update(feelRef, {
                                                                'beğenenlerListesi': likers,
                                                                'beğeniSayısı': likes + 1,
                                                              });
                                                              ScaffoldMessenger.of(context)
                                                                  .showSnackBar(SnackBar(
                                                                content: Text(
                                                                    'Yazıyı Beğendin.'),
                                                                backgroundColor:
                                                                    Colors.green,
                                                              ));
                                                            }
                                                          }
                                                        });
                                                      },
                                                      icon: Icon(
                                                        Icons.thumb_up,
                                                        color: isLiked
                                                            ? Colors.purple
                                                            : null,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${feelData['beğeniSayısı'] ?? 0}',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    'Gönderen: ${userData?['name'] ?? 'Bilinmiyor'} - $formattedDate',
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (feelData.containsKey('imageUrl'))
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Icon(
                                            Icons.image,
                                            color: Colors.blue,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddFeelScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              icon: Icon(Icons.person),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageScreen extends StatelessWidget {
  final String imageUrl;
  final String imageDescription;
  final String addedText;

  ImageScreen({required this.imageUrl, required this.imageDescription, required this.addedText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resim Görüntüle'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0), // Border radius ekledik
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 300, // İsteğe bağlı, resmin genişliğini ayarlayabilirsiniz
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.black54,
              child: Text(
                addedText, // Resimle birlikte eklenen yazı
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
