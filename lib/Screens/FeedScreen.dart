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
    if (userId.isNotEmpty) {
      // userId boş değilse devam et
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .get();
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
                                  child: Container(
                                    padding: EdgeInsets.all(
                                        10.0), // Add padding for more height
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
                                                                  .doc(feels[
                                                                          index]
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
                                                                      .get(
                                                                          feelRef);
                                                              if (feel.exists) {
                                                                List<dynamic>?
                                                                    likers =
                                                                    feel.data()?[
                                                                        'beğenenlerListesi'];
                                                                int likes =
                                                                    feel.data()?[
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
                                                                          feelRef,
                                                                          {
                                                                        'beğenenlerListesi':
                                                                            likers,
                                                                        'beğeniSayısı':
                                                                            likes -
                                                                                1,
                                                                      });
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                          'Beğeniyi Kaldırdın.'),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                  );
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
                                                                          feelRef,
                                                                          {
                                                                        'beğenenlerListesi':
                                                                            likers,
                                                                        'beğeniSayısı':
                                                                            likes +
                                                                                1,
                                                                      });
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                          'Yazıyı Beğendin.'),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .green,
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            },
                                                          );
                                                        },
                                                        icon: Icon(
                                                          Icons.thumb_up,
                                                          color: isLiked
                                                              ? Colors.purple
                                                              : null,
                                                        ),
                                                        padding: EdgeInsets
                                                            .zero, // Butonun etrafındaki boşlukları kaldırır
                                                        visualDensity: VisualDensity
                                                            .compact, // Butonun boyutunu küçültür
                                                      ),
                                                      SizedBox(
                                                          width:
                                                              5), // Boşluk ekler

// Beğeni sayısının altına bir çizgi ekler
                                                      Container(
                                                        height: 1,
                                                        color: Colors.grey,
                                                        margin: EdgeInsets
                                                            .symmetric(
                                                                vertical:
                                                                    2), // Çizginin üst ve alt boşluklarını ayarlar
                                                      ),

                                                      SizedBox(
                                                          width:
                                                              5), // Boşluk ekler
                                                      InkWell(
                                                        onTap: () {
                                                          _showLikersDialog(
                                                              feelData[
                                                                  'beğenenlerListesi']);
                                                        },
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              '${feelData['beğeniSayısı'] ?? 0}',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                            Container(
                                                              height: 1,
                                                              color:
                                                                  Colors.grey,
                                                              width:
                                                                  10,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                       SizedBox(width: 7),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

  void _showLikersDialog(List<dynamic>? likers) async {
    if (likers == null || likers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Beğenenler'),
          content: Text('Henüz kimse beğenmemiş.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Kapat'),
            ),
          ],
        ),
      );
      return;
    }

    List<Map<String, dynamic>> likersData = [];
    for (var userId in likers) {
      Map<String, dynamic>? userDetails = await _getUserDetails(userId);
      if (userDetails != null) {
        likersData.add(userDetails);
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Beğenenler'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: likersData.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                    '${likersData[index]['name'] ?? 'Bilinmiyor'} ${likersData[index]['surname'] ?? ''}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
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
  TextEditingController _commentController = TextEditingController();

  void _submitComment() async {
    if (_commentController.text.isEmpty) return;

    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('feels').doc(widget.postId);

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

  Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detaylar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.feelData['feel'] ?? '',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Gönderen: ${widget.userData?['name'] ?? 'Bilinmiyor'} ${widget.userData?['surname'] ?? ''}',
            ),
            SizedBox(height: 5),
            Text('Tarih: ${widget.formattedDate}'),
            SizedBox(height: 20),
            if (widget.feelData.containsKey('imageUrl'))
              Image.network(
                widget.feelData['imageUrl'],
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
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
            SizedBox(height: 20),
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
                        Map<String, dynamic> commentData = comments[index];
                        DateTime date = (commentData['timestamp'] as Timestamp)
                            .toDate()
                            .add(Duration(hours: 3)); // UTC+3 (Türkiye saati)
                        String formattedDate =
                            DateFormat.yMd().add_Hm().format(date);
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _getUserDetails(commentData['userId']),
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
                              return ListTile(
                                title: Text(
                                    '${userData?['name'] ?? 'Bilinmiyor'} ${userData?['surname'] ?? ''}'),
                                subtitle: Text(commentData['text'] ?? ''),
                                trailing: Text(formattedDate),
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
    );
  }
}
