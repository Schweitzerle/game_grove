import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:game_grove/peopleDetail.dart';
import 'package:game_grove/screens/filter_screen.dart';
import 'package:game_grove/seriesDetail.dart';
import 'package:game_grove/utils/AdMobService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:marquee/marquee.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Database/userAccountState.dart';
import '../movieDetail.dart';
import '../utils/text.dart';
import '../widgets/singleton.dart';

class FilmSearchScreen extends StatefulWidget {
  @override
  _FilmSearchScreenState createState() => _FilmSearchScreenState();
}

class _FilmSearchScreenState extends State<FilmSearchScreen> {
  List<dynamic> searchResults = [];
  bool isLoadingMore = false;
  String query = "";
  bool darkenSeenMovies = false; // Initially show seen movies

  // Cache for user ratings to avoid unnecessary rebuilds
  Map<int, UserAccountState> userRatingCache = {};

  late final PagingController<int, dynamic> _pagingController;

  TextEditingController _usernameController = TextEditingController();

  String defaultLanguage = '';

  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchMoviesPage(pageKey);
    });
    initAd();
  }

  void initAd() {
    InterstitialAd.load(
        adUnitId: AdMobService.interstitialAdUnitId!,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) => _interstitialAd = ad,
            onAdFailedToLoad: (LoadAdError error) => _interstitialAd = null));
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          initAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error){
          ad.dispose();
          initAd();
        }
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchMoviesPage(int page) async {
    try {
      final List<dynamic> movies = await _fetchMovies(page);

      final isLastPage = movies.isEmpty;

      if (isLastPage) {
        _pagingController.appendLastPage(movies.toList());
      } else {
        final nextPageKey = page + 1;
        _pagingController.appendPage(movies.toList(), nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<List<dynamic>> _fetchMovies(int page) async {
    final apiKey = '24b3f99aa424f62e2dd5452b83ad2e43'; //
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      defaultLanguage = prefs.getString('selectedLanguage')!;
    });
    final url = Uri.parse(
        'https://api.themoviedb.org/3/search/multi?api_key=$apiKey&query=$query&page=$page&language=$defaultLanguage&include_adult=false');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    List<dynamic> nextPageResults = data['results'];

    return nextPageResults;
  }

  void _handleFilterChange(bool value) {
    setState(() {
      darkenSeenMovies = value;
    });
  }

  Widget buildMovieWidget(
    Map<String, dynamic> movie,
    bool isPerson,
    int index,
    double voteAverage,
    UserAccountState? userRating,
  ) {
    String? imagePath;
    if (isPerson) {
      imagePath = movie['profile_path'];
    } else {
      imagePath = movie['poster_path'];
    }

    bool hasSeen = userRating != null && userRating.ratedValue != 0.0;

    ColorFilter? colorFilter;

    if (darkenSeenMovies && hasSeen) {
      colorFilter = ColorFilter.mode(
        Colors.black.withOpacity(0.9), // Change the opacity and color here
        BlendMode.darken, //// You can change the blend mode as needed
      );
    }

    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 375),
      columnCount: 2,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: GestureDetector(
            onLongPress: () {
              movie['media_type'] == 'movie'
                  ? Singleton.showRatingDialogMovie(context, userRating!)
                  : Singleton.showRatingDialogTV(context, userRating!);
              HapticFeedback.lightImpact();
            },
            onTap: () {
              Get.to(
                () => movie['media_type'] == 'movie'
                    ? DescriptionMovies(
                        movieID: movie['id'],
                        isMovie: true,
                      )
                    : movie['media_type'] == 'person'
                        ? DescriptionPeople(
                            peopleID: movie['id'],
                            isMovie: true,
                          )
                        : DescriptionSeries(
                            gameID: movie['id'],
                            isMovie: false,
                          ),
                transition: Transition.zoom,
                duration: Duration(milliseconds: 500),
              );
              _showInterstitialAd();

            },
            child: Container(
              margin: const EdgeInsets.all(10),
              child: SizedBox(
                width: 160,
                child: Stack(
                  children: [
                    Container(
                      height: 250,
                      decoration: imagePath != null
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                colorFilter: colorFilter,
                                image: NetworkImage(
                                  'https://image.tmdb.org/t/p/w500' + imagePath,
                                ),
                                fit: BoxFit.cover,
                              ))
                          : BoxDecoration(
                              color: Singleton.thirdTabColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                      child: movie['media_type'] != 'person'
                          ? Container(
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
                                      text: movie['title'] ?? movie['name'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              height: 250,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  movie['profile_path'] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                'https://image.tmdb.org/t/p/w500' +
                                                    movie['profile_path'],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: Colors.grey,
                                          ),
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                            color: Colors.white,
                                          ),
                                          alignment: Alignment.center,
                                        ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                        color: Colors.black.withOpacity(0.6),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: mod_Text(
                                              text: movie['name'] ?? 'Loading',
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          mod_Text(
                                            text: movie['character'] != null
                                                ? '(' + movie['character'] + ')'
                                                : movie['job'] != null
                                                    ? movie['job']
                                                    : '',
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(height: 4),
                                          mod_Text(
                                            text:
                                                movie['known_for_department'] !=
                                                        null
                                                    ? movie[
                                                        'known_for_department']
                                                    : 'Loading',
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (imagePath == null)
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double _w = MediaQuery.of(context).size.width;
    int columnCount = 2;
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(translate('Entdecken')),
          backgroundColor: Color(0xff480178),

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
          bottom: TabBar(
            tabs: [
              Tab(text: translate('Suchen')),
              Tab(text: translate('Filtern')),
            ],
            indicatorColor: Color(0xff480178),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.0, 0.4), // Start at the middle left
              end: Alignment(0.0, 0.1), // End a little above the middle
              colors: [Singleton.fourthTabColor.withOpacity(0.8), Colors.black],
            ),
          ),
          child: TabBarView(
            children: [
              Stack(
                children: [ Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              cursorColor: Colors.black,
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    query = value;
                                  });
                                  _pagingController.refresh();
                                }
                              },
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: translate('Suche'),
                                hintStyle: TextStyle(
                                    color: Colors.black45, fontSize: 12),
                                fillColor: Color(0xff480178),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    _usernameController.clear();
                                  },
                                  child: Icon(Icons.clear, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimationLimiter(
                        child: PagedGridView<int, dynamic>(
                          physics: BouncingScrollPhysics(),
                          pagingController: _pagingController,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                          ),
                          // Inside the builderDelegate of PagedGridView
                          builderDelegate: PagedChildBuilderDelegate(
                            itemBuilder: (context, movie, index) {
                              final bool isPerson =
                                  movie['media_type'] == 'person'
                                      ? true
                                      : false;
                              double voteAverage = isPerson
                                  ? 0.0
                                  : double.parse(
                                      movie['vote_average'].toString());
                              int movieId = movie['id'];

                              // Check if the user rating is already fetched and stored in the cache
                              final cachedRating = userRatingCache[movieId];

                              if (cachedRating != null) {
                                // If the user rating is in the cache, use it to build the widget
                                return buildMovieWidget(movie, isPerson, index,
                                    voteAverage, cachedRating);
                              } else {
                                // If the user rating is not in the cache, use FutureBuilder to fetch it
                                return FutureBuilder<UserAccountState>(
                                  future: movie['media_type'] == 'movie'
                                      ? Singleton.getUserRatingMovie(movieId)
                                      : Singleton.getUserRatingTV(movieId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Singleton
                                          .buildShimmerPlaceholder();
                                    } else {
                                      // Cache the fetched user rating for future use
                                      UserAccountState? userRating =
                                          snapshot.data;
                                      return buildMovieWidget(movie, isPerson,
                                          index, voteAverage, userRating);
                                    }
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                  Positioned(
                    bottom: 100.0, // Adjust the position as needed
                    right: 20.0, // Adjust the position as needed
                    child: LiteRollingSwitch(
                      //initial value
                      value: darkenSeenMovies,
                      width: 140,
                      textOn: translate('Unsichtbar'),
                      textOff: translate('Sichtbar'),
                      colorOn: Singleton.fifthTabColor,
                      colorOff: Singleton.firstTabColor,
                      iconOn: CupertinoIcons.eye_slash,
                      iconOff: CupertinoIcons.eye,
                      textOffColor: Colors.black,
                      textOnColor: Colors.white,
                      onChanged: _handleFilterChange
                      , onTap: (){

                    }, onDoubleTap: (){

                    }, onSwipe: (){

                    },
                    ),
                  ),
        ],
              ),
              Container(child: MovieFilterWidget()),
            ],
          ),
        ),
      ),
    );
  }
}
