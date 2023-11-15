import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:http/http.dart' as http;

import '../widgets/singleton.dart';

class AllMoviesScreen extends StatefulWidget {
  final String title;
  final Color appBarColor;
  final int? movieID;
  final int? accountID;
  final String? sessionID;
  final int typeOfApiCall;
  final int? peopleID;
  final int? keywordID;
  final int? collectionID;

  AllMoviesScreen({
    Key? key,
    required this.title,
    required this.appBarColor,
    this.movieID,
    this.accountID,
    this.sessionID,
    this.peopleID,
    required this.typeOfApiCall,
    this.keywordID,
    this.collectionID,
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
  _AllSimilarMoviesState createState() => _AllSimilarMoviesState();
}

class _AllSimilarMoviesState extends State<AllMoviesScreen> {
  int currentPage = 1;
  bool isLoadingMore = false;
  List<dynamic> allMovies = [];
  Map collectionDetails = {};
  bool darkenSeenMovies = false; // Initially show seen movies


  late final PagingController<int, dynamic> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchMoviesPage(pageKey);
    });
  }


  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }


  void _handleFilterChange(bool value) {
    setState(() {
      darkenSeenMovies = value;
    });
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
    Map<dynamic, dynamic> watchlistResults = {};

    switch (widget.typeOfApiCall) {
      case 0:
        watchlistResults = await Singleton.tmdbWithCustLogs.v3.movies.getSimilar(
          widget.movieID!,
          page: page,
        );
        break;
      case 1:
        watchlistResults = await Singleton.tmdbWithCustLogs.v3.movies.getRecommended(
          widget.movieID!,
          page: page,
        );
        break;
      case 2:
        watchlistResults = await Singleton.tmdbWithCustLogs.v3.trending.getTrending(mediaType: MediaType.movie, page: page);
        break;
      case 3:
        watchlistResults = await Singleton.tmdbWithCustLogs.v3.movies.getPopular(page: page);
        break;
      case 4:
        watchlistResults = await Singleton.tmdbWithCustLogs.v3.movies.getTopRated(page: page);
        break;
      case 5:
        watchlistResults = await Singleton.tmdbWithCustLogs.v3.movies.getUpcoming(page: page);
        break;
      case 6:
        watchlistResults = await Singleton.tmdbWithCustLogs.v3.movies.getNowPlaying(page: page);
        break;
      case 7:
        watchlistResults = await Singleton.tmdbWithCustLogs.v3.account.getMovieWatchList(
          widget.sessionID!,
          widget.accountID!,
          sortBy: SortBy.createdAtDes,
          page: page,
        );
        break;
      case 8:
        if (page == 1) {
          watchlistResults = await Singleton.tmdbWithCustLogs.v3.people.getMovieCredits(
            widget.peopleID!,
          );
        } else {
          return []; // Return an empty list for subsequent pages
        }
        break;
      case 9:
        watchlistResults = await Singleton.tmdbWithCustLogs.v3.account.getFavoriteMovies(
          widget.sessionID!,
          widget.accountID!,
          sortBy: SortBy.createdAtDes,
          page: page,
        );
        break;
      case 10:
        String def = Singleton.defaultLanguage;
        final response = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/keyword/${widget.keywordID}/movies?api_key=${Singleton.apiKey}&session_id=${widget.sessionID!}&page=$page&language=$def'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          watchlistResults = data;
        }
        break;
      case 11:
        if (page == 1) {
          watchlistResults = await Singleton.tmdbWithCustLogs.v3.collections.getDetails(
            widget.collectionID!,
          );
          setState(() {
            collectionDetails = watchlistResults;
          });
        } else {
          return []; // Return an empty list for subsequent pages
        }
        break;
    }

    List<dynamic> watchlistSeries = widget.typeOfApiCall == 8
        ? watchlistResults['cast']
        : widget.typeOfApiCall == 11
        ? watchlistResults['parts']
        : watchlistResults['results'];

    return watchlistSeries;
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
              )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (collectionDetails.isNotEmpty) ...[
            Stack(
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
                        collectionDetails['backdrop_path'].isNotEmpty
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
                            'https://image.tmdb.org/t/p/w500${collectionDetails['backdrop_path']}',
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
                Container(
                  padding: EdgeInsets.fromLTRB(16, 30, 0, 0),
                  // Adjust padding as needed
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collectionDetails['name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            height: 180,
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                'https://image.tmdb.org/t/p/w500${collectionDetails['poster_path']}',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 0),
                      // Adjust spacing between image and description
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 30, left: 10, right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Text(
                                collectionDetails['overview'],
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
          Singleton.allMovieItemsGridView(context, _pagingController, true, darkenSeenMovies),
          if (isLoadingMore)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(bottom: 16),
                child: CircularProgressIndicator(color: Singleton.firstTabColor),
              ),
            ),
        ],
      ),
    );
  }

}
