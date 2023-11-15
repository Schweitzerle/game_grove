import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:countup/countup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';

import '../Database/user.dart';
import '../widgets/singleton.dart';
import '../widgets/rated_movies.dart';
import '../widgets/rated_series.dart';
import '../widgets/series.dart';

import '../widgets/movies.dart';

class FriendScreen extends StatefulWidget {
  final int accountID;
  final String sessionID;
  final Color appBarColor;
  final String title;
  final AppUser user;

  FriendScreen({
    Key? key,
    required this.accountID,
    required this.sessionID,
    required this.appBarColor,
    required this.title,
    required this.user,
  }) : super(key: key);

  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> recommendedMovies = [];
  List<dynamic> recommendedSeries = [];
  List<dynamic> ratedMovies = [];
  List<dynamic> ratedSeries = [];
  double recommendedMoviesLength = 0;
  double recommendedSeriesLength = 0;
  double seenMoviesLength = 0;
  double seenSeriesLength = 0;

  final String apiKey = '24b3f99aa424f62e2dd5452b83ad2e43';
  final readAccToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyNGIzZjk5YWE0MjRmNjJlMmRkNTQ1MmI4M2FkMmU0MyIsInN1YiI6IjYzNjI3NmU5YTZhNGMxMDA4MmRhN2JiOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.fiB3ZZLqxCWYrIvehaJyw6c4LzzOFwlqoLh8Dw77SUw';
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    loadMovies();
    super.initState();
  }

  loadMovies() async {
    int reccMovieTotalPages = 1;
    int reccSeriesTotalPages = 1;
    int ratedMoviesTotalPages = 1;
    int ratedSeriesTotalPages = 1;

    int reccMovieTotalItems = 0;
    int reccSeriesTotalItems = 0;
    int ratedMoviesTotalItems = 0;
    int ratedSeriesTotalItems = 0;

    // Fetch the total number of pages for each API call
    Map<dynamic, dynamic> reccMovieInfo =
        await Singleton.tmdbWithCustLogs.v3.account.getFavoriteMovies(
      widget.sessionID,
      widget.accountID,
      page: 1,
    );
    if (reccMovieInfo.containsKey('total_pages')) {
      reccMovieTotalPages = reccMovieInfo['total_pages'];
    }
    if (reccMovieInfo.containsKey('total_results')) {
      reccMovieTotalItems = reccMovieInfo['total_results'];
    }

    Map<dynamic, dynamic> reccSeriesInfo =
        await Singleton.tmdbWithCustLogs.v3.account.getFavoriteTvShows(
      widget.sessionID,
      widget.accountID,
      page: 1,
    );
    if (reccSeriesInfo.containsKey('total_pages')) {
      reccSeriesTotalPages = reccSeriesInfo['total_pages'];
    }
    if (reccSeriesInfo.containsKey('total_results')) {
      reccSeriesTotalItems = reccSeriesInfo['total_results'];
    }

    Map<dynamic, dynamic> ratedMoviesInfo =
        await Singleton.tmdbWithCustLogs.v3.account.getRatedMovies(
      widget.sessionID,
      widget.accountID,
      page: 1,
    );
    if (ratedMoviesInfo.containsKey('total_pages')) {
      ratedMoviesTotalPages = ratedMoviesInfo['total_pages'];
    }
    if (ratedMoviesInfo.containsKey('total_results')) {
      ratedMoviesTotalItems = ratedMoviesInfo['total_results'];
    }

    Map<dynamic, dynamic> ratedSeriesInfo =
        await Singleton.tmdbWithCustLogs.v3.account.getRatedTvShows(
      widget.sessionID,
      widget.accountID,
      page: 1,
    );
    if (ratedSeriesInfo.containsKey('total_pages')) {
      ratedSeriesTotalPages = ratedSeriesInfo['total_pages'];
    }
    if (ratedSeriesInfo.containsKey('total_results')) {
      ratedSeriesTotalItems = ratedSeriesInfo['total_results'];
    }

    // Fetch the last two pages for each API call
    List<Map<dynamic, dynamic>> reccMoviePages = [];
    List<Map<dynamic, dynamic>> reccSeriesPages = [];
    List<Map<dynamic, dynamic>> ratedMoviesPages = [];
    List<Map<dynamic, dynamic>> ratedSeriesPages = [];

    if (reccMovieTotalPages >= 1) {
      int lastPage = reccMovieTotalPages;
      if (lastPage > 0 && lastPage <= 1000) {
        Map<dynamic, dynamic> reccMovieResultsLast =
            await Singleton.tmdbWithCustLogs.v3.account.getFavoriteMovies(
          widget.sessionID,
          widget.accountID,
          page: lastPage,
        );
        reccMoviePages.add(reccMovieResultsLast);
      }
      int secondLastPage = reccMovieTotalPages - 1;
      if (secondLastPage > 0 && secondLastPage <= 1000) {
        Map<dynamic, dynamic> reccMovieResultsSecondLast =
            await Singleton.tmdbWithCustLogs.v3.account.getFavoriteMovies(
          widget.sessionID,
          widget.accountID,
          page: secondLastPage,
        );
        reccMoviePages.add(reccMovieResultsSecondLast);
      }
    }

    if (reccSeriesTotalPages >= 1) {
      int lastPage = reccSeriesTotalPages;
      if (lastPage > 0 && lastPage <= 1000) {
        Map<dynamic, dynamic> reccSeriesResultsLast =
            await Singleton.tmdbWithCustLogs.v3.account.getFavoriteTvShows(
          widget.sessionID,
          widget.accountID,
          page: lastPage,
        );
        reccSeriesPages.add(reccSeriesResultsLast);
      }
      int secondLastPage = reccSeriesTotalPages - 1;
      if (secondLastPage > 0 && secondLastPage <= 1000) {
        Map<dynamic, dynamic> reccSeriesResultsSecondLast =
            await Singleton.tmdbWithCustLogs.v3.account.getFavoriteTvShows(
          widget.sessionID,
          widget.accountID,
          page: secondLastPage,
        );
        reccSeriesPages.add(reccSeriesResultsSecondLast);
      }
    }

    if (ratedMoviesTotalPages >= 1) {
      int lastPage = ratedMoviesTotalPages;
      if (lastPage > 0 && lastPage <= 1000) {
        Map<dynamic, dynamic> ratedMoviesResultsLast =
            await Singleton.tmdbWithCustLogs.v3.account.getRatedMovies(
          widget.sessionID,
          widget.accountID,
          page: lastPage,
        );
        ratedMoviesPages.add(ratedMoviesResultsLast);
      }
      int secondLastPage = ratedMoviesTotalPages - 1;
      if (secondLastPage > 0 && secondLastPage <= 1000) {
        Map<dynamic, dynamic> ratedMoviesResultsSecondLast =
            await Singleton.tmdbWithCustLogs.v3.account.getRatedMovies(
          widget.sessionID,
          widget.accountID,
          page: secondLastPage,
        );
        ratedMoviesPages.add(ratedMoviesResultsSecondLast);
      }
    }

    if (ratedSeriesTotalPages >= 1) {
      int lastPage = ratedSeriesTotalPages;
      if (lastPage > 0 && lastPage <= 1000) {
        Map<dynamic, dynamic> ratedSeriesResultsLast =
            await Singleton.tmdbWithCustLogs.v3.account.getRatedTvShows(
          widget.sessionID,
          widget.accountID,
          page: lastPage,
        );
        ratedSeriesPages.add(ratedSeriesResultsLast);
      }
      int secondLastPage = ratedSeriesTotalPages - 1;
      if (secondLastPage > 0 && secondLastPage <= 1000) {
        Map<dynamic, dynamic> ratedSeriesResultsSecondLast =
            await Singleton.tmdbWithCustLogs.v3.account.getRatedTvShows(
          widget.sessionID,
          widget.accountID,
          page: secondLastPage,
        );
        ratedSeriesPages.add(ratedSeriesResultsSecondLast);
      }
    }

    // Combine the results and reverse the items of each page
    List<dynamic> reversedRecommendedMovies = [];
    for (var i = 0; i < reccMoviePages.length; i++) {
      reversedRecommendedMovies.addAll(reccMoviePages[i]['results'].reversed);
    }

    List<dynamic> reversedRecommendedSeries = [];
    for (var i = 0; i < reccSeriesPages.length; i++) {
      reversedRecommendedSeries.addAll(reccSeriesPages[i]['results'].reversed);
    }

    List<dynamic> reversedRatedMovies = [];
    for (var i = 0; i < ratedMoviesPages.length; i++) {
      reversedRatedMovies.addAll(ratedMoviesPages[i]['results'].reversed);
    }

    List<dynamic> reversedRatedSeries = [];
    for (var i = 0; i < ratedSeriesPages.length; i++) {
      reversedRatedSeries.addAll(ratedSeriesPages[i]['results'].reversed);
    }

    setState(() {
      recommendedMoviesLength = reccMovieTotalItems.toDouble();
      recommendedSeriesLength = reccSeriesTotalItems.toDouble();
      seenMoviesLength = ratedMoviesTotalItems.toDouble();
      seenSeriesLength = ratedSeriesTotalItems.toDouble();

      recommendedMovies = reversedRecommendedMovies;
      recommendedSeries = reversedRecommendedSeries;
      ratedMovies = reversedRatedMovies;
      ratedSeries = reversedRatedSeries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: widget.appBarColor,
          title: Text(
            widget.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListView(
            physics: BouncingScrollPhysics(),
            children: [
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: NetworkImage(widget.user.imagePath),
                    ),
                    SizedBox(height: 10),
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          widget.user.name.isNotEmpty ? widget.user.name : 'Loading...',
                          speed: Duration(milliseconds: 150),
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      isRepeatingAnimation: false,
                    ),
                  ],
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    // Align content to the center
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        // Center the icon and text
                        children: [
                          Icon(
                            Icons.movie,
                            color: Singleton.firstTabColor,
                            size: 16,
                          ),
                          SizedBox(width: 20),
                          Row(
                            children: [
                              Text(
                                translate('Gesehen: '),
                                style: TextStyle(
                                  color: Singleton.firstTabColor,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Countup(
                                begin: 0,
                                end: seenMoviesLength.toDouble(),
                                //here you insert the number or its variable
                                duration: Duration(seconds: 3),
                                separator: '.',
                                //this is the character you want to add to seperate between every 3 digits
                                style: TextStyle(
                                  color: Singleton.firstTabColor.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        // Center the icon and text
                        children: [
                          Icon(
                            Icons.thumb_up,
                            color: Singleton.secondTabColor,
                            size: 16,
                          ),
                          SizedBox(width: 20),
                          Row(
                            children: [
                              Text(
                                translate('Empfohlen: '),
                                style: TextStyle(
                                  color: Singleton.secondTabColor,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Countup(
                                begin: 0,
                                end: recommendedMoviesLength.toDouble(),
                                //here you insert the number or its variable
                                duration: Duration(seconds: 3),
                                separator: '.',
                                //this is the character you want to add to seperate between every 3 digits
                                style: TextStyle(
                                  color: Singleton.secondTabColor.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        // Center the icon and text
                        children: [
                          Icon(
                            Icons.tv,
                            color: Singleton.secondTabColor,
                            size: 16,
                          ),
                          SizedBox(width: 20),
                          Row(
                            children: [
                              Text(
                                translate('Gesehen: '),
                                style: TextStyle(
                                  color: Singleton.secondTabColor,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Countup(
                                begin: 0,
                                end: seenSeriesLength.toDouble(),
                                //here you insert the number or its variable
                                duration: Duration(seconds: 3),
                                separator: '.',
                                //this is the character you want to add to seperate between every 3 digits
                                style: TextStyle(
                                  color: Singleton.secondTabColor.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        // Center the icon and text
                        children: [
                          Icon(
                            Icons.thumb_up,
                            color: Singleton.firstTabColor,
                            size: 16,
                          ),
                          SizedBox(width: 20),
                          Row(
                            children: [
                              Text(
                                translate('Empfohlen: '),
                                style: TextStyle(
                                  color: Singleton.firstTabColor,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Countup(
                                begin: 0,
                                end: recommendedSeriesLength.toDouble(),
                                //here you insert the number or its variable
                                duration: Duration(seconds: 3),
                                separator: '.',
                                //this is the character you want to add to seperate between every 3 digits
                                style: TextStyle(
                                  color: Singleton.firstTabColor.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          recommendedMovies.isNotEmpty
              ? MoviesScreen(
                  movies: recommendedMovies.length < 10
                      ? recommendedMovies
                      : recommendedMovies.sublist(0, 10),
                  allMovies: recommendedMovies,
                  title: translate('Empfohlene Filme'),
                  buttonColor: Color(0xff690257),
                  typeOfApiCall: 9,
                  accountID: widget.accountID,
                  sessionID: widget.sessionID,
                )
              : Container(),
          recommendedSeries.isNotEmpty
              ? GamesScreen(
                  games: recommendedSeries.length < 10
                      ? recommendedSeries
                      : recommendedSeries.sublist(0, 10),
                  title: translate('Empfohlene Serien'),
                  buttonColor: Color(0xff690257),
                  typeOfApiCall: 9,
                  accountID: widget.accountID,
                  sessionID: widget.sessionID,
                )
              : Container(),
          ratedMovies.isNotEmpty
              ? RatedMovies(
                  ratedMovies: ratedMovies.length < 10
                      ? ratedMovies
                      : ratedMovies.sublist(0, 10),
                  allRatedMovies: ratedMovies,
                  buttonColor: Color(0xff690257),
                  accountID: widget.accountID,
                  sessionID: widget.sessionID,
                  myRated: false,
                )
              : Container(),
          ratedSeries.isNotEmpty
              ? RatedSeries(
                  ratedSeries: ratedSeries.length < 10
                      ? ratedSeries
                      : ratedSeries.sublist(0, 10),
                  allRatedSeries: ratedSeries,
                  buttonColor: Color(0xff690257),
                  accountID: widget.accountID,
                  sessionID: widget.sessionID,
                  myRated: false,
                )
              : Container(),
        ]));
  }
}
