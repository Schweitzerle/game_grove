import 'package:game_grove/seasonDetail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:marquee/marquee.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

import '../Database/user.dart';
import '../Database/userAccountState.dart';
import '../movieDetail.dart';
import '../screens/all_movies.dart';
import '../utils/text.dart';
import '../widgets/singleton.dart';

class TVSeasons extends StatefulWidget {
  final List seasons;
  final String title;
  final int? seriesID;
  final int? accountID;
  final String? sessionID;
  final double voteAverage;
  final String bannerUrl;
  final bool inProduction;
  final int revenue;
  final String status;
  final String tagline;
  final String type;
  final List recommendedSeries;
  final List similarSeries;
  final List genres;
  final List keywords;
  final String sessionId;
  final int accountId;
  final List reviews;
  final Map<AppUser, double> users;

  const TVSeasons({
    Key? key,
    required this.seasons,
    required this.title,
    required this.seriesID,
    required this.accountID,
    required this.sessionID, required this.voteAverage, required this.bannerUrl, required this.inProduction, required this.revenue, required this.status, required this.tagline, required this.type, required this.recommendedSeries, required this.similarSeries, required this.genres, required this.keywords, required this.sessionId, required this.accountId, required this.reviews, required this.users,
  }) : super(key: key);

  @override
  _TVSeasonsState createState() => _TVSeasonsState();
}

class _TVSeasonsState extends State<TVSeasons> {
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 250, // Fixed height for the ListView
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: widget.seasons.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                Map<String, dynamic>? season = widget.seasons[index];
                int? movieId = season!['id'];
                String? posterPath = season['poster_path'] ?? '';
                String originalTitle = season['name'] ?? '';
                int seasonNumber = season['season_number'] ?? 0;
                // Generate a unique key for each item
                Key itemKey = Key(movieId.toString());
               return Padding(
                        key: itemKey, // Use the generated key for the item
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DescriptionSeason(seriesID: widget.seriesID!, voteAverage: widget.voteAverage, inProduction: widget.inProduction, revenue: widget.revenue, status: widget.status, tagline: widget.tagline, type: widget.type, recommendedSeries: widget.recommendedSeries, similarSeries: widget.similarSeries, genres: widget.genres, keywords: widget.keywords, sessionId: widget.sessionId, accountId: widget.accountId, reviews: widget.reviews, users: widget.users, seasonNumber: seasonNumber, seriesBannerUrl: widget.bannerUrl,)
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
                                          Container(

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
                    }
            ),
          )
        ],
      ),
    );
  }
}

