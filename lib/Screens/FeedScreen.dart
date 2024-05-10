import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_me/Screens/AddFeelScreen.dart';
import 'package:social_me/Screens/ProfileScreen.dart';

class FeedScreen extends StatelessWidget {
  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserData() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    int maxRetries = 3; // Maksimum deneme sayısı
    int retryDelayMilliseconds = 1000; // Deneme aralığı (1 saniye)

    for (int i = 0; i < maxRetries; i++) {
      try {
        return await FirebaseFirestore.instance.collection('users').doc(userId).get();
      } catch (e) {
        if (i == maxRetries - 1) {
          throw e; // Maksimum deneme sayısına ulaşıldığında hatayı yukarı yönlendir
        }
        await Future.delayed(Duration(milliseconds: retryDelayMilliseconds));
      }
    }
    throw Exception('Veri alınamadı');
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getFeels() async {
    int maxRetries = 3; // Maksimum deneme sayısı
    int retryDelayMilliseconds = 1000; // Deneme aralığı (1 saniye)

    for (int i = 0; i < maxRetries; i++) {
      try {
        return await FirebaseFirestore.instance.collection('feels').orderBy('timestamp', descending: true).get();
      } catch (e) {
        if (i == maxRetries - 1) {
          throw e; // Maksimum deneme sayısına ulaşıldığında hatayı yukarı yönlendir
        }
        await Future.delayed(Duration(milliseconds: retryDelayMilliseconds));
      }
    }
    throw Exception('Veri alınamadı');
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
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Hata: ${snapshot.error}');
                } else {
                  Map<String, dynamic>? userData = snapshot.data?.data();
                  if (userData == null) {
                    return Text('Kullanıcı verileri yüklenirken bir hata oluştu.');
                  }
                  print(userData);
                  return Text(
                    'Merhaba, ${userData['name'] ?? 'İsim'} ${userData['surname'] ?? 'Soyisim'}!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );
                }
              },
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
                    List<QueryDocumentSnapshot<Map<String, dynamic>>> feels = snapshot.data?.docs ?? [];
                    return ListView.builder(
                      itemCount: feels.length,
                      itemBuilder: (context, index) {

                        Map<String, dynamic> feelData = feels[index].data();
                        Timestamp timestamp = feelData['timestamp'] ?? Timestamp.now();
                        DateTime date = timestamp.toDate();
                        print('Gönderen: ${feelData['userName']}');
                        String formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';

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
                                        String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                                        DocumentReference<Map<String, dynamic>> feelRef = FirebaseFirestore.instance.collection('feels').doc(feels[index].id);
                                        await FirebaseFirestore.instance.runTransaction((transaction) async {
                                          DocumentSnapshot<Map<String, dynamic>> feel = await transaction.get(feelRef);
                                          if (feel.exists) {
                                            List<dynamic>? likers = feel['beğenenlerListesi'];
                                            if (likers != null && likers.contains(userId)) {
                                              return;
                                            }

                                            int likes = feel['beğeniSayısı'] ?? 0;
                                            if (likers == null) {
                                              likers = [userId];
                                            } else {
                                              likers.add(userId);
                                            }
                                            transaction.update(feelRef, {'beğenenlerListesi': likers});
                                            transaction.update(feelRef, {'beğeniSayısı': likes + 1}); 
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                              content: Text('Yazıyı Beğendin.'),
                                              backgroundColor: Colors.green,
                                            ));
                                          }
                                        });
                                      },
                                      icon: Icon(Icons.thumb_up),
                                    ),

                                    SizedBox(width: 8),
                                    Text(
                                      '${feelData['beğeniSayısı'] ?? 0}',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Text('Gönderen: ${feelData['userName']} - $formattedDate'),

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
