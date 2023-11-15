import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:tmdb_api/tmdb_api.dart';
import '../widgets/singleton.dart';

class AllRatedMovieScreen extends StatefulWidget {
  final List ratedMovies;
  final Color appBarColor;
  final int? accountID;
  final String? sessionID;
  final bool myRating;

  const AllRatedMovieScreen({
    Key? key,
    required this.ratedMovies,
    required this.appBarColor,
    this.accountID,
    this.sessionID,
    required this.myRating,
  });

  @override
  _AllRatedMoviesState createState() => _AllRatedMoviesState();
}

class _AllRatedMoviesState extends State<AllRatedMovieScreen> {
  late final PagingController<int, dynamic> _pagingController;
  bool showSeenMovies = false; // Initially show seen movies


  @override
  void initState() {
    super.initState();
    _pagingController = PagingController(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchMoviesPage(pageKey);
    });
  }

  void _handleFilterChange(bool value) {
    setState(() {
      showSeenMovies = value;
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
    final watchlistResults = await Singleton.tmdbWithCustLogs.v3.account.getRatedMovies(
      widget.sessionID!,
      widget.accountID!,
      sortBy: SortBy.createdAtDes,
      page: page,
    );

    final List<dynamic> watchlistSeries = watchlistResults['results'];
    return watchlistSeries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: widget.appBarColor,
        title: Text(
          'Alle bewerteten Filme',
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
          Singleton.allMovieItemsGridView(context, _pagingController, widget.myRating, showSeenMovies),
    ],
    ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
