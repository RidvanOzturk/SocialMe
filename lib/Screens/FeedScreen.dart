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

  Future<QuerySnapshot<Map<String, dynamic>>> _getFeels() async {
    return await FirebaseFirestore.instance
        .collection('feels')
        .orderBy('timestamp', descending: true)
        .get();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ANA SAYFA'),
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
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: _getFeels(),
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

                        return Card(
                          child: ListTile(
                            title: Text(feelData['feel'] ?? ''),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        print('butona tıklandı');
                                        String userId = FirebaseAuth
                                                .instance.currentUser?.uid ??
                                            '';
                                        DocumentReference<Map<String, dynamic>>
                                            feelRef = FirebaseFirestore.instance
                                                .collection('feels')
                                                .doc(feels[index].id);
                                        await FirebaseFirestore.instance
                                            .runTransaction(
                                                (transaction) async {
                                          DocumentSnapshot<Map<String, dynamic>>
                                              feel =
                                              await transaction.get(feelRef);
                                          if (feel.exists) {
                                            List<dynamic>? likers = feel
                                                .data()?['beğenenlerListesi'];

                                            if (likers != null &&
                                                likers.contains(userId)) {
                                              // Kullanıcı zaten beğenmiş, işlem yapmaya gerek yok
                                              return;
                                            }

                                            int likes =
                                                feel.data()?['beğeniSayısı'] ??
                                                    0;
                                            if (likers == null) {
                                              likers = [userId];
                                            } else {
                                              likers.add(userId);
                                            }
                                            transaction.update(feelRef, {
                                              'beğenenlerListesi': likers,
                                              'beğeniSayısı': likes + 1,
                                            });
                                            setState(() {
                                              feels[index].data()[
                                                  'beğenenlerListesi'] = likers;
                                              feels[index]
                                                      .data()['beğeniSayısı'] =
                                                  likes + 1;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text('Yazıyı Beğendin.'),
                                              backgroundColor: Colors.green,
                                            ));
                                          }
                                        });
                                      },
                                      icon: Icon(Icons.thumb_up),
                                    ),
                                    Text(
                                      '${feelData['beğeniSayısı'] ?? 0}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Text(
                                    'Gönderen: ${_userData!['name']} - $formattedDate'),
                              ],
                            ),
                          ),
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
