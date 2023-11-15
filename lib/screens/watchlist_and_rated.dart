import 'package:game_grove/widgets/movies.dart';
import 'package:game_grove/utils/SessionManager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/AdMobService.dart';
import '../widgets/singleton.dart';
import '../widgets/rated_movies.dart';
import '../widgets/rated_series.dart';
import '../widgets/series.dart';

class WatchlistScreen extends StatefulWidget {
  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  List watchlistMovies = [];
  List watchlistSeries = [];
  List recommendedMovies = [];
  List recommendedSeries = [];
  List ratedMovies = [];
  List ratedSeries = [];
  final Future<String?> sessionID = SessionManager.getSessionId();
  final Future<int?> accountID = SessionManager.getAccountId();
  final String apiKey = '24b3f99aa424f62e2dd5452b83ad2e43';
  final readAccToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyNGIzZjk5YWE0MjRmNjJlMmRkNTQ1MmI4M2FkMmU0MyIsInN1YiI6IjYzNjI3NmU5YTZhNGMxMDA4MmRhN2JiOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.fiB3ZZLqxCWYrIvehaJyw6c4LzzOFwlqoLh8Dw77SUw';
  late TabController _tabController;
  int? accountId = 0;
  String? sessionId = '';
  BannerAd? _bannerAdWatchlist;
  BannerAd? _bannerAdRated;

  bool dataLoaded = false;


  @override
  void initState() {
    super.initState();
    loadAdWatchlist();
    loadAdRated();
    initialize();
  }

  Future<void> initialize() async {
    _tabController = TabController(length: 2, vsync: this);
    await loadMovies();
    setState(() {
      dataLoaded = true;
    });
  }

  void loadAdWatchlist() {
    _bannerAdWatchlist = BannerAd(
        size: AdSize.banner,
        adUnitId: AdMobService.bannerAdUnitId!,
        listener: AdMobService.bannerAdListener,
        request: const AdRequest())
      ..load();
  }

  void loadAdRated() {
    _bannerAdRated = BannerAd(
        size: AdSize.banner,
        adUnitId: AdMobService.bannerAdUnitId!,
        listener: AdMobService.bannerAdListener,
        request: const AdRequest())
      ..load();
  }

  Future<void> loadMovies() async {
    accountId = await accountID;
    sessionId = await sessionID;

    int watchlistSeriesTotalPages = 1;
    int watchlistMoviesTotalPages = 1;
    int ratedMoviesTotalPages = 1;
    int ratedSeriesTotalPages = 1;

    int reccMovieTotalPages = 1;
    int reccSeriesTotalPages = 1;


    // Fetch the total number of pages for each API call
    if (accountId! >= 1) {
      Map<dynamic, dynamic> reccMovieInfo =
      await Singleton.tmdbWithCustLogs.v3.account.getFavoriteMovies(
        sessionId!,
        accountId!,
        page: 1,
      );
      if (reccMovieInfo.containsKey('total_pages')) {
        reccMovieTotalPages = reccMovieInfo['total_pages'];
      }

      Map<dynamic, dynamic> reccSeriesInfo =
      await Singleton.tmdbWithCustLogs.v3.account.getFavoriteTvShows(
        sessionId!,
        accountId!,
        page: 1,
      );
      if (reccSeriesInfo.containsKey('total_pages')) {
        reccSeriesTotalPages = reccSeriesInfo['total_pages'];
      }


      // Fetch the total number of pages for each API call
      Map<dynamic, dynamic> watchlistSeriesInfo =
      await Singleton.tmdbWithCustLogs.v3.account.getTvShowWatchList(
        sessionId!,
        accountId!,
        page: 1,
      );
      watchlistSeriesTotalPages = watchlistSeriesInfo['total_pages'];

      Map<dynamic, dynamic> watchlistMoviesInfo =
      await Singleton.tmdbWithCustLogs.v3.account.getMovieWatchList(
        sessionId!,
        accountId!,
        page: 1,
      );
      watchlistMoviesTotalPages = watchlistMoviesInfo['total_pages'];

      Map<dynamic, dynamic> ratedMoviesInfo =
      await Singleton.tmdbWithCustLogs.v3.account.getRatedMovies(
        sessionId!,
        accountId!,
        page: 1,
      );
      ratedMoviesTotalPages = ratedMoviesInfo['total_pages'];

      Map<dynamic, dynamic> ratedSeriesInfo =
      await Singleton.tmdbWithCustLogs.v3.account.getRatedTvShows(
        sessionId!,
        accountId!,
        page: 1,
      );
      ratedSeriesTotalPages = ratedSeriesInfo['total_pages'];

      // Fetch the last two pages for each API call
      List<Map<dynamic, dynamic>> watchlistSeriesPages = [];
      List<Map<dynamic, dynamic>> watchlistMoviesPages = [];
      List<Map<dynamic, dynamic>> ratedMoviesPages = [];
      List<Map<dynamic, dynamic>> ratedSeriesPages = [];
      List<Map<dynamic, dynamic>> reccMoviePages = [];
      List<Map<dynamic, dynamic>> reccSeriesPages = [];

      if (reccMovieTotalPages >= 1) {
        int lastPage = reccMovieTotalPages;
        if (lastPage > 0 && lastPage <= 1000) {
          Map<dynamic, dynamic> reccMovieResultsLast =
          await Singleton.tmdbWithCustLogs.v3.account.getFavoriteMovies(
            sessionId!,
            accountId!,
            page: lastPage,
          );
          reccMoviePages.add(reccMovieResultsLast);
        }
        int secondLastPage = reccMovieTotalPages - 1;
        if (secondLastPage > 0 && secondLastPage <= 1000) {
          Map<dynamic, dynamic> reccMovieResultsSecondLast =
          await Singleton.tmdbWithCustLogs.v3.account.getFavoriteMovies(
            sessionId!,
            accountId!,
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
            sessionId!,
            accountId!,
            page: lastPage,
          );
          reccSeriesPages.add(reccSeriesResultsLast);
        }
        int secondLastPage = reccSeriesTotalPages - 1;
        if (secondLastPage > 0 && secondLastPage <= 1000) {
          Map<dynamic, dynamic> reccSeriesResultsSecondLast =
          await Singleton.tmdbWithCustLogs.v3.account.getFavoriteTvShows(
            sessionId!,
            accountId!,
            page: secondLastPage,
          );
          reccSeriesPages.add(reccSeriesResultsSecondLast);
        }
      }

      if (watchlistSeriesTotalPages >= 1) {
        int lastPage = watchlistSeriesTotalPages;
        if (lastPage > 0 && lastPage <= 1000) {
          Map<dynamic, dynamic> watchlistSeriesResultsLast =
          await Singleton.tmdbWithCustLogs.v3.account.getTvShowWatchList(
            sessionId!,
            accountId!,
            page: lastPage,
          );
          watchlistSeriesPages.add(watchlistSeriesResultsLast);
        }
        int secondLastPage = watchlistSeriesTotalPages - 1;
        if (secondLastPage > 0 && secondLastPage <= 1000) {
          Map<dynamic, dynamic> watchlistSeriesResultsSecondLast =
          await Singleton.tmdbWithCustLogs.v3.account.getTvShowWatchList(
            sessionId!,
            accountId!,
            page: secondLastPage,
          );
          watchlistSeriesPages.add(watchlistSeriesResultsSecondLast);
        }
      }

      if (watchlistMoviesTotalPages >= 1) {
        int lastPage = watchlistMoviesTotalPages;
        if (lastPage > 0 && lastPage <= 1000) {
          Map<dynamic, dynamic> watchlistMoviesResultsLast =
          await Singleton.tmdbWithCustLogs.v3.account.getMovieWatchList(
            sessionId!,
            accountId!,
            page: lastPage,
          );
          watchlistMoviesPages.add(watchlistMoviesResultsLast);
        }
        int secondLastPage = watchlistMoviesTotalPages - 1;
        if (secondLastPage > 0 && secondLastPage <= 1000) {
          Map<dynamic, dynamic> watchlistMoviesResultsSecondLast =
          await Singleton.tmdbWithCustLogs.v3.account.getMovieWatchList(
            sessionId!,
            accountId!,
            page: secondLastPage,
          );
          watchlistMoviesPages.add(watchlistMoviesResultsSecondLast);
        }
      }

      if (ratedSeriesTotalPages >= 1) {
        int lastPage = ratedSeriesTotalPages;
        if (lastPage > 0 && lastPage <= 1000) {
          Map<dynamic, dynamic> ratedSeriesResultsLast =
          await Singleton.tmdbWithCustLogs.v3.account.getRatedTvShows(
            sessionId!,
            accountId!,
            page: lastPage,
          );
          ratedSeriesPages.add(ratedSeriesResultsLast);
        }
        int secondLastPage = ratedSeriesTotalPages - 1;
        if (secondLastPage > 0 && secondLastPage <= 1000) {
          Map<dynamic, dynamic> ratedSeriesResultsSecondLast =
          await Singleton.tmdbWithCustLogs.v3.account.getRatedTvShows(
            sessionId!,
            accountId!,
            page: secondLastPage,
          );
          ratedSeriesPages.add(ratedSeriesResultsSecondLast);
        }
      }

      if (ratedMoviesTotalPages >= 1) {
        int lastPage = ratedMoviesTotalPages;
        if (lastPage > 0 && lastPage <= 1000) {
          Map<dynamic, dynamic> ratedMoviesResultsLast =
          await Singleton.tmdbWithCustLogs.v3.account.getRatedMovies(
            sessionId!,
            accountId!,
            page: lastPage,
          );
          ratedMoviesPages.add(ratedMoviesResultsLast);
        }
        int secondLastPage = ratedMoviesTotalPages - 1;
        if (secondLastPage > 0 && secondLastPage <= 1000) {
          Map<dynamic, dynamic> ratedMoviesResultsSecondLast =
          await Singleton.tmdbWithCustLogs.v3.account.getRatedMovies(
            sessionId!,
            accountId!,
            page: secondLastPage,
          );
          ratedMoviesPages.add(ratedMoviesResultsSecondLast);
        }
      }


      // Combine the results and reverse the items of each page
      List<dynamic> reversedRecommendedMovies = [];
      for (var i = 0; i < reccMoviePages.length; i++) {
        reversedRecommendedMovies.addAll(reccMoviePages[i]['results'].reversed);
      }

      List<dynamic> reversedRecommendedSeries = [];
      for (var i = 0; i < reccSeriesPages.length; i++) {
        reversedRecommendedSeries.addAll(
            reccSeriesPages[i]['results'].reversed);
      }

      // Combine the results and reverse the items of each page
      List<dynamic> reversedWatchlistMovies = [];
      for (var i = 0; i < watchlistMoviesPages.length; i++) {
        reversedWatchlistMovies
            .addAll(watchlistMoviesPages[i]['results'].reversed);
      }

      List<dynamic> reversedWatchlistSeries = [];
      for (var i = 0; i < watchlistSeriesPages.length; i++) {
        reversedWatchlistSeries
            .addAll(watchlistSeriesPages[i]['results'].reversed);
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
        watchlistMovies = reversedWatchlistMovies;
        watchlistSeries = reversedWatchlistSeries;
        ratedMovies = reversedRatedMovies;
        ratedSeries = reversedRatedSeries;

        recommendedMovies = reversedRecommendedMovies;
        recommendedSeries = reversedRecommendedSeries;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('CouchCinema'),
        backgroundColor: Color(0xffd6069b),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.0, 0.4), // Start at the middle left
            end: Alignment(0.0, 0.1), // End a little above the middle
            colors: [Singleton.firstTabColor.withOpacity(0.8), Colors.black],
          ),
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: translate('Watchlist')),
                Tab(text: translate('Rated')),
              ],
              indicatorColor: Color(0xffd6069b),
            ),
            Expanded(
              child: !Singleton.isGuest ? dataLoaded ? TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    physics: BouncingScrollPhysics(),
                    children: [
                      watchlistMovies.isNotEmpty
                          ? MoviesScreen(
                              movies: watchlistMovies.length < 10
                                  ? watchlistMovies
                                  : watchlistMovies.sublist(0, 10),
                              allMovies: watchlistMovies,
                              title: translate('Watchlist Filme'),
                              buttonColor: Color(0xffd6069b),
                              typeOfApiCall: 7,
                              accountID: accountId,
                              sessionID: sessionId,
                            )
                          : Container(),
                      watchlistSeries.isNotEmpty
                          ? GamesScreen(
                              games: watchlistSeries.length < 10
                                  ? watchlistSeries
                                  : watchlistSeries.sublist(0, 10),
                              title: translate('Watchlist Serien'),
                              buttonColor: Color(0xffd6069b),
                              typeOfApiCall: 7,
                              accountID: accountId,
                              sessionID: sessionId,
                            )
                          : Container(),
                      SizedBox(height: 10,),
                      _bannerAdWatchlist != null
                          ? Container(
                        width: _bannerAdWatchlist!.size.width.toDouble(),
                        height: _bannerAdWatchlist!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAdWatchlist!),
                      )
                          : Container(),
                    ],
                  ),
                  ListView(
                    physics: BouncingScrollPhysics(),
                    children: [
                      ratedMovies.isNotEmpty
                          ? RatedMovies(
                              ratedMovies: ratedMovies.length < 10
                                  ? ratedMovies
                                  : ratedMovies.sublist(0, 10),
                              allRatedMovies: ratedMovies,
                              buttonColor: Color(0xffd6069b),
                              accountID: accountId,
                              sessionID: sessionId,
                              myRated: true,
                            )
                          : Container(),
                      ratedSeries.isNotEmpty
                          ? RatedSeries(
                              ratedSeries: ratedSeries.length < 10
                                  ? ratedSeries
                                  : ratedSeries.sublist(0, 10),
                              allRatedSeries: ratedSeries,
                              buttonColor: Color(0xffd6069b),
                              accountID: accountId,
                              sessionID: sessionId,
                              myRated: true,
                            )
                          : Container(),
                      SizedBox(height: 10,),
                      _bannerAdRated != null
                          ? Container(
                        width: _bannerAdRated!.size.width.toDouble(),
                        height: _bannerAdRated!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAdRated!),
                      )
                          : Container(),
                      recommendedMovies.isNotEmpty
                          ? MoviesScreen(
                        movies: recommendedMovies.length < 10
                            ? recommendedMovies
                            : recommendedMovies.sublist(0, 10),
                        allMovies: recommendedMovies,
                        title: translate('Empfohlene Filme'),
                        buttonColor: Singleton.firstTabColor,
                        typeOfApiCall: 9,
                        accountID: accountId!,
                        sessionID: sessionId!,
                      )
                          : Container(),
                      recommendedSeries.isNotEmpty
                          ? GamesScreen(
                        games: recommendedSeries.length < 10
                            ? recommendedSeries
                            : recommendedSeries.sublist(0, 10),
                        title: translate('Empfohlene Serien'),
                        buttonColor: Singleton.firstTabColor,
                        typeOfApiCall: 9,
                        accountID: accountId!,
                        sessionID: sessionId!,
                      )
                          : Container(),
                      SizedBox(height: 80,)
                    ],
                  ),
                ],
              ) : Singleton.ShimmerEffectMainScreen(context, Singleton.firstTabColor) : Singleton.customWidget(translate('WatchlistReminder'), context),
            ),
          ],
        ),
      ),
    );
  }
}
