/// ===============================================================
///
/// アプリ名 : Multi-Chat
/// 概要　　 : 自動翻訳機を通して日本語と英語でチャットが可能なアプリ
/// 主な機能 : ログイン、相互チャット、自動翻訳
/// 開発者　 : Ryoya Nakano
///
/// ===============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:multi_chat_app_ver3/screens/login_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
