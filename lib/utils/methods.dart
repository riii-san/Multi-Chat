import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

// ログインしているユーザのメールアドレスを取得するメソッド
Future<String?> getAuthUserEmailAddress() async {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
    final DocumentReference<Map<String, dynamic>> userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await userDoc.get();
  return documentSnapshot.get('email') as String?;
}

// 指定したアドレスのユーザ名を返すメソッド
Future<String?> getUserNameByEmail(String email) async {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;

  QuerySnapshot querySnapshot = await fireStore
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();

  if (querySnapshot.size > 0) {
    final data = querySnapshot.docs[0].data() as Map<String, dynamic>?;
    if (data != null) {
      return data['name'];
    }
  }

  return null;
}

// 指定したアドレスのユーザIDを返すメソッド
Future<String?> getUserIdByEmail(String email) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  QuerySnapshot querySnapshot = await firestore
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();

  if (querySnapshot.size > 0) {
    final data = querySnapshot.docs[0].data() as Map<String, dynamic>?;
    if (data != null) {
      return data['uid'];
    }
  }

  return null;
}

// 指定したuidのユーザ名を返すメソッド
Future<String?> getUserNameById(String uid) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  QuerySnapshot querySnapshot = await firestore
      .collection('users')
      .where('uid', isEqualTo: uid)
      .limit(1)
      .get();

  if (querySnapshot.size > 0) {
    final data = querySnapshot.docs[0].data() as Map<String, dynamic>?;
    if (data != null) {
      return data['name'];
    }
  }

  return null;
}

// 指定したuidのメールアドレスを返すメソッド
Future<String?> getUserEmailById(String uid) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  QuerySnapshot querySnapshot = await firestore
      .collection('users')
      .where('uid', isEqualTo: uid)
      .limit(1)
      .get();

  if (querySnapshot.size > 0) {
    final data = querySnapshot.docs[0].data() as Map<String, dynamic>?;
    if (data != null) {
      return data['email'];
    }
  }

  return null;
}

// 指定したチャットルームIDに紐づくuserEmail1,2を返すメソッド
Future<List<String>> getUserEmailAddressesByChatRoomId(String chatRoomId) async {
  try {
    final DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('chatroom')
        .doc(chatRoomId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>?;
      String? authEmailAddress = await getAuthUserEmailAddress();
      String userEmailAddress1;
      String userEmailAddress2;

      // ログインしているユーザは1の方にデータ格納
      if (data?['userEmail1'] == authEmailAddress){
        userEmailAddress1 = data?['userEmail1'];
        userEmailAddress2 = data?['userEmail2'];
      }else{
        userEmailAddress1 = data?['userEmail2'];
        userEmailAddress2 = data?['userEmail1'];
      }

      return [userEmailAddress1, userEmailAddress2];
    } else {
      return [];
    }
  } catch (e) {
    print('Error getting user email addresses: $e');
  }

  return []; // エラーが発生した場合やドキュメントが存在しない場合は空のリストを返す
}

// ログインしているユーザのホーム画面表示に必要なデータを取得するメソッド
// info.dartのchatListinfo定数を参考
Future<List<Map<String, dynamic>>> getChatRooms() async {

  List<Map<String, dynamic>> infoInstance = [];

  // Firestoreのインスタンス生成
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
  QuerySnapshot querySnapshot = await fireStore.collection('chatroom').get();

  // 取得したchatroom情報からログインユーザのチャット情報を取得
  for (var doc in querySnapshot.docs) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String userEmail1 = data['userEmail1'];
    String userEmail2 = data['userEmail2'];

    String? authEmailAddress = await getAuthUserEmailAddress();

    if (userEmail1 == authEmailAddress ||
        userEmail2 == authEmailAddress) {

      String chatroomId = doc.id;
      QuerySnapshot messagesSnapshot = await fireStore
          .collection('chatroom')
          .doc(chatroomId)
          .collection('chats')
          .orderBy('time', descending: true)  // タイムスタンプで降順にソート
          .limit(1)  // 最新のメッセージ1件のみを取得
          .get();

      String? name;
      if (userEmail1 == authEmailAddress){
        name = await getUserNameByEmail(userEmail2);
      } else{
        name = await getUserNameByEmail(userEmail1);
      }

      for (QueryDocumentSnapshot messageDoc in messagesSnapshot.docs) {
        // メッセージのデータにアクセスして処理を行う
        Map<String, dynamic> messageData = messageDoc.data() as Map<String, dynamic>;

        DateTime dateTime = (messageData['time'] as Timestamp).toDate();
        String formattedTime = DateFormat('hh:mm a').format(dateTime);

        Map<String, dynamic> info = {
          'name': name, // ユーザ名に対応するデータを取得する必要があります
          'chatRoomId': chatroomId,
          'message': messageData['message'],
          'time': formattedTime,
          'profilePic':
          'assets/images/210511_2_10.jpeg',
        };
        infoInstance.add(info);
      }

    }
  }

  infoInstance.sort((a, b) => b['time'].compareTo(a['time']));

  return infoInstance;

}

// 受け取ったメールアドレスからチャットルームIDを作成し返すメソッド
String getChatRoomId(String userEmail1, String userEmail2) {

  int result = userEmail1.compareTo(userEmail2);

  // chatRoomIdは辞書順で作成しユニークなIdを設定する
  if (result < 0) {
    return "$userEmail1&$userEmail2";
  } else if (result > 0) {
    return "$userEmail2&$userEmail1";
  } else {
    return "$userEmail1&$userEmail2";
  }

}

// 受け取ったチャットルームIDがすでに存在するかを調べるメソッド
Future<bool> checkChatRoomExists(String chatRoomId) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('chatroom')
      .doc(chatRoomId)
      .get();
  return snapshot.exists;
}

// 受け取ったテキストを翻訳して返すメソッド
Future<String> getTranslateText(String text, String apiKey, String lang) async {
  const apiUrl = 'https://api-free.deepl.com/v2/translate';
  final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
  final body = {
    'auth_key': apiKey,
    'text': text,
    'source_lang': lang == 'JA' ? 'JA' : 'EN',
    'target_lang': lang == 'JA' ? 'EN' : 'JA',
  };

  final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    print(data['translations'][0]['text']);
    return data['translations'][0]['text'];
  } else {
    print(response.statusCode);
    print(response.body);
    throw Exception('Failed to translate text');
  }
}

// メールアドレスを受けとりtypes.Userを作成し返すメソッド
Future<types.User> getUser(String email) async {
  String? userId = await getUserIdByEmail(email);
  String? userName = await getUserNameById(userId!);
  return types.User(id: userId ?? '', firstName: userName ?? '');
}

// ランダムな文字列を生成するメソッド
String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}