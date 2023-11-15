import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:marquee/marquee.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

import '../Database/userAccountState.dart';
import '../movieDetail.dart';
import '../screens/all_movies.dart';
import '../utils/text.dart';
import '../widgets/singleton.dart';

class MoviesScreen extends StatefulWidget {
  final List movies;
  final List allMovies;
  final String title;
  final Color buttonColor;
  final int? movieID;
  final int typeOfApiCall;
  final int? accountID;
  final String? sessionID;
  final int? peopleID;

  const MoviesScreen({
    Key? key,
    required this.movies,
    required this.allMovies,
    required this.title,
    required this.buttonColor,
    this.movieID,
    required this.typeOfApiCall,
    this.accountID,
    this.sessionID,
    this.peopleID,
  }) : super(key: key);

  @override
  _MoviesScreenState createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
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
                          () => AllMoviesScreen(
                        title: widget.title,
                        appBarColor: widget.buttonColor,
                        movieID: widget.movieID,
                        typeOfApiCall: widget.typeOfApiCall,
                        sessionID: widget.sessionID,
                        accountID: widget.accountID,
                        peopleID: widget.peopleID,
                      ),
                      transition: Transition.downToUp,
                      duration: Duration(milliseconds: 700),
                    );
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
          Container(
            height: 250, // Fixed height for the ListView
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: widget.movies.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                Map<String, dynamic>? movie = widget.movies[index];
                double? voteAverage = double.parse(movie!['vote_average'].toString());
                int? movieId = movie['id'];
                String? posterPath = movie['poster_path'];
                String originalTitle = movie['title'] ?? '';
                // Generate a unique key for each item
                Key itemKey = Key(movieId.toString());
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
                        key: itemKey, // Use the generated key for the item
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onLongPress: () {
                            if(!Singleton.isGuest) {
                              Singleton.showRatingDialogMovie(context, userRating!);
                            }
                          },
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DescriptionMovies(
                                  movieID: movieId,
                                  isMovie: true,
                                ),
                              ),
                            );
                          },
                          child: InkWell(
                            child: SizedBox(
                              width: 160,
                              child: Stack(
                                children: [
                                  Container(
                                    height: 250,
                                    decoration: posterPath != null
                                        ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          'https://image.tmdb.org/t/p/w500' +
                                              posterPath,
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : BoxDecoration(
                                      color: Singleton.thirdTabColor,
                                      borderRadius: BorderRadius.circular(20),
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
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          CircularPercentIndicator(
                                            radius: 28.0,
                                            lineWidth: 8.0,
                                            animation: true,
                                            animationDuration: 1000,
                                            percent: voteAverage / 10,
                                            center: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  voteAverage.toStringAsFixed(1),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (userRating != null && userRating.ratedValue != 0.0)
                                                  SizedBox(height: 2),
                                                if (userRating != null && userRating.ratedValue != 0.0)
                                                  Text(
                                                    userRating.ratedValue.toStringAsFixed(1),
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
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              fadingEdgeEndFraction: 0.9,
                                              fadingEdgeStartFraction: 0.1,
                                              blankSpace: 200,
                                              pauseAfterRound: Duration(seconds: 4),
                                              text: originalTitle,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (posterPath == null)
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
