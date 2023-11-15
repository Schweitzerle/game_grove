import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:game_grove/api/rawg_api.dart';
import 'package:game_grove/utils/AdMobService.dart';
import 'package:game_grove/utils/SessionManager.dart';
import 'package:game_grove/widgets/genreWidget.dart';
import 'package:game_grove/widgets/images_screen.dart';
import 'package:game_grove/widgets/people.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:game_grove/widgets/reviews.dart';
import 'package:game_grove/widgets/series.dart';
import 'package:game_grove/widgets/tv_seasons.dart';
import 'package:game_grove/widgets/video_widget.dart';
import 'package:countup/countup.dart';
import 'package:game_grove/widgets/watchProviders.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_fade/image_fade.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:http/http.dart' as http;

import 'Database/WatchProvider.dart';
import 'Database/user.dart';
import 'Database/userAccountState.dart';

class DescriptionSeries extends StatefulWidget {
  final int gameID;
  late bool isMovie;

  DescriptionSeries({Key? key, required this.gameID, required this.isMovie})
      : super(key: key);

  @override
  _DescriptionSeriesState createState() => _DescriptionSeriesState();
}

class _DescriptionSeriesState extends State<DescriptionSeries>
    with SingleTickerProviderStateMixin {
  final Future<int?> accountID = SessionManager.getAccountId();
  Map<String, dynamic> gameData = {};
  List creditData = [];
  List<WatchProvider> watchProvidersList = [];
  late Future<String?> sessionID;
  String? apiKey;
  double voteAverage = 0;
  int voteCount = 0;
  String title = '';
  String posterUrl = '';
  String bannerUrl = '';
  String launchOn = '';
  String description = '';
  int id = 0;
  bool inProduction = false;
  int revenue = 0;
  int numberOfEpisodes = 0;
  int numberOfSeasons = 0;
  String status = '';
  String tagline = '';
  String type = '';
  double initialRating = 0.0;
  bool isRated = false;
  List recommendedSeries = [];
  List similarSeries = [];
  List<dynamic> seasons = [];
  List images = [];
  List genres = [];
  List keywords = [];
  List reviews = [];
  List videoItems = [];
  Map<AppUser, double> users = {};
  UserAccountState? userAccountState = null;
  Color colorpalette = Colors.black;
  Color lightColor = Colors.black;
  Color darkColor = Colors.black;

  NumberFormat formatter = NumberFormat('###,###,###,###');

  bool watchlistState = false;
  bool reccState = false;

  late Animation<double> _animation;
  late AnimationController _animationController;

  String defaultCountry = '';
  String defaultLanguage = '';

  BannerAd? _bannerAd;

  bool dataLoaded = false;
  bool isColorLoaded = false;

  String sessionId = '';

  int accountId = 0;

  Map allImages = {};

  double metacritics = 0;
  double added = 0;
  double playtime = 0;
  double moviesCount = 0;
  double creatorsCount = 0;
  double achievementsCount = 0;
  double parentAchievementsCount = 0;
  List metacriticsPlatforms = [];
  Map addedByStatus = {};
  String originalTitle = '';
  String additionalBannerUrl = '';
  String website = '';
  String redditUrl = '';
  String redditName = '';
  String redditDescription =  '';
  String redditLogo = '';
  double redditCount = 0;
  double twitchCount = 0;
  double youtubeCount = 0;
  double ratingsCount = 0;
  double reviewsCount = 0;
  String metacriticUrl =  '';
  List parentPlatforms =  [];
  List platforms = [];
  List stores = [];
  List developers = [];
  List tags = [];
  List publishers = [];
  Map esrbRating = {};

  double suggestionCount = 0;

  @override
  void initState() {
    super.initState();
    loadAd();
    initialize();
  }



  Future<void> initialize() async {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );
    final curvedAnimation =
    CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    sessionID = SessionManager.getSessionId();
    apiKey = RawgApiService.getApiKey();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultCountry = prefs.getString('selectedCountry')!;
      defaultLanguage = prefs.getString('selectedLanguage')!;
    });
    await setIDs();

    await Future.wait([fetchTasks(),
    ]);

    //TODO: fetchUserData();

    setState(() {
      dataLoaded = true;
    });
  }

  Future<void> fetchUserData() async {
    if (accountId! >= 1) {
      await Future.wait([
        getUserRating(),
        _searchUsers(),
        getUserAccounts()
      ]);
  }
  }

  Future<void> fetchTasks() async {
    await Future.wait([
      fetchData(),
      //TODO: getReviews(),
    ]);
  }

  void loadAd() {
    _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: AdMobService.bannerAdUnitId!,
        listener: AdMobService.bannerAdListener,
        request: const AdRequest())
      ..load();
  }

  Future<void> setIDs() async {
    sessionId = (await sessionID)!;
    accountId = (await accountID)!;
  }



  Future<void> getReviews() async {
    Map watchlistResults = await Singleton.tmdbWithCustLogs.v3.tv.getReviews(
      widget.gameID,
    );
    TMDB tmdbWithCustLogs = TMDB(
      ApiKeys(Singleton.apiKey, Singleton.readAccToken),
      logConfig: const ConfigLogger(showLogs: true, showErrorLogs: true),
    );
    Map watchlistResultsEn = await tmdbWithCustLogs.v3.tv.getReviews(
      widget.gameID,
    );
    setState(() {
      reviews = watchlistResults['results'];
      if(defaultLanguage != 'en') {
        reviews.addAll(watchlistResultsEn['results']);
      }
    });
  }

  Future<void> _searchUsers() async {
    int? _accountId = await accountID;
    users.clear();
    List<AppUser> _users = [];
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
          _users.add(user);
        });
      }
    } else {
      print('No data available.');
    }

    for (AppUser user in _users) {
      String? sessionId = user.sessionId;

      Map<dynamic, dynamic> ratedMovieResult = await Singleton
          .tmdbWithCustLogs.v3.tv
          .getAccountStatus(widget.gameID, sessionId: sessionId);

      double ratedValue = 0.0; // Default value is 0.0

      if (ratedMovieResult['rated'] is Map<String, dynamic>) {
        Map<String, dynamic> ratedData = ratedMovieResult['rated'];
        ratedValue = ratedData['value']?.toDouble() ?? 0.0;
      }

      if (ratedValue != 0.0) {
        setState(() {
          users[user] = ratedValue;
        });
      }
    }
  }



  Future<void> getUserRating() async {
    String? sessionId = await SessionManager.getSessionId();
    print(sessionId);

    Map<dynamic, dynamic> ratedMovieResult = await Singleton
        .tmdbWithCustLogs.v3.tv
        .getAccountStatus(widget.gameID, sessionId: sessionId);

// Extract the data from the ratedMovieResult
    int? seriesId = ratedMovieResult['id'];
    bool favorite = ratedMovieResult['favorite'];
    double ratedValue = 0.0; // Default value is 0.0

    if (ratedMovieResult['rated'] is Map<String, dynamic>) {
      Map<String, dynamic> ratedData = ratedMovieResult['rated'];
      ratedValue = ratedData['value']?.toDouble() ?? 0.0;
    }

    bool watchlist = ratedMovieResult['watchlist'];

    setState(() {
      initialRating = ratedValue;
      isRated = ratedValue == 0.0 ? false : true;
      watchlistState = watchlist;
      reccState = favorite;
    });
  }





  Future<void> getUserAccounts() async {
    UserAccountState? userRating =
        await Singleton.getUserRatingTV(widget.gameID);
    setState(() {
      userAccountState = userRating;
    });
  }

  Future<void> fetchData() async {
    int ID = widget.gameID;
    final url = Uri.parse(
        'https://api.rawg.io/api/games/${widget.gameID}?key=${RawgApiService.apiKey}');

    print(url);
    final response = await http.get(url);

    print(response.statusCode);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
      setState(() {
        gameData = data;
        voteAverage = gameData['rating'] != null
            ? Singleton.parseDouble(gameData['rating'])
            : 0.0;
        metacritics = gameData['metacritic'] != null
            ? Singleton.parseDouble(gameData['metacritic'])
            : 0;
        added = gameData['added'] != null
            ? Singleton.parseDouble(gameData['added'])
            : 0;
        playtime = gameData['playtime'] != null
            ? Singleton.parseDouble(gameData['playtime'])
            : 0;
        moviesCount = gameData['movies_count'] != null
            ? Singleton.parseDouble(gameData['movies_count'])
            : 0;
        creatorsCount = gameData['creators_count'] != null
            ? Singleton.parseDouble(gameData['creators_count'])
            : 0;
        achievementsCount = gameData['achievements_count'] != null
            ? Singleton.parseDouble(gameData['achievements_count'])
            : 0;
        parentAchievementsCount = gameData['parent_achievements_count'] != null
            ? Singleton.parseDouble(gameData['parent_achievements_count'])
            : 0;
        metacriticsPlatforms = gameData['metacritic_platforms'] ?? [];
        title = gameData['name'] != null && gameData['name'].isNotEmpty
            ? gameData['name']
            : '';
        addedByStatus = gameData['added_by_status'] ?? {};
        title = gameData['name'] != null && gameData['name'].isNotEmpty
            ? gameData['name']
            : '';
        originalTitle = gameData['name_original'] != null && gameData['name_original'].isNotEmpty
            ? gameData['name_original']
            : '';
        bannerUrl = gameData['background_image'] != null && gameData['background_image'].isNotEmpty
            ? gameData['background_image']
            : '';
        additionalBannerUrl = gameData['background_image_additional'] != null && gameData['background_image_additional'].isNotEmpty
            ? gameData['background_image_additional']
            : '';
        launchOn = gameData['released'] != null && gameData['released'].isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(gameData['released']))
            : '';
        website = gameData['website'] != null && gameData['website'].isNotEmpty ? gameData['website'] : '';
        redditUrl = gameData['reddit_url'] != null && gameData['reddit_url'].isNotEmpty ? gameData['reddit_url'] : '';
        redditName = gameData['reddit_name'] != null && gameData['reddit_name'].isNotEmpty ? gameData['reddit_name'] : '';
        redditDescription = gameData['reddit_description'] != null && gameData['reddit_description'].isNotEmpty ? gameData['reddit_description'] : '';
        redditLogo = gameData['reddit_logo'] != null && gameData['reddit_logo'].isNotEmpty ? gameData['reddit_logo'] : '';
        redditCount = gameData['reddit_count'] != null
            ? Singleton.parseDouble(gameData['reddit_count'])
            : 0;
        twitchCount = gameData['twitch_count'] != null
            ? Singleton.parseDouble(gameData['twitch_count'])
            : 0;
        youtubeCount = gameData['youtube_count'] != null
            ? Singleton.parseDouble(gameData['youtube_count'])
            : 0;
        ratingsCount = gameData['ratings_count'] != null
            ? Singleton.parseDouble(gameData['ratings_count'])
            : 0;
        suggestionCount = gameData['suggestions_count'] != null
            ? Singleton.parseDouble(gameData['suggestions_count'])
            : 0;
        reviewsCount = gameData['reviews_count'] != null
            ? Singleton.parseDouble(gameData['reviews_count'])
            : 0;
        metacriticUrl = gameData['metacritic_url'] != null && gameData['metacritic_url'].isNotEmpty ? gameData['metacritic_url'] : '';
        parentPlatforms = gameData['parent_platforms'] ?? [];
        platforms = gameData['platforms'] ?? [];
        stores = gameData['stores'] ?? [];
        developers = gameData['developers'] ?? [];
        genres = gameData['genres'] ?? [];
        tags = gameData['tags'] ?? [];
        publishers = gameData['publishers'] ?? [];
        esrbRating = gameData['esrb_rating'] ?? {};
        description = gameData['description_raw'] != null && gameData['description_raw'].isNotEmpty ? gameData['description_raw'] : '';
        id = gameData['id'] != null ? gameData['id'] : 0;
        genres = gameData['genres'] != null && gameData['genres'].isNotEmpty ? gameData['genres'] : [];

      });
    } else {
      throw Exception('Failed to fetch data');
    }


    getColorPalette();




  }

  Future<void> getColorPalette() async {
    if (bannerUrl.isNotEmpty) {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(bannerUrl),
        size: Size(100, 150), // Adjust the image size as needed
        maximumColorCount: 10, // Adjust the maximum color count as needed
      );
      setState(() {
        colorpalette = paletteGenerator.dominantColor?.color ?? Singleton.thirdTabColor;
        lightColor = paletteGenerator.lightVibrantColor?.color ?? colorpalette;
        darkColor = paletteGenerator.darkVibrantColor?.color ?? colorpalette;
        isColorLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        backgroundColor: Colors.black,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        //Init Floating Action Bubble
        floatingActionButton: !Singleton.isGuest ? dataLoaded ? Padding(
          padding: EdgeInsets.only(bottom: 70, right: 10),
          child: FloatingActionBubble(
            // Menu items
            items: <Bubble>[
              Bubble(
                icon: watchlistState ? Icons.bookmark : Icons.bookmark_border,
                bubbleColor: Singleton.fifthTabColor,
                onPress: () {
                  toggleWatchlist();
                  HapticFeedback.lightImpact();
                  _animationController.reverse();
                },
                title: translate("Watchlist"),
                iconColor:
                    watchlistState ? Singleton.secondTabColor : Colors.white,
                titleStyle: TextStyle(fontSize: 16, color: Colors.white),
              ),
              // Floating action menu item
              Bubble(
                icon: isRated ? CupertinoIcons.star_fill : CupertinoIcons.star,
                bubbleColor: Singleton.firstTabColor,
                onPress: () {
                  HapticFeedback.lightImpact();
                  Singleton.showRatingDialogTV(context, userAccountState!);
                  _animationController.reverse();
                },
                title: translate("Bewertung"),
                iconColor: isRated ? Colors.yellow : Colors.white,
                titleStyle: TextStyle(fontSize: 16, color: Colors.white),
              ),
              // Floating action menu item

              //Floating action menu item
              Bubble(
                icon: reccState ? Icons.recommend : Icons.recommend_outlined,
                bubbleColor: Singleton.thirdTabColor,
                onPress: () {
                  toggleRecommended();
                  HapticFeedback.lightImpact;
                  _animationController.reverse();
                },
                title: translate('Empfehlung'),
                iconColor: reccState ? Singleton.firstTabColor : Colors.white,
                titleStyle: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],

            // animation controller
            animation: _animation,

            // On pressed change animation state
            onPress: () => _animationController.isCompleted
                ? _animationController.reverse()
                : _animationController.forward(),

            // Floating Action button Icon color
            iconColor: Colors.white,

            // Flaoting Action button Icon
            iconData: Icons.menu,
            backGroundColor: Singleton.firstTabColor,
          ),
        ): Container() : Container(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.0, 0.4), // Start at the middle left
              end: Alignment(0.0, 0.1), // End a little above the middle
              colors: [colorpalette.withOpacity(0.8), Colors.black],
            ),
          ),
          child:  dataLoaded ? Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      additionalBannerUrl.isNotEmpty
                          ? ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color.fromRGBO(0, 0, 0, 1),
                                  ],
                                  stops: [0.1, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.darken,
                              child: Image.network(
                                additionalBannerUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey.withOpacity(
                                    0.2), // Customize the color here
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                    bottom: 10,
                    top: MediaQuery.of(context).size.height * 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          title.isNotEmpty ? title : translate('Loading...'),
                          speed: Duration(milliseconds: 150),
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      isRepeatingAnimation: true,
                      repeatForever: false,
                      totalRepeatCount: 2,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.width * 0.65,
                              width: MediaQuery.of(context).size.width * 0.4,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                      color: lightColor,
                                      offset: Offset(4.0, 4.0),
                                      blurRadius: 15.0,
                                      spreadRadius: 1.0
                                  ),
                                  BoxShadow(
                                      color: lightColor,
                                      offset: Offset(-4.0, -4.0),
                                      blurRadius: 15.0,
                                      spreadRadius: 1.0
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: bannerUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: ImageFade(
                                        image: NetworkImage(
                                          bannerUrl,
                                        ),
                                        // slow fade for newly loaded images:
                                        duration: Duration(seconds: 4),
                                        alignment: Alignment.center,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors
                                            .grey, // Customize the color here
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.photo,
                                          color: Colors.white,
                                          // Customize the icon color here
                                          size: 50,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 1,
                              left: 1,
                              child: CircularPercentIndicator(
                                radius: 28.0,
                                lineWidth: 8.0,
                                animation: true,
                                animationDuration: 4000,
                                percent: voteAverage / 10,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Countup(
                                      begin: 0,
                                      precision: 1,
                                      end: voteAverage,
                                      //here you insert the number or its variable
                                      duration: Duration(seconds: 4),
                                      separator: '.',
                                      //this is the character you want to add to seperate between every 3 digits
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    initialRating != 0.0
                                        ? SizedBox(height: 2)
                                        : SizedBox(height: 0),
                                    initialRating != 0.0
                                        ? Countup(
                                            begin: 0,
                                            precision: 1,
                                            end: initialRating,
                                            //here you insert the number or its variable
                                            duration: Duration(seconds: 3),
                                            separator: '.',
                                            //this is the character you want to add to seperate between every 3 digits
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Container(),
                                  ],
                                ),
                                circularStrokeCap: CircularStrokeCap.round,
                                backgroundColor: Colors.transparent,
                                progressColor: Singleton.getCircleColor(
                                  Singleton.parseDouble(voteAverage),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Card(
                                color: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 5,
                                        runSpacing: 5,
                                        children: [
                                          Singleton.buildInfoRow(
                                              Icons.calendar_today,
                                              '${launchOn ?? ''}', false),
                                          Singleton.buildInfoRow(
                                              Icons.contact_page, '$website', true),
                                          Singleton.buildInfoRow(
                                              Icons.av_timer,
                                              '${playtime.toInt()} Hours', false),
                                          Singleton.buildInfoRow(
                                            Icons.eighteen_up_rating,
                                            esrbRating['name'] ?? '', false,
                                          ),
                                          Singleton.buildInfoRow(
                                              Icons.score, '${metacritics.toInt()}', false),
                                          Singleton.buildCountupRow(
                                              Icons.star,
                                              '',
                                              ratingsCount,
                                              Colors.yellow,
                                              ''),
                                          Singleton.buildCountupRow(
                                              Icons.recommend,
                                              '',
                                              suggestionCount,
                                              Colors.green,
                                              ''),
                                          SizedBox(height: 10),
                                          genres.isNotEmpty
                                              ? FittedBox(
                                            child: GenreList(
                                              genres: genres,
                                              color: Color(0xff540126),
                                              isMovieKeyword: false,
                                            ),
                                          )
                                              : Container(),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    users.isNotEmpty
                        ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.1,
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),

                        scrollDirection: Axis.horizontal,
                        itemCount: users.length,
                        itemBuilder: (BuildContext context, int index) {
                          AppUser user = users.keys.elementAt(index);
                          double? rating = users[user];
                          return Container(
                            margin: EdgeInsets.only(right: 10),
                            width:
                            MediaQuery.of(context).size.width * 0.2,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    user.imagePath,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  bottom: 1,
                                  left: 1,
                                  child: Container(
                                    width: MediaQuery.of(context)
                                        .size
                                        .width *
                                        0.1,
                                    height: MediaQuery.of(context)
                                        .size
                                        .height *
                                        0.05,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Singleton.getCircleColor(
                                          rating!),
                                    ),
                                    child: Center(
                                      child: Text(
                                        rating.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                        : Container(),
                    SizedBox(height: 10),
                    keywords.isNotEmpty
                        ? GenreList(
                      genres: keywords,
                      color: Color(0xff690257),
                      isMovieKeyword: false,
                    )
                        : Container(),
                    SizedBox(height: 10,),
                    ExpansionTile(
                      shape: const ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30))
                      ),
                      collapsedShape: const ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30))
                      ),
                      collapsedBackgroundColor:
                          Singleton.fifthTabColor.withOpacity(0.6),
                      backgroundColor: Colors.black.withOpacity(0.6),
                      childrenPadding: EdgeInsets.all(10),
                      iconColor: Singleton.thirdTabColor,
                      collapsedIconColor: Singleton.firstTabColor,
                      title: Text(
                        translate('Beschreibung'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        SizedBox(height: 10),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    watchProvidersList.isNotEmpty
                        ? WatchProvidersScreen(
                            watchProviders: watchProvidersList, selectedCountry: defaultCountry,)
                        : Container(),
                    ],
                      ),
                    ),
                    SizedBox(height: 10),
                    _bannerAd != null
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                    SizedBox(height: 10),
                    creditData.isNotEmpty
                        ? PeopleScreen(
                            people: creditData.length < 10
                                ? creditData
                                : creditData.sublist(0, 10),
                            allPeople: creditData,
                            title: translate('Cast und Crew'),
                            buttonColor: Color(0xff540126),
                          )
                        : Container(),
                    SizedBox(height: 10),
                    reviews.isNotEmpty
                        ? RatingsDisplayWidget(
                            id: widget.gameID,
                            isMovie: false,
                            reviews: reviews.length < 10
                                ? reviews
                                : reviews.sublist(0, 10),
                            movieID: widget.gameID,
                          )
                        : Container(),
                    images.isNotEmpty
                        ? ImageScreen(
                            images: images.length < 10
                                ? images
                                : images.sublist(0, 10),
                            movieID: widget.gameID,
                            title: translate('Bilder'),
                            buttonColor: Color(0xff540126),
                            backdrop: false,
                            overview: true,
                            isMovie: 2, allImages: allImages,
                          )
                        : Container(),
                  ],
                ),
              ),
            ],
          ): isColorLoaded ? Singleton.ShimmerEffectDetailScreens(context, lightColor) : Container() ,
        ));
  }


  void toggleWatchlist() {
    setState(() {
      watchlistState = !watchlistState;
    });
    if (watchlistState) {
      // Add to watchlist logic
      Singleton.addToWatchlist(context, accountID, sessionID, false, id);
    } else {
      // Remove from watchlist logic
      Singleton.removeFromWatchlist(context, accountID, sessionID, false, id);
    }
  }

  void toggleRecommended() {
    setState(() {
      reccState = !reccState;
    });
    if (reccState) {
      // Add to watchlist logic
      Singleton.addToRecommendations(context, accountID, sessionID, false, id);
    } else {
      // Remove from watchlist logic
      Singleton.removeFromRecommendations(
          context, accountID, sessionID, false, id);
    }
  }
}
