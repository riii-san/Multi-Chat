import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:multi_chat_app_ver3/screens/home_screen.dart';
import 'package:multi_chat_app_ver3/utils/info.dart';
import 'package:multi_chat_app_ver3/utils/methods.dart';

// 個人チャットルーム画面クラス
class ChatRoom extends StatefulWidget {
  final String chatRoomId;
  types.User user = types.User(id:'');
  types.User partner = types.User(id:'');

  ChatRoom(this.chatRoomId);

  // 新規トークルームの場合は_userと_partnerも受け取る
  ChatRoom.NewChatRoom(this.chatRoomId,this.user,this.partner);

  @override
  ChatRoomState createState() => ChatRoomState();
}

class ChatRoomState extends State<ChatRoom> {
  final List<types.Message> _messages = [];

  // FirebaseのFirestoreインスタンスを作成
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  // トグルボタン選択言語モード
  bool isJapaneseMode = true;

  // ローディングフラグ
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  // 個人チャットルームに必要な情報を初期化
  Future<void> _initializeChat() async {
    await _createChatUser();
    await _getChatMessages();
    setState(() {
      isLoading = false;
    });
  }

  // 自身とチャット相手の名前とメールアドレスを取得するメソッド
  Future<void> _createChatUser() async{
    // ChatRoomIdからメールアドレスを取得
    List<String> temp = await getUserEmailAddressesByChatRoomId(widget.chatRoomId);
    // 新規チャットルームでない場合、_userと_partnerを作成
    if(!temp.isEmpty){
      widget.user = await getUser(temp[0]);
      widget.partner = await getUser(temp[1]);
    }
  }

  // fireStoreからチャットメッセージを取得するメソッド
  Future<void> _getChatMessages() async {

    // Firestoreのコレクション名とチャットルームIDを指定してクエリを作成
    final query = _fireStore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .orderBy('time', descending: false);

    query.snapshots().listen((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        final String authorId = (data['sendby'] == widget.user.firstName) ? widget.user.id : widget.partner.id;

        return types.TextMessage(
          author: types.User(
            id: authorId,
            firstName: data['sendby'],
          ),
          id: doc.id,
          text: data['message'],
        );

        // Firestoreから取得したデータをtypes.Messageに変換する
      }).toList();

      setState(() {
        _messages.clear();
        _messages.addAll(messages.reversed);
      });
    });
  }

  // トグルボタンの選択言語を変換するメソッド
  void toggleLanguage() {
    setState(() {
      isJapaneseMode = !isJapaneseMode;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // 戻るボタンが押されたときの処理を記述
            // 擬似的に画面を戻るようなアニメーションを設定
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation), // Tween を使用
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 100), // アニメーションの時間を調整
              ),
                  (route) => false,
            );
          },
        ),
        title: Text(isLoading ? '' : widget.partner.firstName.toString(),style: TextStyle(color: Colors.white),),
        actions: [
          TextButton(
            onPressed: toggleLanguage,
            child: Text(
              isJapaneseMode ? 'JN' : 'EN',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        iconTheme: const IconThemeData(
          color: Colors.white, // 戻るボタンの色を白色に設定
        ),
      ),
      // 基本的なUIはflutter_chat_uiを使用
      body: isLoading ? const Center(child: CircularProgressIndicator()) : Chat(
        user: widget.user,
        messages: _messages,
        onSendPressed: _handleSendPressed,
      ),
    );
  }

  // データをfireStoreに登録し画面に表示する
  Future<void> _addMessage(types.TextMessage message) async {

    Map<String, dynamic> m = {
      "sendby": widget.user.firstName,
      "message": message.text,
      "type": "text",
      "time": FieldValue.serverTimestamp(),
    };

    final userEmail = await getUserEmailById(widget.user.id);
    final partnerEmail = await getUserEmailById(widget.partner.id);

    await _fireStore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .set({
      "userEmail1": userEmail,
      "userEmail2": partnerEmail,
    }).then((_) {
      _fireStore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .add(m);
    });

    _messages.insert(0, message);

  }

  // メッセージ送信時に実行するメソッド
  // fireStoreに登録するデータを作成
  void _handleSendPressed(types.PartialText message) async{

    String translateText = await getTranslateText(
        message.text,
        // TODO : deepL API 入力
        deeplAPI,
        isJapaneseMode ? 'JA' : 'EN'
    );

    final textMessage = types.TextMessage(
      author: widget.user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: message.text + '\n\n' + translateText,
    );

    _addMessage(textMessage);

  }
}

