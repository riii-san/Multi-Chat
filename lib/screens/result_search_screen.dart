import 'package:flutter/material.dart';
import 'package:multi_chat_app_ver3/utils/methods.dart';
import 'package:multi_chat_app_ver3/screens/chat_screen.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

// ホーム画面のbodyに表示するチャットルームリスト画面クラス
class ResultSearch extends StatelessWidget {
  final Map<String, dynamic>? userMap;

  ResultSearch(this.userMap);

  @override
  Widget build(BuildContext context) {

    types.User user = types.User(id:'');
    types.User partner = types.User(id:'');

    return ListTile(
      onTap: () async {
        String? authEmailAddress = await getAuthUserEmailAddress();
        String roomId = getChatRoomId(
            authEmailAddress!,
            userMap!['email']
        );

        // chatRoomIdが存在しなかった場合は_userと_partnerを作成する
        bool checkResult = await checkChatRoomExists(roomId);
        if(!checkResult){
          user = await getUser(authEmailAddress);
          partner = await getUser(userMap!['email']);
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => checkResult ? ChatRoom(roomId) : ChatRoom.NewChatRoom(roomId,user,partner),
          ),(route) => false,
        );
      },
      leading: const CircleAvatar(
        backgroundImage: AssetImage(
          'assets/images/210511_2_10.jpeg',
        ),
        radius: 25,
      ),
      title: Text(
        userMap!['name'],
        style: const TextStyle(
          color: Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(userMap!['email']),
    );
  }
}
