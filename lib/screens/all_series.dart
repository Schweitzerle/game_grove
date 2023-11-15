import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';

import '../api/rawg_api.dart';
import '../widgets/singleton.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:http/http.dart' as http;


class AllSeriesScreen extends StatefulWidget {
  final String title;
  final Color appBarColor;
  final int? seriesID;
  final int? accountID;
  final String? sessionID;
  final int typeOfApiCall;
  final int? peopleID;

  AllSeriesScreen({
    Key? key,
    required this.title,
    required this.appBarColor,
    this.seriesID,
    this.accountID,
    this.sessionID,
    this.peopleID,
    required this.typeOfApiCall,
  }) : super(key: key);

  /*
  0:trending
  1:topmeta
  2:top
   */

  @override
  _AllSeriesState createState() => _AllSeriesState();
}

class _AllSeriesState extends State<AllSeriesScreen> {
  int currentPage = 1;
  bool isLoadingMore = false;
  List<dynamic> allSeries = [];
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
        final url = Uri.parse(
            'https://api.rawg.io/api/games?key=${RawgApiService.apiKey}&page=$page');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
            watchlistResults = data;
        } else {
          throw Exception('Failed to fetch data');
        }
        break;
      case 1:
        final url = Uri.parse(
            'https://api.rawg.io/api/games?key=${RawgApiService.apiKey}&ordering=-metacritic&page=$page');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
            watchlistResults = data;
        } else {
          throw Exception('Failed to fetch data');
        };
        break;
      case 2:
        final url = Uri.parse(
            'https://api.rawg.io/api/games?key=${RawgApiService.apiKey}&ordering=-rating&page=$page');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
            watchlistResults = data;
        } else {
          throw Exception('Failed to fetch data');
        }
        break;
    }

    List<dynamic> watchlistSeries = watchlistResults['results'];

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
          Singleton.allTVItemsGridView(context, _pagingController, true, darkenSeenMovies),
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
