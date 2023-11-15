import 'package:game_grove/seriesDetail.dart';
import 'package:game_grove/screens/all_rated_series.dart';
import 'package:game_grove/screens/all_movies.dart';
import 'package:game_grove/screens/all_series.dart';
import 'package:game_grove/utils/text.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:marquee/marquee.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tmdb_api/tmdb_api.dart';

import '../Database/userAccountState.dart';
import '../api/rawg_api.dart';
import '../movieDetail.dart';
import '../utils/SessionManager.dart';

class GamesScreen extends StatefulWidget {
  final List games;
  final String title;
  final Color buttonColor;
  final int? gameID;
  final int typeOfApiCall;
  final int? accountID;
  final String? sessionID;
  final int? peopleID;

  const GamesScreen({
    Key? key,
    required this.games,
    required this.title,
    required this.buttonColor,
    this.gameID,
    required this.typeOfApiCall,
    this.accountID,
    this.sessionID,
    this.peopleID,
  }) : super(key: key);

  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  @override
  void initState() {
    super.initState();
  }

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
                mod_Text(text: widget.title, color: Colors.white, size: 22),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.to(
                        () => AllSeriesScreen(
                              title: widget.title,
                              appBarColor: widget.buttonColor,
                              seriesID: widget.gameID,
                              typeOfApiCall: widget.typeOfApiCall,
                              sessionID: widget.sessionID,
                              accountID: widget.accountID,
                              peopleID: widget.peopleID,
                            ),
                        transition: Transition.downToUp,
                        duration: Duration(milliseconds: 700));
                  },
                  style: ElevatedButton.styleFrom(
                    primary: widget.buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(translate('Alle')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: widget.games.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                Map<String, dynamic> game = widget.games[index];
                double voteAverage =
                    double.parse(game['rating'].toString());
                      UserAccountState? userRating = UserAccountState(id: game['id'], favorite: false, watchlist: false, ratedValue: 1); //TODO: rating selber implementieren
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: InkWell(
                          onLongPress: () {
                            if(!Singleton.isGuest) {
                              Singleton.showRatingDialogTV(context, userRating!);
                            }
                          },
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DescriptionSeries(
                                  gameID: game['id'],
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
                                    decoration: game['background_image'] != null
                                        ? BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                    game['background_image'],
                                              ),
                                              fit: BoxFit.cover,
                                            ))
                                        : BoxDecoration(
                                            color: Singleton.thirdTabColor,
                                            borderRadius:
                                                BorderRadius.circular(20),
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
                                              blankSpace: 200,
                                              pauseAfterRound:
                                                  Duration(seconds: 4),
                                              text: game['name'].toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                if (game['background_image'] == null)
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
