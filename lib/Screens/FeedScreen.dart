import 'package:flutter/material.dart';
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
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getFeels() async {
    return await FirebaseFirestore.instance.collection('feels').orderBy('timestamp', descending: true).get();
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
                    List<QueryDocumentSnapshot<Map<String, dynamic>>> feels = snapshot.data?.docs ?? [];
                    return ListView.builder(
                      itemCount: feels.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> feelData = feels[index].data();
                        Timestamp timestamp = feelData['timestamp'] ?? Timestamp.now();
                        DateTime date = timestamp.toDate();
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
                                        // Buton işlemleri
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
                                Text('Gönderen: ${_userData!['name']} - $formattedDate'),
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
