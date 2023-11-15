import 'package:game_grove/screens/all_list_items.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../widgets/singleton.dart';

class AllListsScreen extends StatefulWidget {
  final List movies;
  final String title;
  final Color appBarColor;
  final int? movieID;
  final int? accountID;
  final String? sessionID;

  AllListsScreen({
    Key? key,
    required this.movies,
    required this.title,
    required this.appBarColor,
    this.movieID,
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
  _AllListsState createState() => _AllListsState();
}

class _AllListsState extends State<AllListsScreen> {
  int currentPage = 1;
  bool isLoadingMore = false;
  List<dynamic> allLists = [];


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


  Future<void> _fetchMoviesPage(int page) async {
    try {
      final List<dynamic> lists = await _fetchMovies(page);

      final isLastPage = lists.isEmpty;

      if (isLastPage) {
        _pagingController.appendLastPage(lists.toList());
      } else {
        final nextPageKey = page + 1;
        _pagingController.appendPage(lists.toList(), nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<List<dynamic>> _fetchMovies(int page) async {
    Map<dynamic, dynamic> watchlistResults = {};

    watchlistResults = await Singleton.tmdbWithCustLogs.v3.movies.getLists(
      widget.movieID!,
      page: page,
    );

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
      ),
      body: Stack(
        children: [
          PagedGridView<int, dynamic>(
              physics: BouncingScrollPhysics(),
              pagingController: _pagingController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
              ),
              builderDelegate: PagedChildBuilderDelegate(
                itemBuilder: (context, movie, index) {
              final list = movie;
              double voteAverage =
                  double.parse(list['favorite_count'].toString());
              int movieId = list['id'];

              return FutureBuilder<double>(
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Singleton.buildShimmerPlaceholder();
                  } else {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => AllListsItemsScreen(
                                sessionID: widget.sessionID,
                                    title: widget.title,
                                    appBarColor: widget.appBarColor,
                                    listID: movieId,
                                  ),transition: Transition.downToUp, duration: Duration(milliseconds: 700)
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          list['poster_path'] != null ?
                                          Image.network(
                                            'https://image.tmdb.org/t/p/w300${list['poster_path']}',
                                            fit: BoxFit.scaleDown,
                                          ): Container(
                                            color: Colors.grey,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: 48,
                                              color: Colors.white,
                                            ),
                                            alignment: Alignment.center,
                                          ),
                                          Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Singleton
                                                    .getCircleColor(
                                                  Singleton.parseDouble(
                                                      voteAverage),
                                                ),
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      voteAverage
                                                          .toStringAsFixed(1),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    list['name'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }, future: null,
              );
            },
          ),
          ),
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
