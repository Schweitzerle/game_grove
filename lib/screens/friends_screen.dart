import 'dart:async';

import 'package:game_grove/widgets/friend_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:game_grove/utils/SessionManager.dart';
import 'package:rxdart/rxdart.dart';

import '../Database/user.dart';
import '../widgets/singleton.dart';
import 'package:firebase_database/firebase_database.dart';

class RecommendedScreen extends StatefulWidget {
  @override
  _RecommendedScreenState createState() => _RecommendedScreenState();
}

class _RecommendedScreenState extends State<RecommendedScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> recommendedMovies = [];
  List<dynamic> recommendedSeries = [];
  List<dynamic> ratedMovies = [];
  List<dynamic> ratedSeries = [];
  List<AppUser> following = [];

  final Future<String?> sessionID = SessionManager.getSessionId();
  final Future<int?> accountID = SessionManager.getAccountId();
  String? sessionId;
  int? accountId;
  final String apiKey = '24b3f99aa424f62e2dd5452b83ad2e43';
  final readAccToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyNGIzZjk5YWE0MjRmNjJlMmRkNTQ1MmI4M2FkMmU0MyIsInN1YiI6IjYzNjI3NmU5YTZhNGMxMDA4MmRhN2JiOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.fiB3ZZLqxCWYrIvehaJyw6c4LzzOFwlqoLh8Dw77SUw';
  late TabController _tabController;

  late Future<void> _searchUsersFuture;

  bool dataLoaded = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await setIDs();
    if (accountId! >= 1) {
      await _searchUsers();
    }
    setState(() {
      dataLoaded = true;
    });
  }

  Future<void> setIDs() async {
    accountId = await accountID;
    sessionId = await sessionID;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(translate('Gefolgt')),
        backgroundColor: Color(0xff690257),
        actions: [
          Padding(
            padding: EdgeInsets.all(5),
            child: SvgPicture.asset(
              "assets/images/tmdb_logo.svg",
              fit: BoxFit.fitHeight, //
              alignment:
                  Alignment.centerRight, // Adjust the fit property as needed
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: !Singleton.isGuest ? Padding(
        padding: EdgeInsets.only(bottom: 70, right: 10),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserSearchDialog(),
                ));
          },
          child: Icon(Icons.movie_filter_outlined),
          backgroundColor: Singleton.fourthTabColor,
          foregroundColor: Singleton.secondTabColor,
        ),
      ):Container(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.0, 0.4), // Start at the middle left
            end: Alignment(0.0, 0.1), // End a little above the middle
            colors: [Singleton.secondTabColor.withOpacity(0.8), Colors.black],
          ),
        ),
        child: !Singleton.isGuest ? dataLoaded
            ? Stack(
                children: [
                  AnimationLimiter(
                    child: GridView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.only(bottom: 80),
                      itemCount: following.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        final user = following[index];
                        //_searchFollowers(context, accountId.toString(), user.accountId.toString());
                        return AnimationConfiguration.staggeredGrid(
                            position: index,
                            duration: Duration(milliseconds: 500),
                            columnCount: 2,
                            child: ScaleAnimation(
                              duration: Duration(milliseconds: 900),
                              curve: Curves.fastLinearToSlowEaseIn,
                              child: FadeInAnimation(
                                child: GestureDetector(
                                  onTap: () {
                                    Get.to(
                                        () => FriendScreen(
                                              accountID: user.accountId,
                                              sessionID: user.sessionId,
                                              appBarColor: Color(0xff690257),
                                              title: translate('Folge ich'),
                                              user: user,
                                            ),
                                        transition: Transition.downToUp,
                                        duration: Duration(milliseconds: 700));
                                  },
                                  child: Container(
                                    margin: EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Singleton.secondTabColor,
                                      borderRadius: BorderRadius.circular(10.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          height: 200,
                                          width: 140,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: user.imagePath.substring(
                                                        user.imagePath.length -
                                                            4,
                                                        user.imagePath
                                                            .length) !=
                                                    'null'
                                                ? Image.network(
                                                    user.imagePath,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: Singleton
                                                          .fourthTabColor
                                                          .withOpacity(
                                                              0.7), // Customize the color here
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.person_pin,
                                                        color: Singleton
                                                            .firstTabColor,
                                                        // Customize the icon color here
                                                        size: 50,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                Text(
                                                  user.username,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ])
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ));
                      },
                    ),
                  ),
                ],
              )
            : Singleton.buildShimmerFriendsItem() :Singleton.customWidget(translate('FreundeText'), context),
      ),
    );
  }

  Future<void> _searchUsers() async {
    int? _accountId = await accountID;
    following.clear();
    final ref = FirebaseDatabase.instance
        .ref("users")
        .child(_accountId.toString())
        .child('following');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final value in data.values) {
        final accountId = value['accountId'] as int;
        final sessionId = value['sessionId'] as String;
        final user = AppUser(accountId: accountId, sessionId: sessionId);
        await user.loadUserData();
        setState(() {
          following.add(user);
        });
      }
    } else {
      print('No data available.');
    }
  }
}



class UserSearchDialog extends StatefulWidget {
  @override
  _UserSearchDialogState createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final Future<String?> sessionID = SessionManager.getSessionId();
  final Future<int?> accountID = SessionManager.getAccountId();
  final String apiKey = '24b3f99aa424f62e2dd5452b83ad2e43';
  final readAccToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyNGIzZjk5YWE0MjRmNjJlMmRkNTQ1MmI4M2FkMmU0MyIsInN1YiI6IjYzNjI3NmU5YTZhNGMxMDA4MmRhN2JiOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.fiB3ZZLqxCWYrIvehaJyw6c4LzzOFwlqoLh8Dw77SUw';

  List<AppUser> users = [];
  bool isPressed2 = true;
  bool isHighlighted = false;
  int? accountIDActiveUser = 0;
  List<AppUser> following = [];

  final database = FirebaseDatabase.instance.ref().child('users');

  StreamController<String> _searchQueryController = StreamController<String>.broadcast();


  @override
  void initState() {
    super.initState();
    setAccId();
    if(!Singleton.isGuest) {
      getFollowingStatus();

      _searchQueryController.stream
          .debounceTime(
          Duration(milliseconds: 300)) // Adjust debounce time if needed
          .listen((String query) {
        _searchUsers(query);
      });
    }
  }

  @override
  void dispose() {
    _searchQueryController.close();
    super.dispose();
  }


  Future<void> setAccId() async {
    accountIDActiveUser = await accountID;
  }

  Widget _buildUserGrid() {
    return GridView.builder(
      physics: BouncingScrollPhysics(),
      itemCount: users.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        final user = users[index];
        //_searchFollowers(context, accountId.toString(), user.accountId.toString());
        return AnimationConfiguration.staggeredGrid(
          position: index,
          duration: Duration(milliseconds: 500),
          columnCount: 2,
          child: ScaleAnimation(
            duration: Duration(milliseconds: 900),
            curve: Curves.fastLinearToSlowEaseIn,
            child: FadeInAnimation(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Singleton.secondTabColor,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 190,
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: user.imagePath.substring(
                              user.imagePath.length - 4,
                              user.imagePath.length) !=
                              'null'
                              ? Image.network(
                            user.imagePath,
                            fit: BoxFit.cover,
                          )
                              : Container(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              // Wrap the username with Flexible
                              child: Text(
                                user.username,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            InkWell(
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onHighlightChanged: (value) {
                                setState(() {
                                  isHighlighted = !isHighlighted;
                                });
                              },
                              onTap: () {
                                if (!user.isSelected) {
                                  setState(() async {
                                    user.isSelected = !user.isSelected;
                                    // Create a new user entry in the database
                                    final newUser = AppUser(
                                      accountId: user.accountId,
                                      sessionId: user.sessionId,
                                    );
                                    final newUserRef = database
                                        .child(accountIDActiveUser.toString())
                                        .child('following')
                                        .child(user.accountId.toString());
                                    await newUserRef.set(newUser.toMap());
                                  });
                                } else if (user.isSelected) {
                                  setState(() async {
                                    user.isSelected = !user.isSelected;
                                    // Delete the user entry in the database
                                    final newUserRef = database
                                        .child(accountIDActiveUser.toString())
                                        .child('following')
                                        .child(user.accountId.toString());
                                    await newUserRef.remove();
                                  });
                                }
                              },
                              child: AnimatedContainer(
                                margin: EdgeInsets.all(isHighlighted ? 0 : 2.5),
                                height: isHighlighted ? 50 : 45,
                                width: isHighlighted ? 50 : 45,
                                curve: Curves.fastLinearToSlowEaseIn,
                                duration: Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: Offset(5, 10),
                                    ),
                                  ],
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: !user.isSelected
                                    ? Icon(
                                  Icons.favorite_border,
                                  color: Colors.black.withOpacity(0.6),
                                )
                                    : Icon(
                                  Icons.favorite,
                                  color: Colors.pink.withOpacity(1.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(translate('Folge Leuten')),
        backgroundColor: Singleton.fourthTabColor,
      ),
      backgroundColor: Color(0xFF1f1f1f),
      body: Container(
        width: 600, // Set the desired width of the dialog
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onChanged: (value) {
                _searchQueryController.add(value);
              },
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: translate('Such nach Benutzername'),
                hintStyle: TextStyle(color: Colors.grey),
                fillColor: Singleton.fourthTabColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: AnimationLimiter(
                child: _buildUserGrid(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    translate('Abbruch'),
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getFollowingStatus() async {
    int? _accountId = await accountID;
    following.clear();
    final ref = FirebaseDatabase.instance
        .ref("users")
        .child(_accountId.toString())
        .child('following');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final value in data.values) {
        final accountId = value['accountId'] as int;
        final sessionId = value['sessionId'] as String;
        final user = AppUser(accountId: accountId, sessionId: sessionId);
        await user.loadUserData();
        setState(() {
          following.add(user);
        });
      }
    } else {
      print('No data available.');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        users.clear();
      });
      return;
    }

    users.clear(); // Clear the list before populating with new results

    final ref = FirebaseDatabase.instance.ref("users");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) async {
        final accountId = value['accountId'] as int;
        final sessionId = value['sessionId'] as String;

        final user = AppUser(accountId: accountId, sessionId: sessionId);
        await user.loadUserData();

        if (user.username
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()) &&
            user.accountId != accountIDActiveUser) {
          final userAlreadyFollowed = following.any(
                  (followingUser) => followingUser.accountId == user.accountId);
          user.isSelected = userAlreadyFollowed;
          setState(() {
            users.add(user);
          });
        }
      });

      if (users.isNotEmpty) {
        print('Users found');
      } else {
        print('No users found with the specified query.');
      }
    } else {
      print('No data available.');
    }
  }
}