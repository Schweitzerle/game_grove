import 'dart:async';
import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:countup/countup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Database/user.dart';
import '../main.dart';
import '../utils/AdMobService.dart';
import '../utils/SessionManager.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

import '../utils/text.dart';
import '../widgets/singleton.dart';
import 'package:rxdart/rxdart.dart';


class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final Future<String?> sessionID = SessionManager.getSessionId();
  final Future<int?> accountID = SessionManager.getAccountId();
  String name = '';
  String imagePath = '';
  String username = '';
  int seriesRanked = 0;
  int moviesRanked = 0;
  int friendsCount = 0;
  List<AppUser> following = [];
  int minutesMoviesWatched = 0;
  String? sessionId;
  int? accountId;
  int addedRuntimeMovies = 0;
  final String apiKey = '24b3f99aa424f62e2dd5452b83ad2e43';
  final readAccToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyNGIzZjk5YWE0MjRmNjJlMmRkNTQ1MmI4M2FkMmU0MyIsInN1YiI6IjYzNjI3NmU5YTZhNGMxMDA4MmRhN2JiOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.fiB3ZZLqxCWYrIvehaJyw6c4LzzOFwlqoLh8Dw77SUw';

  BannerAd? _bannerAd;

  List<Map<dynamic, dynamic>> supportedLanguages = [];
  List<Map<dynamic, dynamic>> supportedCountries = [];

  String defaultLang = "";
  String defaultCountry = "";

  @override
  initState() {
    super.initState();
    loadAd();
    initialize();
  }

  Future<void> initialize() async {
    await setDefaultState();
    await fetchSupportedLanguages();
    await fetchSupportedCountries();
    await setIDs();

    if(!Singleton.isGuest) {
      await loadData();
      await _searchUsers();
    }
  }

  void loadAd() {
    _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: AdMobService.bannerAdUnitId!,
        listener: AdMobService.bannerAdListener,
        request: const AdRequest())
      ..load();
  }

  Future<void> fetchSupportedCountries() async {
    final response = await http.get(
      Uri.parse(
          'https://api.themoviedb.org/3/configuration/countries?api_key=$apiKey'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<dynamic, dynamic>> countryList = data.map((item) {
        return {
          item['iso_3166_1']: item['english_name'],
        };
      }).toList();

      countryList.sort((a, b) {
        return a.values.first.compareTo(b.values.first);
      });

      setState(() {
        supportedCountries = countryList;
      });
    } else {
      throw Exception('Failed to load supported languages');
    }
  }

  Future<void> fetchSupportedLanguages() async {
    final response = await http.get(
      Uri.parse(
          'https://api.themoviedb.org/3/configuration/languages?api_key=$apiKey'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<dynamic, dynamic>> languagesList = data.map((item) {
        return {
          item['iso_639_1']: item['english_name'],
        };
      }).toList();

      // Exclude the item with key "xx" (No Language)
      languagesList =
          languagesList.where((item) => item.keys.first != 'xx').toList();

      languagesList.sort((a, b) {
        return a.values.first.compareTo(b.values.first);
      });

      setState(() {
        supportedLanguages = languagesList;
      });
    } else {
      throw Exception('Failed to load supported languages');
    }
  }

  Future<void> getMoviesRuntime() async {
    int totalRuntime = 0;
    for (int i = 0; i < moviesRanked; i++) {
      int runtime = 0 ?? 0;
      totalRuntime += runtime;
    }

    setState(() {
      addedRuntimeMovies = totalRuntime;
    });
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

  Future<void> loadData() async {
    int? accountId = await accountID;
    String? sessionId = await sessionID;
    String def = Singleton.defaultLanguage;
    final response = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/account/$accountId?api_key=$apiKey&session_id=$sessionId&language=$def'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Access the avatar path from the response data
      final namePath = data["name"];
      final userNamePath = data["username"];
      final avatarPath = data['avatar']['tmdb']['avatar_path'];

      // Construct the full URL for the avatar image
      final imageUrl = 'https://image.tmdb.org/t/p/w500$avatarPath';

      // Use the imageUrl as needed (e.g., display the image in a Flutter app)

      setState(() {
        imagePath = imageUrl;
        username = userNamePath;
        name = namePath;
      });
    } else {
      print('Error: ${sessionId}');
    }

    Map<dynamic, dynamic> ratedMoviesResults =
        await Singleton.tmdbWithCustLogs.v3.account.getRatedMovies(
      sessionId!,
      accountId!,
    );
    int ratedMovies = ratedMoviesResults['total_results'];

    Map<dynamic, dynamic> ratedSeriesResults =
        await Singleton.tmdbWithCustLogs.v3.account.getRatedTvShows(
      sessionId!,
      accountId!,
    );
    int ratedSeries = ratedSeriesResults['total_results'];

    setState(() {
      moviesRanked = ratedMovies;
      seriesRanked = ratedSeries;
    });

    getMoviesRuntime();
  }

  Future<void> setDefaultState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultCountry = prefs.getString('selectedCountry')!;
      defaultLang = prefs.getString('selectedLanguage')!;

    });
  }

  Future<void> setIDs() async {

    int? accId = await accountID;
    String? sessId = await sessionID;
    setState(() {
      accountId = accId;
      sessionId = sessId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(translate('Mein Profil')),
        backgroundColor: Color(0xff270140),
        actions: [
          IconButton(
            onPressed: () {
              showCreditsDialog(context);
            },
            icon: Icon(Icons.info),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.0, 0.4), // Start at the middle left
            end: Alignment(0.0, 0.1), // End a little above the middle
            colors: [Singleton.fifthTabColor.withOpacity(0.8), Colors.black],
          ),
        ),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(bottom: 70, left: 10, right: 10),
            child: Column(
              children: [
                SizedBox(height: 5),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        logout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xff270140),
                      ),
                      child: Text(translate('Ausloggen')),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(
                    18.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final Uri url = Uri.parse(
                              'https://www.themoviedb.org/settings/profile');
                          if (!await launchUrl(url,
                              mode: LaunchMode.externalApplication)) {
                            throw Exception('Could not launch $url');
                          }
                        },
                        child: Container(
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey, // Placeholder background color
                          ),
                          child: Center(
                            child: ClipOval(
                              child: SizedBox(
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: imagePath.isNotEmpty
                                      ? Image.network(
                                    imagePath,
                                  )
                                      : Icon(
                                    Icons.person, // Placeholder icon (you can use any other icon)
                                    size: screenWidth * 0.15, // Adjust the size as needed
                                    color: Colors.white, // Color of the placeholder icon
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),


                      SizedBox(height: 20.0),
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            name.isNotEmpty ? name : translate('Loading...'),
                            speed: Duration(milliseconds: 150),
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        isRepeatingAnimation: true,
                        repeatForever: false,
                        totalRepeatCount: 4,
                      ),
                      SizedBox(height: 20.0),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat(
                              translate('Filme bewertet'), moviesRanked),
                          _buildProfileStat(
                              translate('Serien bewertet'), seriesRanked),
                          _buildProfileStat(
                              translate('Folge ich'), following.length),
                        ],
                      ),
                      /*SizedBox(height: screenHeight * 0.03),
                      _buildProfileStat(
                        'Movie Time Watched',
                        '${addedRuntimeMovies.toString()} minutes',
                      ),*/
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: screenWidth * 0.8,
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            // Add padding
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Singleton.secondTabColor),
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(
                                  10), // Add rounded corners
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      translate('Ausgewählte Sprache'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(width: 40),
                                    GestureDetector(
                                      onTap: () {
                                        showInfoDialog(translate('Daten'));
                                      },
                                      child: Icon(Icons.info_outline,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  // Add padding
                                  decoration: BoxDecoration(
                                    color: Singleton.fifthTabColor
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(
                                        10), // Add rounded corn
                                  ),
                                  child: DropdownButton<String>(
                                    itemHeight: 70,
                                    menuMaxHeight: screenHeight * 0.6,
                                    borderRadius: BorderRadius.circular(20),
                                    dropdownColor: Singleton.fifthTabColor,
                                    value: defaultLang,
                                    onChanged: (String? value) {
                                      setState(() {
                                        defaultLang = value!;
                                        Singleton.setDefaultLanguage(value);
                                        var localizationDelegate =
                                            LocalizedApp.of(context).delegate;
                                        localizationDelegate
                                            .changeLocale(Locale(value));
                                      });
                                    },
                                    items: supportedLanguages.map((sortBy) {
                                      String sortByValue = sortBy.keys.first;
                                      String displayString =
                                          sortBy.values.first;
                                      return DropdownMenuItem<String>(
                                        value: sortByValue,
                                        child: mod_Text(
                                          // Display the country name
                                          text: displayString,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      );
                                    }).toList(),
                                    style: TextStyle(color: Colors.white),
                                    underline: Container(
                                      height: 2,
                                      color: Singleton.secondTabColor,
                                    ),
                                    icon: Icon(Icons.arrow_downward,
                                        color: Singleton.secondTabColor),
                                    isExpanded: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            width: screenWidth * 0.8,
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            // Add padding
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Singleton.secondTabColor),
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(
                                  10), // Add rounded corners
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      translate('Ausgewähltes Land'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showInfoDialog(
                                            translate('Neustarten.'));
                                      },
                                      child: Icon(Icons.info_outline,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  // Add padding
                                  decoration: BoxDecoration(
                                    color: Singleton.fifthTabColor
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(
                                        10), // Add rounded corn
                                  ),
                                  child: DropdownButton<String>(
                                    menuMaxHeight: screenHeight * 0.6,
                                    itemHeight: 70,
                                    borderRadius: BorderRadius.circular(20),
                                    dropdownColor: Singleton.fifthTabColor,
                                    value: defaultCountry,
                                    onChanged: (String? value) {
                                      setState(() {
                                        defaultCountry = value!;
                                        Singleton.setDefaultCountry(value);
                                      });
                                    },
                                    items: supportedCountries.map((sortBy) {
                                      String sortByValue = sortBy.keys.first;
                                      String displayString =
                                          sortBy.values.first;
                                      return DropdownMenuItem<String>(
                                        value: sortByValue,
                                        child: mod_Text(
                                          text: displayString,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      );
                                    }).toList(),
                                    // Set a specific width for the dropdown menu
                                    // Adjust the value of width based on your preference
                                    isExpanded: true,
                                    // Set this property to true to allow the dropdown to expand
                                    // to the full width of its parent
                                    style: TextStyle(color: Colors.white),
                                    underline: Container(
                                      height: 2,
                                      color: Singleton
                                          .secondTabColor, // Change this to the color you want
                                    ),
                                    icon: Icon(Icons.arrow_downward,
                                        color: Singleton.secondTabColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height:10),
                          _bannerAd != null
                              ? Row(
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                width: _bannerAd!.size.width.toDouble(),
                                height: _bannerAd!.size.height.toDouble(),
                                child: AdWidget(ad: _bannerAd!),
                              ),
                            ],
                          )
                              : Container(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showCreditsDialog(BuildContext context) async {
    final appVersion = await Singleton.appVersion;
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF1f1f1f),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(left: 10, right: 10, bottom: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'App Info',
                style: TextStyle(
                  color: Singleton.thirdTabColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24, // Adjust the size as per your preference
                  decoration: TextDecoration.underline,
                ),
              ),              SizedBox(height: 20,),
              Container(
                width:
                    MediaQuery.of(context).size.width * 0.8, // 80% screen width
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info, // Add an icon here
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'About', // Add a title here
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      translate('Version'),
                      style: TextStyle(
                        color: Singleton.secondTabColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      appVersion,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                width:
                    MediaQuery.of(context).size.width * 0.8, // 80% screen width
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.handshake, // Add an icon here
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Credits', // Add a title here
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: translate('Bilder von'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' Dorothe,',
                            style: TextStyle(
                              fontSize: 14,
                              color: Singleton.secondTabColor,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launch(
                                    'https://pixabay.com/users/darkmoon_art-1664300/?utm_source=link-attribution&utm_medium=referral&utm_campaign=image&utm_content=3700446');
                              },
                          ),
                          TextSpan(
                            text: '6847478,',
                            style: TextStyle(
                              fontSize: 14,
                              color: Singleton.secondTabColor,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launch(
                                    'https://pixabay.com/users/6847478-6847478/?utm_source=link-attribution&utm_medium=referral&utm_campaign=image&utm_content=4788367');
                              },
                          ),
                          TextSpan(
                            text: 'mariaisabela ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Singleton.secondTabColor,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launch(
                                    'https://pixabay.com/users/mariaisabela-241286/?utm_source=link-attribution&utm_medium=referral&utm_campaign=image&utm_content=778057');
                              },
                          ),
                          TextSpan(
                            text: translate('auf'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' Pixabay',
                            style: TextStyle(
                              fontSize: 14,
                              color: Singleton.secondTabColor,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launch('https://pixabay.com/');
                              },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                        text: 'Flutter Animation Gallery',
                        style: TextStyle(
                          fontSize: 14,
                          color: Singleton.secondTabColor,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launch(
                              'https://play.google.com/store/apps/details?id=com.flutter.gaurav_tantuway.flutter_animation_gallery',
                            );
                          },
                      ),
                    ])),
                    SizedBox(height: 10),
                    Text(
                      translate('Zertifiziert'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              launch('https://www.justwatch.com/');
                            },
                            child: Image.asset(
                              "assets/images/JustWatch.png",
                              width: 70.0,
                              height: 70.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              launch('https://www.themoviedb.org/');
                            },
                            child: SvgPicture.asset(
                              "assets/images/tmdb_logo.svg",
                              width: 70.0,
                              height: 70.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xff270140),
                    ),
                    child: Text(translate('Schließen')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void showInfoDialog(String infoText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translate('Information'),
              style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF1f1f1f),
          content: Text(
            infoText,
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                primary: Color(0xff270140),
              ),
              child: Text(translate('Schließen')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileStat(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.0),
        Countup(
          begin: 0,
          end: value.toDouble(),
          //here you insert the number or its variable
          duration: Duration(seconds: 3),
          separator: '.',
          //this is the character you want to add to seperate between every 3 digits
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('sessionId');
    prefs.remove('isGuest');
    FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (BuildContext context) => MyHomePage()),
      (route) => false,
    );
  }
}

