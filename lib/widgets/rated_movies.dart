import 'package:game_grove/screens/all_rated_movies.dart';
import 'package:game_grove/utils/text.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:marquee/marquee.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

import '../Database/userAccountState.dart';
import '../movieDetail.dart';

class RatedMovies extends StatelessWidget {
  final List ratedMovies;
  final List allRatedMovies;
  final Color buttonColor;
  final int? accountID;
  final String? sessionID;
  final bool myRated;

  const RatedMovies(
      {Key? key,
      required this.ratedMovies,
      required this.allRatedMovies,
      required this.buttonColor,
      this.accountID,
      this.sessionID,
      required this.myRated})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 mod_Text(
                    text: translate('Bewertete Filme'),
                    color: Colors.white, size: 22),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.to(
                        () => AllRatedMovieScreen(
                              ratedMovies: allRatedMovies,
                              appBarColor: buttonColor,
                              accountID: accountID,
                              sessionID: sessionID,
                              myRating: myRated,
                            ),
                        transition: Transition.downToUp,
                        duration: Duration(milliseconds: 700));
                  },
                  style: ElevatedButton.styleFrom(
                    primary: buttonColor, // Set custom background color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Set custom corner radius
                    ),
                  ),
                  child: Text(translate('Alle')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 250, // Fixed height for the ListView
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: ratedMovies.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                Map<String, dynamic> movie = ratedMovies[index];
                double voteAverage = myRated
                    ? double.parse(movie['vote_average'].toString())
                    : double.parse(movie['rating'].toString());
                int movieId = movie['id'];
                String? posterPath = movie['poster_path'];
                String originalTitle = movie['title'] ?? '';

                return FutureBuilder<UserAccountState>(
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
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: InkWell(
                          onLongPress: () {
                            if(!Singleton.isGuest) {
                              Singleton.showRatingDialogMovie(
                                  context, userRating!);
                            }

                          },
                          onTap: () {
                            Get.to(
                                () => DescriptionMovies(
                                      movieID: movieId,
                                      isMovie: true,
                                    ),
                                transition: Transition.zoom,
                                duration: Duration(milliseconds: 500));
                          },
                          child: SizedBox(
                            width: 160,
                            child: Stack(
                              children: [
                                Container(
                                  height: 250,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    image: posterPath != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              'https://image.tmdb.org/t/p/w500' +
                                                  posterPath,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: posterPath != null
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
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
                                                      voteAverage
                                                          .toStringAsFixed(1),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (userRating != null &&
                                                        userRating.ratedValue !=
                                                            0.0)
                                                      SizedBox(height: 2),
                                                    if (userRating != null &&
                                                        userRating.ratedValue !=
                                                            0.0)
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
                                                backgroundColor:
                                                    Colors.transparent,
                                                progressColor:
                                                    Singleton.getCircleColor(
                                                  Singleton.parseDouble(
                                                      voteAverage),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Marquee(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  fadingEdgeEndFraction: 0.9,
                                                  fadingEdgeStartFraction: 0.1,
                                                  blankSpace: 100,
                                                  pauseAfterRound:
                                                      Duration(seconds: 4),
                                                  text: originalTitle,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.photo,
                                            color: Colors.white,
                                            size: 50,
                                          ),
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
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
