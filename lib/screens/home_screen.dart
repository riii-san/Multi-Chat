import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:multi_chat_app_ver3/screens/contact_screen.dart';
import 'package:multi_chat_app_ver3/screens/result_search_screen.dart';
import 'package:multi_chat_app_ver3/utils/methods.dart';

// ログイン後のホーム画面クラス
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // 初期のチャットルームリスト表示に必要な情報を格納
  List<Map<String, dynamic>> infoInstance = [];

  // Firestoreインスタンス
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // 検索でヒットしたuser情報を格納
  Map<String, dynamic>? userMap;

  // ローディングフラグ
  bool isLoading = true;

  // 検索フラグ
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    getInfo();
  }

  // 所属するchatroomid,chat相手,最新メッセージとその時間を取得するメソッド
  Future<void> getInfo() async{
    infoInstance = await getChatRooms();
    setState(() {
      isLoading = false;
    });
  }

  // 検索バーを返すメソッド
  Widget searchTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: TextField(
        autofocus: true,
        cursorColor: Colors.white,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          hintText: 'User Email Address',
          hintStyle: TextStyle(
            color: Colors.white60,
            fontSize: 20,
          ),
        ),
        onSubmitted: (value) {
          print('Entered text: $value');
          execSearch(value);
        },
      ),
    );
  }

  // 受け取ったメールアドレスがfireStoreに登録されているかを検索するメソッド
  void execSearch(String address) async {

    setState(() {
      isLoading = true;
    });

    await firestore
        .collection('users')
        .where("email", isEqualTo: address)
        .get()
        .then((value) {
      if (value.docs.length > 0) {
        setState(() {
          userMap = value.docs[0].data();
          isLoading = false;
        });
      } else {
        setState(() {
          userMap = null;
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: !isSearching ? const Text(
          "Multi-Chat",
          style: TextStyle(color: Colors.white),
        ) : searchTextField(),
          actions: ! isSearching
              ? [
            IconButton(
                icon: const Icon(Icons.search,color: Colors.white,),
                onPressed: () {
                  setState(() {
                    isSearching = true;
                  });
                })
          ]
              : [
            IconButton(
                icon: const Icon(Icons.clear,color: Colors.white,),
                onPressed: () {
                  setState(() {
                    isSearching = false;
                  });
                }
            )
          ]
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator())
          : isSearching ? userMap != null ? ResultSearch(userMap) : Container()
          : ContactList(infoInstance),
    );
  }
}

