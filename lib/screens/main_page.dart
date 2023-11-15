import 'dart:convert';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:game_grove/api/rawg_api.dart';
import 'package:game_grove/utils/AdMobService.dart';
import 'package:game_grove/widgets/movies.dart';
import 'package:game_grove/widgets/people.dart';
import 'package:game_grove/widgets/series.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:marquee/marquee.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tmdb_api/tmdb_api.dart';

import '../Database/user.dart';
import '../Database/userAccountState.dart';
import '../movieDetail.dart';
import '../seriesDetail.dart';
import '../utils/SessionManager.dart';
import '../utils/text.dart';
import '../widgets/singleton.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Widget> sliderMovies = [];
  List<Widget> sliderSeries = [];
  List trendingGames = [];

  final Future<String?> sessionID = SessionManager.getSessionId();
  final Future<int?> accountID = SessionManager.getAccountId();
  String? sessionId;
  int? accountId = 0;

  List<AppUser> following = [];
  AppUser randUser = AppUser(accountId: 0, sessionId: '');

  List<dynamic> recommendedMovies = [];
  List<dynamic> recommendedSeries = [];

  BannerAd? _bannerAd;

  final String apiKey = '24b3f99aa424f62e2dd5452b83ad2e43';
  final readAccToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyNGIzZjk5YWE0MjRmNjJlMmRkNTQ1MmI4M2FkMmU0MyIsInN1YiI6IjYzNjI3NmU5YTZhNGMxMDA4MmRhN2JiOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.fiB3ZZLqxCWYrIvehaJyw6c4LzzOFwlqoLh8Dw77SUw';

  String defaultLanguage = "";
  String defaultCountry = "";

  bool dataLoaded = false;

  List topRatedMetacriticsGames  =[];
  List topRatedGames = [];
  List newestGames = [];

  @override
  void initState() {
    super.initState();
    loadAd();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await setIDs();

    await Future.wait([
      loadMoviesData(),
      if (accountId! >= 1) _searchUsers(),
    ]);

    setState(() {
      dataLoaded = true;
    });
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
    accountId = await accountID;
    sessionId = await sessionID;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultLanguage = prefs.getString('selectedLanguage')!;
      defaultCountry = prefs.getString('selectedCountry')!;
    });
  }

  Future<void> _searchUsers() async {
    following.clear();

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = await auth.authStateChanges().first;

    if (user != null) {
      final ref = FirebaseDatabase.instance
          .ref("users")
          .child(accountId.toString())
          .child('following');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        await Future.wait(data.values.map((value) async {
          final accountId = value['accountId'] as int;
          final sessionId = value['sessionId'] as String;
          final user = AppUser(accountId: accountId, sessionId: sessionId);
          await user.loadUserData();
          setState(() {
            following.add(user);
          });
        }));

        Random random = Random();
        int randomIndex = random.nextInt(following.length);

        randUser = following[randomIndex];
      } else {
        print('No data available.');
      }

      await Future.wait([loadRecommendedMovies(), loadRecommendedSeries()]);

      setState(() {
        recommendedMovies.shuffle();
        recommendedSeries.shuffle();
      });
    } else {
      print('User is not authenticated');
    }
  }

  Future<void> loadMoviesData() async {
    await Future.wait([
      loadTrendingGames(),
      loadTopRatedGames(),
      loadTopRatedMetacriticsGames(),
    ]);
  }

  Future<void> loadTrendingGames() async {
    final url = Uri.parse(
        'https://api.rawg.io/api/games?key=${RawgApiService.apiKey}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        trendingGames = data['results'];
      });
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  Future<void> loadTopRatedGames() async {
    final url = Uri.parse(
        'https://api.rawg.io/api/games?key=${RawgApiService.apiKey}&ordering=-rating');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        topRatedGames = data['results'];
      });
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  Future<void> loadTopRatedMetacriticsGames() async {
    final url = Uri.parse(
        'https://api.rawg.io/api/games?key=${RawgApiService.apiKey}&ordering=-metacritic');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        topRatedMetacriticsGames = data['results'];
      });
    } else {
      throw Exception('Failed to fetch data');
    }
  }




  Future<void> loadTopRatedMovies() async {
    Map topratedMoviesResults =
    await Singleton.tmdbWithCustLogs.v3.movies.getTopRated(language: defaultLanguage, region: defaultCountry);
    setState(() {
      trendingGames = topratedMoviesResults['results'];
    });
  }


  Future<void> loadRecommendedMovies() async {
    int reccMovieTotalPages = 1;
    List<dynamic> recommendedMoviesRes = [];

    Map<dynamic, dynamic> reccMovieInfo =
    await Singleton.tmdbWithCustLogs.v3.account.getFavoriteMovies(
      language: defaultLanguage,
      randUser.sessionId,
      randUser.accountId,
      page: 1,
    );

    if (reccMovieInfo.containsKey('total_pages')) {
      reccMovieTotalPages = reccMovieInfo['total_pages'];
    }

    for (int page = 1; page <= reccMovieTotalPages; page++) {
      Map<dynamic, dynamic> reccMovieResults =
      await Singleton.tmdbWithCustLogs.v3.account.getFavoriteMovies(
        randUser.sessionId,
        randUser.accountId,
        page: page,
      );
      recommendedMoviesRes.addAll(reccMovieResults['results']);
    }

    setState(() {
      recommendedMovies = recommendedMoviesRes;
      sliderMovies = recommendedMovies.take(20).map((item) {
        Map<String, dynamic>? movie = item;
        double? voteAverage = double.parse(movie!['vote_average'].toString());
        int? movieId = movie['id'];
        String? posterPath = movie['poster_path'];
        String originalTitle = movie['title'] ?? '';
        Key itemKey = Key(movieId.toString());
        return Container(
          height: 250,
          child: FutureBuilder<UserAccountState>(
            future: Singleton.getUserRatingMovie(movieId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Shimmer.fromColors(
                    baseColor: Singleton.thirdTabColor!,
                    highlightColor: Colors.grey[100]!,
                    child: SizedBox(
                      width: 160,
                      height: 250,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                );
              } else if (snapshot.hasData) {
                UserAccountState? userRating = snapshot.data;
                return Padding(
                  key: itemKey,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onLongPress: () {
                      Singleton.showRatingDialogMovie(context, userRating!);
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DescriptionMovies(
                            movieID: movieId,
                            isMovie: true,
                          ),
                        ),
                      );
                    },
                    child: InkWell(
                      child: SizedBox(
                        width: 160,
                        child: Stack(
                          children: [
                            Container(
                              height: 250,
                              decoration: posterPath != null
                                  ? BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://image.tmdb.org/t/p/w500' +
                                        posterPath,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : BoxDecoration(
                                color: Singleton.thirdTabColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                  bottom: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CircularPercentIndicator(
                                      radius: 28.0,
                                      lineWidth: 8.0,
                                      animation: true,
                                      animationDuration: 1000,
                                      percent: voteAverage / 10,
                                      center: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            voteAverage.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (userRating != null &&
                                              userRating.ratedValue != 0.0)
                                            SizedBox(height: 2),
                                          if (userRating != null &&
                                              userRating.ratedValue != 0.0)
                                            Text(
                                              userRating.ratedValue
                                                  .toStringAsFixed(1),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                      circularStrokeCap: CircularStrokeCap.round,
                                      backgroundColor: Colors.transparent,
                                      progressColor: Singleton.getCircleColor(
                                        Singleton.parseDouble(voteAverage),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Marquee(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        fadingEdgeEndFraction: 0.9,
                                        fadingEdgeStartFraction: 0.1,
                                        blankSpace: 200,
                                        pauseAfterRound: Duration(seconds: 4),
                                        text: originalTitle,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (posterPath == null)
                              Center(
                                child: Icon(
                                  Icons.photo,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return Container();
              }
            },
          ),
        );
      }).toList();
    });
  }

  Future<void> loadRecommendedSeries() async {
    int reccSeriesTotalPages = 1;
    List<dynamic> recommendedSeriesRes = [];

    Map<dynamic, dynamic> reccSeriesInfo =
    await Singleton.tmdbWithCustLogs.v3.account.getFavoriteTvShows(
      language: defaultLanguage,
      randUser.sessionId,
      randUser.accountId,
      page: 1,
    );

    if (reccSeriesInfo.containsKey('total_pages')) {
      reccSeriesTotalPages = reccSeriesInfo['total_pages'];
    }

    for (int page = 1; page <= reccSeriesTotalPages; page++) {
      Map<dynamic, dynamic> reccSeriesResults =
      await Singleton.tmdbWithCustLogs.v3.account.getFavoriteTvShows(
        randUser.sessionId,
        randUser.accountId,
        page: page,
      );
      recommendedSeriesRes.addAll(reccSeriesResults['results']);
    }

    setState(() {
      recommendedSeries = recommendedSeriesRes;
      sliderSeries = recommendedSeries.take(20).map((item) {
        Map<String, dynamic> series = item;
        double voteAverage = double.parse(series['vote_average'].toString());

        return Container(
          height: 170,
          child: FutureBuilder<UserAccountState>(
            future: Singleton.getUserRatingTV(series['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Shimmer.fromColors(
                    baseColor: Singleton.thirdTabColor!,
                    highlightColor: Colors.grey[100]!,
                    child: SizedBox(
                      width: 250,
                      height: 180,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                );
              } else if (snapshot.hasData) {
                UserAccountState? userRating = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: InkWell(
                    onLongPress: () {
                      Singleton.showRatingDialogTV(context, userRating!);
                    },
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DescriptionSeries(
                            gameID: series['id'],
                            isMovie: false,
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 250,
                      child: Stack(
                        children: [
                          Container(
                              height: 180,
                              decoration: series['backdrop_path'] != null
                                  ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      'https://image.tmdb.org/t/p/w500' +
                                          series['backdrop_path'],
                                    ),
                                    fit: BoxFit.cover,
                                  ))
                                  : BoxDecoration(
                                color: Singleton.thirdTabColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                  bottom: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CircularPercentIndicator(
                                      radius: 28.0,
                                      lineWidth: 8.0,
                                      animation: true,
                                      animationDuration: 1000,
                                      percent: voteAverage / 10,
                                      center: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            voteAverage.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (userRating != null &&
                                              userRating.ratedValue != 0.0)
                                            SizedBox(height: 2),
                                          if (userRating != null &&
                                              userRating.ratedValue != 0.0)
                                            Text(
                                              userRating.ratedValue
                                                  .toStringAsFixed(1),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                      circularStrokeCap:
                                      CircularStrokeCap.round,
                                      backgroundColor: Colors.transparent,
                                      progressColor: Singleton.getCircleColor(
                                        Singleton.parseDouble(voteAverage),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Marquee(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        fadingEdgeEndFraction: 0.9,
                                        fadingEdgeStartFraction: 0.1,
                                        blankSpace: 200,
                                        pauseAfterRound: Duration(seconds: 4),
                                        text: series['name'].toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          if (series['backdrop_path'] == null)
                            Center(
                              child: Icon(
                                Icons.photo,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // Handle error or no data scenario
                return Container();
              }
            },
          ),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xff540126),
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
        body:  Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.0, 0.4), // Start at the middle left
                end: Alignment(0.0, 0.1), // End a little above the middle
                colors: [
                  Singleton.thirdTabColor.withOpacity(0.8),
                  Colors.black
                ],
              ),
            ),
            child:  dataLoaded ? ListView(physics: BouncingScrollPhysics(), children: [
              sliderMovies.length + sliderSeries.length >= 1
                  ? SizedBox(
                      height: 10,
                    )
                  : Container(),
              Container(
                child: Column(
                  children: [
                    sliderMovies.length + sliderSeries.length >= 1
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "${translate('Empfehlung von')} ${randUser.username}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width * 0.05, // Adjust the multiplier as needed
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 8),
                        CircleAvatar(
                          backgroundImage: NetworkImage(randUser.imagePath),
                          radius: 20,
                        ),
                        SizedBox(height: 10),
                      ],
                    )
                        : Container(),
                    sliderMovies.length >= 1
                        ? Column(children: [
                            Container(
                              height: 250,
                              width: double.infinity,
                              child: CarouselSlider(
                                options: CarouselOptions(
                                    autoPlayInterval: Duration(seconds: 8),
                                    autoPlayAnimationDuration:
                                        Duration(milliseconds: 1500),
                                    autoPlay: true,
                                    aspectRatio: 1.0,
                                    enableInfiniteScroll: true,
                                    // Add this line
                                    enlargeCenterPage: true,
                                    // Add this line
                                    viewportFraction: 0.6,
                                    enlargeFactor: 0.4),
                                items: sliderMovies,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                          ])
                        : Container(),
                    sliderSeries.length >= 1
                        ? Column(children: [
                            Container(
                              height: 170,
                              width: double.infinity,
                              child: CarouselSlider(
                                options: CarouselOptions(
                                    autoPlayInterval: Duration(seconds: 6),
                                    autoPlayAnimationDuration:
                                        Duration(milliseconds: 1500),
                                    autoPlay: true,
                                    aspectRatio: 1.0,
                                    enableInfiniteScroll: true,
                                    // Add this line
                                    enlargeCenterPage: true,
                                    // Add this line
                                    viewportFraction: 0.7,
                                    enlargeFactor: 0.4),
                                items: sliderSeries,
                              ),
                            ),
                          ])
                        : Container(),
                  ],
                ),
              ),
              SizedBox(height: 10,),
              _bannerAd != null
                  ? Container(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    )
                  : Container(),
              GamesScreen(
                games: trendingGames,
                title: translate('Trending Games'),
                buttonColor: Color(0xff540126),
                typeOfApiCall: 0,
              ),
              GamesScreen(
                games: topRatedMetacriticsGames,
                title: translate('Top Rated Metacritc Games'),
                buttonColor: Color(0xff540126),
                typeOfApiCall: 1,
              ),
              GamesScreen(
                games: topRatedGames,
                title: translate('Top Rated Games'),
                buttonColor: Color(0xff540126),
                typeOfApiCall: 2,
              ),

              SizedBox(height: 80),
            ]): Singleton.ShimmerEffectMainScreen(context, Singleton.thirdTabColor)));
  }
}
