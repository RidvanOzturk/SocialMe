import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:social_me/Screens/AddFeelScreen.dart';
import 'package:social_me/Screens/LoginScreen.dart';
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
  if (userId.isNotEmpty) { // userId boş değilse devam et
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data();
  } else {
    print('Hata: userId boş veya eksik');
    return null; // Eğer userId boş ise null döndür
  }
}



  @override
  void initState() {
    super.initState();
    _getUserData().then((userData) {
      setState(() {
        _userData = (userData.data() as Map<String, dynamic>?)!;
      });
    });
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ANA SAYFA'),
        leading: null,
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
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (userSnapshot.hasError) {
                              return Center(
                                  child: Text('Hata: ${userSnapshot.error}'));
                            } else {
                              Map<String, dynamic>? userData =
                                  userSnapshot.data;
                              String currentUserId =
                                  FirebaseAuth.instance.currentUser?.uid ?? '';
                              bool isLiked =
                                  feelData['beğenenlerListesi'] != null &&
                                      feelData['beğenenlerListesi']
                                          .contains(currentUserId);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostDetailScreen(
                                        postId: feels[index].id,
                                        feelData: feelData,
                                        userData: userData,
                                        formattedDate: formattedDate,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  child: Stack(
                                    children: [
                                      ListTile(
                                        title: Text(feelData['feel'] ?? ''),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () async {
                                                        String userId =
                                                            FirebaseAuth
                                                                    .instance
                                                                    .currentUser
                                                                    ?.uid ??
                                                                '';
                                                        DocumentReference<
                                                                Map<String,
                                                                    dynamic>>
                                                            feelRef =
                                                            FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'feels')
                                                                .doc(
                                                                    feels[index]
                                                                        .id);
                                                        await FirebaseFirestore
                                                            .instance
                                                            .runTransaction(
                                                                (transaction) async {
                                                          DocumentSnapshot<
                                                                  Map<String,
                                                                      dynamic>>
                                                              feel =
                                                              await transaction
                                                                  .get(feelRef);
                                                          if (feel.exists) {
                                                            List<dynamic>?
                                                                likers =
                                                                feel.data()?[
                                                                    'beğenenlerListesi'];
                                                            int likes = feel
                                                                        .data()?[
                                                                    'beğeniSayısı'] ??
                                                                0;

                                                            if (likers !=
                                                                    null &&
                                                                likers.contains(
                                                                    userId)) {
                                                              // Kullanıcı zaten beğenmiş, beğenisini kaldır
                                                              likers.remove(
                                                                  userId);
                                                              transaction
                                                                  .update(
                                                                      feelRef, {
                                                                'beğenenlerListesi':
                                                                    likers,
                                                                'beğeniSayısı':
                                                                    likes - 1,
                                                              });
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      SnackBar(
                                                                content: Text(
                                                                    'Beğeniyi Kaldırdın.'),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ));
                                                            } else {
                                                              // Kullanıcı beğenmemiş, beğeni ekle
                                                              if (likers ==
                                                                  null) {
                                                                likers = [
                                                                  userId
                                                                ];
                                                              } else {
                                                                likers.add(
                                                                    userId);
                                                              }
                                                              transaction
                                                                  .update(
                                                                      feelRef, {
                                                                'beğenenlerListesi':
                                                                    likers,
                                                                'beğeniSayısı':
                                                                    likes + 1,
                                                              });
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      SnackBar(
                                                                content: Text(
                                                                    'Yazıyı Beğendin.'),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
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
                                                    'Gönderen: ${userData?['name'] ?? 'Bilinmiyor'} ${userData?['surname'] ?? ''} - $formattedDate',
                                                    overflow:
                                                        TextOverflow.ellipsis,
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

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> feelData;
  final Map<String, dynamic>? userData;
  final String formattedDate;

  PostDetailScreen({
    required this.postId,
    required this.feelData,
    required this.userData,
    required this.formattedDate,
  });

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
  if (userId != null && userId.isNotEmpty) { // userId null değil ve boş değilse devam et
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data();
  } else {
    print('Hata: userId null, boş veya eksik');
    return null; // Eğer userId null veya boş ise null döndür
  }
}



  void _submitComment() async {
    if (_commentController.text.isEmpty) return;

    String userId = _auth.currentUser?.uid ?? '';
    DocumentReference postRef =
        _firestore.collection('feels').doc(widget.postId);

    await postRef.collection('comments').add({
      'text': _commentController.text,
      'userId': userId,
      'timestamp': Timestamp.now(),
    });

    _commentController.clear();
  }

  Stream<List<Map<String, dynamic>>> _getCommentsStream() {
    return FirebaseFirestore.instance
        .collection('feels')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'text': doc['text'],
                  'userId': doc['userId'],
                  'timestamp': doc['timestamp'],
                })
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gönderi Detayı'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.feelData.containsKey('imageUrl'))
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(widget.feelData['imageUrl']),
              ),
            SizedBox(height: 10),
            Text(
              widget.feelData['feel'] ?? '',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
                'Gönderen: ${widget.userData?['name'] ?? 'Bilinmiyor'} ${widget.userData?['surname'] ?? ''}'),
            Text('Tarih: ${widget.formattedDate}'),
            Divider(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getCommentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  } else {
                    List<Map<String, dynamic>> comments = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> comment = comments[index];
                        DateTime date =
                            (comment['timestamp'] as Timestamp).toDate();
                        String formattedDate =
                            DateFormat.yMd().add_Hm().format(date);
                        return ListTile(
                          title: FutureBuilder<Map<String, dynamic>?>(
                            future: _getUserDetails(comment['userId']),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (userSnapshot.hasError) {
                                return Text('Hata: ${userSnapshot.error}');
                              } else {
                                Map<String, dynamic>? userData =
                                    userSnapshot.data;
                                String userName =
                                    userData?['name'] ?? 'Bilinmiyor';
                                String userSurname = userData?['surname'] ?? '';
                                return Text('$userName $userSurname');
                              }
                            },
                          ),
                          subtitle: Text(comment['text']),
                          trailing: Text(formattedDate),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Yorum yap',
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _submitComment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
