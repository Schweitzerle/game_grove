import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:marquee/marquee.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Database/userAccountState.dart';
import '../movieDetail.dart';
import '../seriesDetail.dart';
import '../utils/text.dart';
import '../widgets/singleton.dart';
import 'package:http/http.dart' as http;


class AllListsItemsScreen extends StatefulWidget {
  final String title;
  final Color appBarColor;
  final int listID;
  final int? accountID;
  final String? sessionID;

  AllListsItemsScreen({
    Key? key,
    required this.title,
    required this.appBarColor,
    required this.listID,
    this.accountID,
    required this.sessionID,
  }) : super(key: key);

  /*
  0:Similar
  1:Recommended
  2:Trending
  3:Popular
  4:TopRated
  5:Upcoming
  6:Now
  7:Watchlist
  8:PeopleContribution
   */

  @override
  _AllListItemsState createState() => _AllListItemsState();
}

class _AllListItemsState extends State<AllListsItemsScreen> {
  int currentPage = 1;
  bool isLoadingMore = false;
  List<dynamic> allLists = [];
  String name = '';
  String description = '';
  int favoriteCount = 0;
  String createdBy = '';
  int itemCount = 0;
  bool showSeenMovies = false; // Initially show seen movies
  String defaultLanguage = '';


  late final PagingController<int, dynamic> _pagingController;

  @override
  void initState() {
    super.initState();
    getDefaultLanguage();
    _pagingController = PagingController(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchMoviesPage(pageKey);
    });
  }

  Future<void> getDefaultLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultLanguage = prefs.getString('selectedLanguage')!;
    });
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
    int ID = widget.listID;
    String apiKey = Singleton.apiKey;
    String sessionId = widget.sessionID!;
    Map<dynamic, dynamic> watchlistResults = {};

      final url = Uri.parse('https://api.themoviedb.org/3/list/$ID?api_key=$apiKey&session_id=$sessionId&language=$defaultLanguage&page=$page');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        watchlistResults = data;
      }

      setState(() {
        name = watchlistResults['name'];
        description = watchlistResults['description'];
        createdBy = watchlistResults['created_by'];
        favoriteCount = watchlistResults['favorite_count'];
        itemCount = watchlistResults['item_count'];
      });
      List<dynamic> watchlistSeries = watchlistResults['items'];

      return watchlistSeries;

  }



  void _handleFilterChange(bool value) {
    setState(() {
      showSeenMovies = value;
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
          actions: [

            Padding(padding: EdgeInsets.all(4),child:

            LiteRollingSwitch(
              //initial value
              value: showSeenMovies,
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
            )
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.black.withOpacity(0.7),
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person, // Replace with your desired icon
                              color: Colors.white, // Customize the icon color
                              size: 32, // Adjust the size as needed
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${translate('Erstellt von:')} $createdBy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${translate('Favorisiert:')} $favoriteCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${translate('Filme')}: $itemCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimationLimiter(
                child: PagedGridView<int, dynamic>(
                  physics: BouncingScrollPhysics(),
                  pagingController: _pagingController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                  ),
                  // Inside the builderDelegate of PagedGridView
                  builderDelegate: PagedChildBuilderDelegate(
                    itemBuilder: (context, movie, index) {
                      double voteAverage =
                          double.parse(movie['vote_average'].toString());
                      int movieId = movie['id'];

                      // If the user rating is not in the cache, use FutureBuilder to fetch it
                      return FutureBuilder<UserAccountState>(
                        future: movie['media_type'] == 'movie'
                            ? Singleton.getUserRatingMovie(movieId)
                            : Singleton.getUserRatingTV(movieId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Singleton.buildShimmerPlaceholder();
                          } else {
                            // Cache the fetched user rating for future use
                            UserAccountState? userRating = snapshot.data;
                            return buildMovieWidget(
                                movie, index, voteAverage, userRating);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Widget buildMovieWidget(
    Map<String, dynamic> movie,
    int index,
    double voteAverage,
    UserAccountState? userRating,
  ) {
    String? imagePath;

    imagePath = movie['poster_path'];

    bool hasSeen = userRating != null && userRating.ratedValue != 0.0;

    ColorFilter? colorFilter;

    if (showSeenMovies && hasSeen) {
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
                    : DescriptionSeries(
                        gameID: movie['id'],
                        isMovie: false,
                      ),
                transition: Transition.zoom,
                duration: Duration(milliseconds: 500),
              );
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
}
