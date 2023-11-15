import 'dart:convert';

import 'package:http/http.dart' as http;

import '../widgets/singleton.dart';


class AppUser {
  late int accountId;
  late String sessionId;
  List<AppUser> followingUsers;
  String imagePath;
  String name;
  String username;
  bool isSelected;

  AppUser({
    required this.accountId,
    required this.sessionId,
    List<AppUser>? followingUsers,
    this.imagePath = '',
    this.name = '',
    this.username = '',
    this.isSelected = false,
  }): followingUsers = followingUsers ?? [];


  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'sessionId': sessionId,
      'followingUsers': followingUsers.map((user) => user.toMap()).toList(),
      'isFollowing': isSelected,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      accountId: map['accountId'],
      sessionId: map['sessionId'],
      followingUsers: List<AppUser>.from(map['followingUsers']?.map((user) => AppUser.fromMap(user))),
      imagePath: map['imagePath'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      isSelected: map['isFollowing'] ?? false,

    );
  }



  Future<void> loadUserData() async {
    final String apiKey = '24b3f99aa424f62e2dd5452b83ad2e43';

    String def = Singleton.defaultLanguage;
    final response = await http.get(Uri.parse('https://api.themoviedb.org/3/account/$accountId?api_key=$apiKey&session_id=$sessionId&language=$def'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Access the avatar path from the response data
      final namePath = data["name"];
      final userNamePath = data["username"];
      final avatarPath = data['avatar']['tmdb']['avatar_path'];

      // Construct the full URL for the avatar image
      final imageUrl = 'https://image.tmdb.org/t/p/w500$avatarPath';

      // Use the imageUrl as needed (e.g., display the image in a Flutter app)
      imagePath = imageUrl;
      username = userNamePath;
      name = namePath;
    } else {
      print('Error: ${sessionId}');
    }
  }
}
