import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:countup/countup.dart';
import 'package:game_grove/api/rawg_api.dart';
import 'package:game_grove/screens/collections.dart';
import 'package:game_grove/utils/AdMobService.dart';
import 'package:game_grove/utils/SessionManager.dart';
import 'package:game_grove/widgets/genreWidget.dart';
import 'package:game_grove/widgets/images_screen.dart';
import 'package:game_grove/widgets/lists.dart';
import 'package:game_grove/widgets/movies.dart';
import 'package:game_grove/widgets/people.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:game_grove/widgets/reviews.dart';
import 'package:game_grove/widgets/series.dart';
import 'package:game_grove/widgets/tv_seasons.dart';
import 'package:game_grove/widgets/video_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:game_grove/widgets/watchProviders.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_fade/image_fade.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:http/http.dart' as http;

import 'Database/WatchProvider.dart';
import 'Database/user.dart';
import 'Database/userAccountState.dart';

class DescriptionMovies extends StatefulWidget {
  final int movieID;
  late bool isMovie;

  DescriptionMovies({super.key, required this.movieID, required this.isMovie});

  @override
  _DescriptionState createState() => _DescriptionState();
}

class _DescriptionState extends State<DescriptionMovies>
    with SingleTickerProviderStateMixin {
  final Future<int?> accountID = SessionManager.getAccountId();
  Map<String, dynamic> dataColl = {};
  List creditData = [];
  List<WatchProvider> watchProvidersList = [];
  late Future<String?> sessionID = SessionManager.getSessionId();
  String sessionId = '';
  late String apiKey;
  double voteAverage = 0;
  int voteCount = 0;
  String title = '';
  String posterUrl = '';
  String bannerUrl = '';
  String launchOn = '';
  String description = '';
  int id = 0;
  int revenue = 0;
  int runtime = 0;
  String status = '';
  String tagline = '';
  int budget = 0;
  double initialRating = 0.0;
  bool isRated = false;
  List recommendedMovies = [];
  List listsIn = [];
  List similarMovies = [];
  List genres = [];
  Map collections = {};
  List imagePaths = [];
  List reviews = [];
  List keywords = [];
  List videoItems = [];
  NumberFormat formatter = NumberFormat('###,###,###,###');
  Map<AppUser, double> users = {};
  UserAccountState? userAccountState = null;

  bool watchlistState = false;
  bool reccState = false;

  Color colorpalette = Singleton.thirdTabColor;
  Color lightColor = Singleton.secondTabColor;
  Color darkColor = Singleton.fourthTabColor;

  late Animation<double> _animation;
  late AnimationController _animationController;

  String defaultCountry = '';
  String defaultLanguage = '';

  BannerAd? _bannerAd;

  bool dataLoaded = false;
  bool isColorLoaded = false;

  int accountId = 0;

  Map allImages = {};


  @override
  void initState() {
    super.initState();
    loadAd();
    initialise();
  }


  Future<void> initialise() async {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );
    final curvedAnimation =
    CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    apiKey = RawgApiService.getApiKey();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultCountry = prefs.getString('selectedCountry')!;
      defaultLanguage = prefs.getString('selectedLanguage')!;
    });
    await setIDs();


    await Future.wait([fetchTasks(),
      ]);

    fetchUserData();

    setState(() {
      dataLoaded = true;
    });
  }

  Future<void> fetchUserData() async {
    if (accountId>= 1) {
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
    getRecommendedMovies(),
    getSimilarMovies(),
    getReviews(),
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

  Future<void> getUserRating() async {
    String? sessionId = await SessionManager.getSessionId();

    Map<dynamic, dynamic> ratedMovieResult = await Singleton
        .tmdbWithCustLogs.v3.movies
        .getAccountStatus(widget.movieID, sessionId: sessionId);

// Extract the data from the ratedMovieResult
    int? movieId = ratedMovieResult['id'];
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
          .tmdbWithCustLogs.v3.movies
          .getAccountStatus(widget.movieID, sessionId: sessionId);

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

  Future<void> getRecommendedMovies() async {
    Map watchlistResults =
        await Singleton.tmdbWithCustLogs.v3.movies.getRecommended(
      widget.movieID,
    );

    setState(() {
      recommendedMovies = watchlistResults['results'];
    });
  }

  Future<void> getReviews() async {
    Map watchlistResults =
        await Singleton.tmdbWithCustLogs.v3.movies.getReviews(
      widget.movieID,
    );

    TMDB tmdbWithCustLogs = TMDB(
      ApiKeys(Singleton.apiKey, Singleton.readAccToken),
      logConfig: const ConfigLogger(showLogs: true, showErrorLogs: true),
    );
    Map watchlistResultsEn = await tmdbWithCustLogs.v3.movies.getReviews(
      widget.movieID,
    );

    setState(() {
      reviews = watchlistResults['results'];
      if(defaultLanguage != 'en') {
        reviews.addAll(watchlistResultsEn['results']);
      }

    });
  }

  Future<void> getSimilarMovies() async {
    Map watchlistResults =
        await Singleton.tmdbWithCustLogs.v3.movies.getSimilar(
      widget.movieID,
    );
    setState(() {
      similarMovies = watchlistResults['results'];
    });
  }


  Future<void> getUserAccounts() async {
    UserAccountState? userRating =
        await Singleton.getUserRatingMovie(widget.movieID);
    setState(() {
      userAccountState = userRating;
    });
  }

  Future<void> fetchData() async {
    String? sessionId = await sessionID;
    int ID = widget.movieID;
    final url = Uri.parse(
        'https://api.themoviedb.org/3/movie/$ID.?api_key=$apiKey&session_id=$sessionId&language=$defaultLanguage&append_to_response=images,videos,credits,watch/providers,keywords,lists');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        dataColl = data;
        voteAverage = dataColl['vote_average'] != null
            ? Singleton.parseDouble(dataColl['vote_average'])
            : 0.0;
        title = dataColl['title'] != null && dataColl['title'].isNotEmpty
            ? dataColl['title']
            : '';
        posterUrl = dataColl['poster_path'] != null && dataColl['poster_path'].isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500' + dataColl['poster_path']
            : '';
        bannerUrl = dataColl['backdrop_path'] != null && dataColl['backdrop_path'].isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500' + dataColl['backdrop_path']
            : '';
        launchOn = dataColl['release_date'] != null && dataColl['release_date'].isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(dataColl['release_date']))
            : '';
        description = dataColl['overview'] != null && dataColl['overview'].isNotEmpty ? dataColl['overview'] : '';
        id = dataColl['id'] != null ? dataColl['id'] : 0;
        revenue = dataColl['revenue'] != null ? dataColl['revenue'] : '';
        runtime = dataColl['runtime'] != null ? dataColl['runtime'] : '';
        status = dataColl['status'] != null && dataColl['status'].isNotEmpty ? dataColl['status'] : '';
        tagline = dataColl['tagline'] != null && dataColl['tagline'].isNotEmpty ? dataColl['tagline'] : '';
        budget = dataColl['budget'] != null ? dataColl['budget'] : '';
        genres = dataColl['genres'] != null && dataColl['genres'].isNotEmpty ? dataColl['genres'] : [];
        voteCount = dataColl['vote_count'] != null ? dataColl['vote_count'] : 0;
        collections = dataColl['belongs_to_collection'] != null && dataColl['belongs_to_collection'].isNotEmpty ? dataColl['belongs_to_collection'] : {};
        imagePaths = dataColl['images']['posters'] ?? [];
        keywords = dataColl['keywords']['keywords'] ?? [];
        listsIn = dataColl['lists']['results'] ?? [];
        creditData = dataColl['credits']['cast'] ?? [];
        videoItems = dataColl['videos']['results'] ?? [];
        allImages = dataColl['images'] ?? [];

        getColorPalette();
        Map<String, dynamic> watchProviderData =
            dataColl['watch/providers'];

        watchProviderData['results'].forEach((country, data) {
          String link = data['link'];
          List<Map<String, dynamic>> flatrate =
          data['flatrate'] != null ? List.from(data['flatrate']) : [];
          List<Map<String, dynamic>> rent =
          data['rent'] != null ? List.from(data['rent']) : [];
          List<Map<String, dynamic>> buy =
          data['buy'] != null ? List.from(data['buy']) : [];

          WatchProvider watchProvider = WatchProvider(
            country: country,
            link: link,
            flatrate: flatrate,
            rent: rent,
            buy: buy,
          );

          watchProvidersList.add(watchProvider);
        });

      });
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        //Init Floating Action Bubble
        floatingActionButton: !Singleton.isGuest ?  dataLoaded ? Padding(
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
                  Singleton.showRatingDialogMovie(context, userAccountState!);
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
        ):Container() : Container(),
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
                      bannerUrl.isNotEmpty
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
                                bannerUrl,
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
                        SizedBox(height: 5),
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
                                  child: dataColl['poster_path'] != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: ImageFade(
                                      image: NetworkImage(
                                        'https://image.tmdb.org/t/p/w500' +
                                            (dataColl['poster_path'] ?? ''),
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
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  tagline.isNotEmpty ?
                                  Text(
                                    tagline.isNotEmpty ? tagline : translate('Loading...'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : Container(),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 5,
                                            runSpacing: 5,
                                            children: [
                                              Singleton.buildInfoRow(Icons.info, '$status', false),
                                              Singleton.buildInfoRow(Icons.calendar_today, '${launchOn ?? ''}', false),
                                              Singleton.buildCountupRow(Icons.access_time, '', runtime.toDouble(), Colors.yellow, 'min'),
                                              Singleton.buildCountupRow(Icons.star, '', voteCount.toDouble(), Colors.orange, ''),
                                              Singleton.buildCountupRow(Icons.money_off, '', budget.toDouble(), Colors.red, '\$'),
                                              Singleton.buildCountupRow(Icons.monetization_on, '', revenue.toDouble(), Colors.green, '\$'),
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
                        SizedBox(
                          height: 10,
                        ),
                        keywords.isNotEmpty
                            ? GenreList(
                          genres: keywords,
                          color: Color(0xff690257),
                          isMovieKeyword: true,
                          sessionID: sessionId,
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
                          childrenPadding: EdgeInsets.all(20),
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
                        SizedBox(
                          height: 10,
                        ),
                        watchProvidersList.isNotEmpty
                            ? WatchProvidersScreen(
                          watchProviders: watchProvidersList, selectedCountry: defaultCountry,)
                            : Container(),
                      ],),
                    ),

                    SizedBox(
                      height: 10,
                    ),
                    _bannerAd != null
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        _bannerAd != null ?Container(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ) : Container(),
                      ],
                    )
                        : Container(),
                    creditData.isNotEmpty
                        ? PeopleScreen(
                            people: creditData.length < 10
                                ? creditData
                                : creditData.sublist(0, 10),
                            allPeople: creditData,
                            title: translate('Cast und Crew'),
                            buttonColor: Color(0xff540126))
                        : Container(),
                    SizedBox(
                      height: 10,
                    ),
                    recommendedMovies.isNotEmpty
                        ? MoviesScreen(
                            movies: recommendedMovies,
                            allMovies: recommendedMovies,
                            title: translate('Empfohlene Filme'),
                            buttonColor: Color(0xff540126),
                            movieID: widget.movieID,
                            typeOfApiCall: 1,
                          )
                        : Container(),
                    SizedBox(
                      height: 10,
                    ),
                    similarMovies.isNotEmpty
                        ? MoviesScreen(
                            movies: similarMovies,
                            allMovies: similarMovies,
                            title: translate('Ähnliche Filme'),
                            buttonColor: Color(0xff540126),
                            movieID: widget.movieID,
                            typeOfApiCall: 0,
                          )
                        : Container(),
                    SizedBox(
                      height: 10,
                    ),
                    collections.isNotEmpty
                        ? CollectionScreen(
                            collections: collections,
                            title: translate('Collection'),
                            buttonColor: Color(0xff540126))
                        : Container(),
                    SizedBox(
                      height: 10,
                    ),
                    reviews.isNotEmpty
                        ? RatingsDisplayWidget(
                            id: widget.movieID,
                            isMovie: true,
                            reviews: reviews.length < 10
                                ? reviews
                                : reviews.sublist(0, 10),
                            movieID: widget.movieID,
                          )
                        : Container(),
                    SizedBox(height: 10),
                    videoItems.isNotEmpty
                        ? VideoWidget(
                            videoItems: videoItems,
                            title: translate('Videos'),
                            buttonColor: Color(0xff540126))
                        : Container(),
                    SizedBox(
                      height: 10,
                    ),
                    imagePaths.isNotEmpty
                        ? ImageScreen(
                            images: imagePaths.length < 10
                                ? imagePaths
                                : imagePaths.sublist(0, 10),
                            movieID: widget.movieID,
                            title: translate('Bilder'),
                            buttonColor: Color(0xff540126),
                            backdrop: false,
                            overview: true,
                            isMovie: 1, allImages: allImages,
                          )
                        : Container(),
                    SizedBox(
                      height: 10,
                    ),
                    listsIn.isNotEmpty
                        ? ListsScreen(
                      sessionID: sessionId,
                            lists: listsIn,
                            allMovies: listsIn,
                            title: translate('Listen'),
                            buttonColor: Color(0xff540126),
                            listID: widget.movieID,
                          )
                        : Container(),
                  ],
                ),
              ),
            ],
          ): isColorLoaded ? Singleton.ShimmerEffectDetailScreens(context, lightColor) : Container(),
        ));
  }

  void toggleWatchlist() {
    setState(() {
      watchlistState = !watchlistState;
    });
    if (watchlistState) {
      // Add to watchlist logic
      Singleton.addToWatchlist(context, accountID, sessionID, true, id);
    } else {
      // Remove from watchlist logic
      Singleton.removeFromWatchlist(context, accountID, sessionID, true, id);
    }
  }

  void toggleRecommended() {
    setState(() {
      reccState = !reccState;
    });
    if (reccState) {
      // Add to watchlist logic
      Singleton.addToRecommendations(context, accountID, sessionID, true, id);
    } else {
      // Remove from watchlist logic
      Singleton.removeFromRecommendations(
          context, accountID, sessionID, true, id);
    }
  }

  Future<void> getColorPalette() async {
    if (posterUrl.isNotEmpty) {
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        NetworkImage(posterUrl),
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
}
