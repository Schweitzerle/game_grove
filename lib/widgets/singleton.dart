import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:countup/countup.dart';
import 'package:game_grove/seriesDetail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:marquee/marquee.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:transformable_list_view/transformable_list_view.dart';

import '../Database/user.dart';
import '../Database/userAccountState.dart';
import '../api/rawg_api.dart';
import '../main.dart';
import '../movieDetail.dart';
import '../utils/SessionManager.dart';
import 'package:http/http.dart' as http;

class Singleton extends StatelessWidget {
  const Singleton({Key? key}) : super(key: key);

  static String defaultLanguage = '';
  static String defaultCountryCode = '';
  static bool isGuest = false;

  static const String apiKey = '24b3f99aa424f62e2dd5452b83ad2e43';
  static const readAccToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyNGIzZjk5YWE0MjRmNjJlMmRkNTQ1MmI4M2FkMmU0MyIsInN1YiI6IjYzNjI3NmU5YTZhNGMxMDA4MmRhN2JiOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.fiB3ZZLqxCWYrIvehaJyw6c4LzzOFwlqoLh8Dw77SUw';
  static TMDB tmdbWithCustLogs = TMDB(
    ApiKeys(apiKey, readAccToken),
    defaultLanguage: defaultLanguage,
    logConfig: const ConfigLogger(showLogs: true, showErrorLogs: true),
  );

  static Future<void> initDefaultLanguageAndCountry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if language and country code are not set in SharedPreferences
    if (prefs.getString('selectedLanguage') == null) {
      // If not set, get system language and country code
      String systemLanguage = Platform.localeName.split('_')[0];
      String countryCode = Platform.localeName.split('_')[1];

      // Set default language and country code
      defaultCountryCode = countryCode;
      defaultLanguage = systemLanguage;

      // Save them to SharedPreferences
      await prefs.setString('selectedLanguage', systemLanguage);
      await prefs.setString('selectedCountry', countryCode);

      // Update the TMDB instance
      tmdbWithCustLogs = TMDB(
        ApiKeys(apiKey, readAccToken),
        defaultLanguage: defaultLanguage,
        logConfig: const ConfigLogger(showLogs: true, showErrorLogs: true),
      );
    } else {
      // If language and country code are already set, just retrieve them
      defaultLanguage = prefs.getString('selectedLanguage')!;
      defaultCountryCode = prefs.getString('selectedCountry')!;
    }
  }

  static Future<void> setDefaultLanguage(String languageCode) async {
    defaultLanguage = languageCode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageCode);

    tmdbWithCustLogs = TMDB(
      ApiKeys(apiKey, readAccToken),
      defaultLanguage: defaultLanguage,
      logConfig: const ConfigLogger(showLogs: true, showErrorLogs: true),
    );
  }

  static Future<void> setDefaultCountry(String countryCode) async {
    defaultLanguage = countryCode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCountry', countryCode);
  }

  static Future<void> initIsGuest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool? isGuestsPref = prefs.getBool('isGuest');
    if (isGuestsPref == true) {

      isGuest = isGuestsPref!;
    }
  }

  static Future<void> setIsGuest(bool isGuestValue) async {
    isGuest = isGuestValue;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', isGuest);
  }

  static Color firstTabColor = Color(0xffd6069b);
  static Color secondTabColor = Color(0xff690257);
  static Color thirdTabColor = Color(0xff540126);
  static Color fourthTabColor = Color(0xff480178);
  static Color fifthTabColor = Color(0xff270140);
  static Color highlightColor = Color(0xFFfffdfc);

  static Future<String> appVersion = getPackageInfo();

  static Future<String> getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    return version;
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  static double parseDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      // Handle other cases, such as string representation of a number
      return double.tryParse(value.toString()) ?? 0.0;
    }
  }

  static Color getCircleColor(double rating) {
    if (rating < 1.0) {
      return Color(0xFF212121);
    } else if (rating >= 1.0 && rating <= 2.0) {
      return Color(0xFF6E3A06);
    } else if (rating >= 2.0 && rating <= 3.0) {
      return Color(0xFF87868c);
    } else if (rating >= 3.0 && rating <= 4.0) {
      return Color(0xFFA48111);
    } else {
      return Color(0xFF6B0000);
    }
  }

  static Widget ShimmerEffectMainScreen(BuildContext context, Color color) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      width: width,
      margin:
          EdgeInsets.only(bottom: 80, top: height * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Add Expanded widget here
          Expanded(
            flex: 3,
            child: Shimmer.fromColors(
              baseColor: color,
              highlightColor: highlightColor,
              child: Container(
                margin: EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color, // Customize the color here
                ),
                height: 20,
                width: 180, // Adjust height as needed
              ),
            ),
          ),
          // Placeholder for GenreList
          SizedBox(height: 10),
          Expanded(
            flex: 30,
            child: SizedBox(
              height: 250,
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: 7, // Display 3 shimmer placeholders
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return buildShimmerMovieItem(color);
                },
              ),
            ),
          ),
          SizedBox(height: 10),

          // Add Expanded widget here
          Expanded(
            flex: 3,
            child: Shimmer.fromColors(
              baseColor: color,
              highlightColor: highlightColor,
              child: Container(
                margin: EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color, // Customize the color here
                ),
                height: 20,
                width: 180, // Adjust height as needed
              ),
            ),
          ),
          SizedBox(height: 10),

          // Placeholder for ExpansionTile
          Expanded(
            flex: 20,
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: 7, // Display 3 shimmer placeholders
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return buildShimmerTVItem(color);
                },
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            flex: 3,
            child: Shimmer.fromColors(
              baseColor: color,
              highlightColor: highlightColor,
              child: Container(
                margin: EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color, // Customize the color here
                ),
                height: 20,
                width: 180, // Adjust height as needed
              ),
            ),
          ),
          // Placeholder for ExpansionTile
          SizedBox(height: 10),

          Expanded(
            flex: 20,
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: 7, // Display 3 shimmer placeholders
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return buildShimmerTVItem(color);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget ShimmerEffectDetailScreens(BuildContext context, Color color) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Shimmer Placeholder for Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ShaderMask(
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
              child: Shimmer.fromColors(
                baseColor: color,
                highlightColor: highlightColor,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: double.infinity,
                  color: color,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(
                left: 10,
                right: 10,
                bottom: 10,
                top: MediaQuery.of(context).size.height * 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Row(
                  children: [
                    Stack(
                      children: [
                        // Shimmer Placeholder for Poster
                        Shimmer.fromColors(
                          baseColor: color,
                          highlightColor: highlightColor,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: color, // Customize the color here
                            ),
                            height: MediaQuery.of(context).size.width * 0.65,
                            width: MediaQuery.of(context).size.width * 0.4,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Card(
                            color: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Placeholder for Movie Info Rows
                                  Shimmer.fromColors(
                                    baseColor: color,
                                    highlightColor: highlightColor,
                                    child: Column(
                                      children: [
                                        SizedBox(height: 10),
                                        Shimmer.fromColors(
                                          baseColor: color,
                                          highlightColor: highlightColor,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color:
                                                  color, // Customize the color here
                                            ),
                                            height:
                                                30, // Adjust height as needed
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Shimmer.fromColors(
                                          baseColor: color,
                                          highlightColor: highlightColor,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color:
                                                  color, // Customize the color here
                                            ),
                                            height:
                                                30, // Adjust height as needed
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Shimmer.fromColors(
                                          baseColor: color,
                                          highlightColor: highlightColor,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color:
                                                  color, // Customize the color here
                                            ),
                                            height:
                                                30, // Adjust height as needed
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Shimmer.fromColors(
                                          baseColor: color,
                                          highlightColor: highlightColor,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color:
                                                  color, // Customize the color here
                                            ),
                                            height:
                                                30, // Adjust height as needed
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Shimmer.fromColors(
                                          baseColor: color,
                                          highlightColor: highlightColor,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color:
                                                  color, // Customize the color here
                                            ),
                                            height:
                                                30, // Adjust height as needed
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Shimmer.fromColors(
                                          baseColor: color,
                                          highlightColor: highlightColor,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color:
                                                  color, // Customize the color here
                                            ),
                                            height:
                                                30, // Adjust height as needed
                                          ),
                                        ),
                                      ],
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
                SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: color,
                  highlightColor: highlightColor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: highlightColor, // Customize the color here
                    ),
                    height: 20,
                    width: 180, // Adjust height as needed
                  ),
                ),
                SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: color,
                  highlightColor: highlightColor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: highlightColor, // Customize the color here
                    ),
                    height: 150, // Adjust height as needed
                  ),
                ),
                SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: color,
                  highlightColor: highlightColor,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: highlightColor // Customize the color here
                        ),
                    height: 20,
                    width: 180, // Adjust height as needed
                  ),
                ),
                SizedBox(height: 10),
                // Placeholder for GenreList
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: 7, // Display 3 shimmer placeholders
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return buildShimmerMovieItem(color);
                    },
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Shimmer.fromColors(
                  baseColor: color,
                  highlightColor: highlightColor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: highlightColor, // Customize the color here
                    ),
                    height: 20,
                    width: 180, // Adjust height as needed
                  ),
                ),
                SizedBox(height: 10),
                // Placeholder for ExpansionTile
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: 7, // Display 3 shimmer placeholders
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return buildShimmerMovieItem(color);
                    },
                  ),
                ),
                SizedBox(height: 10),
                // Placeholder for WatchProvidersScreen
                Shimmer.fromColors(
                  baseColor: color,
                  highlightColor: highlightColor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: highlightColor, // Customize the color here
                    ),
                    height: 20,
                    width: 180, // Adjust height as needed
                  ),
                ),
                SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: color,
                  highlightColor: highlightColor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: highlightColor, // Customize the color here
                    ),
                    height: 150, // Adjust height as needed
                  ),
                ),
                SizedBox(height: 10),
                // Placeholder for Banner Ad
                Shimmer.fromColors(
                  baseColor: color,
                  highlightColor: highlightColor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: highlightColor, // Customize the color here
                    ),
                    height: 20,
                    width: 180, // Adjust height as needed
                  ),
                ),
                SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: color,
                  highlightColor: highlightColor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: highlightColor, // Customize the color here
                    ),
                    height: 150, // Adjust height as needed
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildShimmerFriendsItem() {
    return AnimationLimiter(
      child: GridView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: 10,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          //_searchFollowers(context, accountId.toString(), user.accountId.toString());
          return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: Duration(milliseconds: 500),
              columnCount: 2,
              child: ScaleAnimation(
                duration: Duration(milliseconds: 900),
                curve: Curves.fastLinearToSlowEaseIn,
                child: FadeInAnimation(
                  child: Shimmer.fromColors(
                    baseColor: Singleton.secondTabColor,
                    highlightColor: highlightColor,
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      width: 160, // Adjust the width as needed
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ));
        },
      ),
    );
  }

  static Widget buildShimmerMovieItem(Color color) {
    return Shimmer.fromColors(
      baseColor: color,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 160, // Adjust the width as needed
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black,
        ),
      ),
    );
  }

  static Widget buildShimmerTVItem(Color color) {
    return Shimmer.fromColors(
      baseColor: color,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 250, // Adjust the width as needed
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black,
        ),
      ),
    );
  }

  static Future<Color?> getImagePalette(String imagePath) async {
    PaletteGenerator paletteGenerator;
    paletteGenerator =
        await PaletteGenerator.fromImageProvider(NetworkImage(imagePath));
    return paletteGenerator.vibrantColor?.color;
  }

  static Widget allTVItemsGridView(
      BuildContext scaffContext,
      PagingController<int, dynamic> pagingController,
      bool isVoteAverage,
      bool darkenItems) {
    return Expanded(
        child: AnimationLimiter(
      child: PagedGridView<int, dynamic>(
        physics: BouncingScrollPhysics(),
        pagingController: pagingController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
        ),
        builderDelegate: PagedChildBuilderDelegate(
          itemBuilder: (context, movie, index) {
            double voteAverage = isVoteAverage
                ? double.parse(movie['rating'].toString())
                : double.parse(movie['rating'].toString());
            int tvID = movie['id'];
            String posterPath = movie['background_image'] ?? '';
            String originalTitle = movie['name'];

                  UserAccountState? userRating = UserAccountState(id: tvID, favorite: false, watchlist: false, ratedValue: 0);

                  bool hasSeen =
                      userRating != 0 && userRating.ratedValue != 0.0;

                  ColorFilter colorFilter =
                      ColorFilter.mode(Colors.transparent, BlendMode.multiply);

                  if (darkenItems && hasSeen) {
                    colorFilter = ColorFilter.mode(
                      Colors.black.withOpacity(0.9),
                      // Change the opacity and color here
                      BlendMode
                          .darken, //// You can change the blend mode as needed
                    );
                  }
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onLongPress: () {
                              if (!isGuest) {
                                Singleton.showRatingDialogTV(
                                    scaffContext, userRating!);
                                HapticFeedback.lightImpact();
                              }
                            },
                            onTap: () {
                              Get.to(
                                  () => DescriptionSeries(
                                        gameID: tvID,
                                        isMovie: true,
                                      ),
                                  transition: Transition.zoom,
                                  duration: Duration(milliseconds: 500));
                            },
                            child: Container(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 160,
                                child: Stack(
                                  children: [
                                    Hero(
                                      tag: 'poster_path_tag',
                                      child: Container(
                                          height: 250,
                                          decoration: posterPath.isNotEmpty
                                              ? BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  image: DecorationImage(
                                                    colorFilter: colorFilter,
                                                    image: NetworkImage(
                                                          posterPath,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ))
                                              : BoxDecoration(
                                                  color:
                                                      Singleton.thirdTabColor,
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
                                                bottomRight:
                                                    Radius.circular(20),
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
                                                        MainAxisAlignment
                                                            .center,
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
                                                          userRating
                                                                  .ratedValue !=
                                                              0.0)
                                                        SizedBox(height: 2),
                                                      if (userRating != null &&
                                                          userRating
                                                                  .ratedValue !=
                                                              0.0)
                                                        Text(
                                                          userRating.ratedValue
                                                              .toStringAsFixed(
                                                                  1),
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
                                                    fadingEdgeStartFraction:
                                                        0.1,
                                                    blankSpace: 200,
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
                                          )),
                                    ),
                                    if (posterPath.isEmpty)
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
                    ),
                  );
                }
        ),
      ),
    ));
  }

  static Widget allMovieItemsGridView(
      BuildContext scaffContext,
      PagingController<int, dynamic> pagingController,
      bool isVoteAverage,
      bool showSeenMovies) {
    return Expanded(
        child: AnimationLimiter(
      child: PagedGridView<int, dynamic>(
        physics: BouncingScrollPhysics(),
        pagingController: pagingController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
        ),
        builderDelegate: PagedChildBuilderDelegate(
          itemBuilder: (context, movie, index) {
            double voteAverage = isVoteAverage
                ? double.parse(movie['vote_average'].toString())
                : double.parse(movie['rating'].toString());
            int movieId = movie['id'];
            String posterPath = movie['poster_path'] ?? '';
            String originalTitle = movie['title'] ?? movie['name'];

            return FutureBuilder<UserAccountState>(
              future: Singleton.getUserRatingMovie(movieId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Singleton.buildShimmerPlaceholder();
                } else {
                  UserAccountState? userRating = snapshot.data;

                  bool hasSeen =
                      userRating != null && userRating.ratedValue != 0.0;

                  ColorFilter? colorFilter;

                  if (showSeenMovies && hasSeen) {
                    colorFilter = ColorFilter.mode(
                      Colors.black.withOpacity(0.9),
                      // Change the opacity and color here
                      BlendMode
                          .darken, //// You can change the blend mode as needed
                    );
                  }
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onLongPress: () {
                              if (!isGuest) {
                                Singleton.showRatingDialogMovie(
                                    scaffContext, userRating!);
                                HapticFeedback.lightImpact();
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
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              child: SizedBox(
                                width: 160,
                                child: Stack(
                                  children: [
                                    Container(
                                        height: 250,
                                        decoration: posterPath.isNotEmpty
                                            ? BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                image: DecorationImage(
                                                  colorFilter: colorFilter,
                                                  image: NetworkImage(
                                                    'https://image.tmdb.org/t/p/w500' +
                                                        posterPath,
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
                                                  text: originalTitle,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                    if (posterPath.isEmpty)
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
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    ));
  }

  static Future<List<AppUser>> searchUsers() async {
    final List<AppUser> users = [];
    final ref = FirebaseDatabase.instance.ref("users");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) async {
        final accountId = value['accountId'] as int;
        final sessionId = value['sessionId'] as String;

        final user = AppUser(accountId: accountId, sessionId: sessionId);
        await user.loadUserData();
        users.add(user);
      });
    }
    return users;
  }

  static Widget buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: thirdTabColor,
      highlightColor: Color(0xFF2d2d2d),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static Future<UserAccountState> getUserRatingTV(int seriesId) async {
    String? sessionId = await SessionManager.getSessionId();

    if (isGuest) {
      UserAccountState userrating = UserAccountState(
          id: 0, favorite: false, watchlist: false, ratedValue: 0);
      return userrating;
    } else {
      Map<dynamic, dynamic> ratedSeriesResult = await tmdbWithCustLogs.v3.tv
          .getAccountStatus(seriesId, sessionId: sessionId);

      // Extract the data from the ratedSeriesResult
      int seriesID = ratedSeriesResult['id'];
      bool favorite = ratedSeriesResult['favorite'];
      double ratedValue = 0.0; // Default value is 0.0

      if (ratedSeriesResult['rated'] is Map<String, dynamic>) {
        Map<String, dynamic> ratedData = ratedSeriesResult['rated'];
        ratedValue = ratedData['value']?.toDouble() ?? 0.0;
      }

      bool watchlist = ratedSeriesResult['watchlist'];

      UserAccountState userRatingData = UserAccountState(
          id: seriesID,
          favorite: favorite,
          watchlist: watchlist,
          ratedValue: ratedValue);

      return userRatingData;
    }
  }

  static Future<UserAccountState> getUserRatingTVEpisode(int seriesId, int seasonNumber, int episodeNumber) async {
    String? sessionId = await SessionManager.getSessionId();
    final isGuest = Singleton.isGuest;

    if (isGuest) {
      UserAccountState userrating = UserAccountState(
          id: 0, favorite: false, watchlist: false, ratedValue: 0);
      return userrating;
    } else {
      final url = Uri.parse('https://api.themoviedb.org/3/tv/$seriesId/season/$seasonNumber/episode/$episodeNumber/account_states?api_key=$apiKey&session_id=$sessionId&language=$defaultLanguage');

      print(url);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionId',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> ratedSeriesResult = json.decode(response.body);

        double ratedValue = 0.0;

        if (ratedSeriesResult['rated'] is Map<String, dynamic>) {
          Map<String, dynamic> ratedData = ratedSeriesResult['rated'];
          ratedValue = ratedData['value']?.toDouble() ?? 0.0;
        }


        UserAccountState userRatingData = UserAccountState(
            id: seriesId,
            favorite: false,
            watchlist: false,
            ratedValue: ratedValue);

        return userRatingData;
      } else {
        throw Exception('Failed to load user rating');
      }
    }
  }


  static Future<UserAccountState> getUserRatingMovie(int seriesId) async {
    String? sessionId = await SessionManager.getSessionId();

    if (isGuest) {
      UserAccountState userrating = UserAccountState(
          id: 0, favorite: false, watchlist: false, ratedValue: 0);
      return userrating;
    } else {
      Map<dynamic, dynamic> ratedSeriesResult = await tmdbWithCustLogs.v3.movies
          .getAccountStatus(seriesId, sessionId: sessionId);

      // Extract the data from the ratedSeriesResult
      int seriesID = ratedSeriesResult['id'];
      bool favorite = ratedSeriesResult['favorite'];
      double ratedValue = 0.0; // Default value is 0.0

      if (ratedSeriesResult['rated'] is Map<String, dynamic>) {
        Map<String, dynamic> ratedData = ratedSeriesResult['rated'];
        ratedValue = ratedData['value']?.toDouble() ?? 0.0;
      }

      bool watchlist = ratedSeriesResult['watchlist'];

      UserAccountState userRatingData = UserAccountState(
          id: seriesID,
          favorite: favorite,
          watchlist: watchlist,
          ratedValue: ratedValue);

      return userRatingData;
    }
  }

  static void showRatingDialogMovie(
      BuildContext context, UserAccountState userAccountState) {
    double rating = 0;
    showAnimatedDialog(
      context: context,
      barrierDismissible: true,
      animationType: DialogTransitionType.slideFromBottom,
      curve: Curves.fastOutSlowIn,
      duration: Duration(seconds: 1),
      builder: (BuildContext innerContext) {
        return AlertDialog(
          shadowColor: Color(0xff690257),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            translate('Bewerte diesen Film'),
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          backgroundColor: Color(0xFF1f1f1f),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rating bar
                  FittedBox(
                    fit: BoxFit.fitWidth,
                    child: RatingBar.builder(
                      itemSize: 22,
                      initialRating: userAccountState.ratedValue,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      glowColor: Colors.pink,
                      glow: true,
                      unratedColor: Color(0xff690257),
                      itemCount: 10,
                      itemPadding: EdgeInsets.symmetric(horizontal: 1.5),
                      itemBuilder: (context, _) => Icon(
                        CupertinoIcons.film,
                        color: Color(0xffd6069b),
                      ),
                      onRatingUpdate: (updatedRating) {
                        rating = updatedRating;
                      },
                    ),
                  )
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Logic to submit the rating
                deleteRatingMovie(innerContext, rating, userAccountState.id);
                HapticFeedback.mediumImpact();
                Navigator.of(innerContext).pop();
                final snackBar = SnackBar(
                  /// need to set following properties for best effect of awesome_snackbar_content
                  elevation: 20,
                  behavior: SnackBarBehavior.fixed,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: translate('Gelöscht!'),
                    message: translate(
                        'Bewertung des Filmes wurde erfolgreich gelöscht!'),

                    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                    contentType: ContentType.failure,
                    color: Singleton.fifthTabColor,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
              },
              child: Text(
                translate('Löschen'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(innerContext).pop();
              },
              child: Text(
                translate('Abbruch'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                // Logic to submit the rating
                submitRatingMovie(innerContext, rating, userAccountState.id);
                HapticFeedback.mediumImpact();
                Navigator.of(innerContext).pop();
                final snackBar = SnackBar(
                  /// need to set following properties for best effect of awesome_snackbar_content
                  elevation: 20,
                  behavior: SnackBarBehavior.fixed,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: translate('Erfolg!'),
                    message: translate('Film erfolgreich bewertet!'),

                    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                    contentType: ContentType.success,
                    color: Singleton.firstTabColor,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
              },
              child: Text(
                translate('Anwenden'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }

  static void submitRatingMovie(
      BuildContext context, double rating, int seriesId) async {
    String? sessionId = await SessionManager.getSessionId();

    Map<dynamic, dynamic> postResult = isGuest
        ? await tmdbWithCustLogs.v3.movies
            .rateMovie(seriesId, rating, guestSessionId: sessionId)
        : await tmdbWithCustLogs.v3.movies
            .rateMovie(seriesId, rating, sessionId: sessionId);
  }

  static void deleteRatingMovie(
      BuildContext context, double rating, int seriesId) async {
    String? sessionId = await SessionManager.getSessionId();

    Map<dynamic, dynamic> deleteResult = isGuest
        ? await tmdbWithCustLogs.v3.movies
            .deleteRating(seriesId, guestSessionId: sessionId)
        : await tmdbWithCustLogs.v3.movies
            .deleteRating(seriesId, sessionId: sessionId);
    // Close the dialog after showing the SnackBar
  }

  static void showRatingDialogTVEpisode(
      BuildContext context, UserAccountState userAccountState, int seasonNumber, int episodeNumber) {
    print(userAccountState.id);
    double rating = 0;
    showAnimatedDialog(
      context: context,
      barrierDismissible: true,
      animationType: DialogTransitionType.slideFromBottom,
      curve: Curves.fastOutSlowIn,
      duration: Duration(seconds: 1),
      builder: (BuildContext innerContext) {
        return AlertDialog(
          shadowColor: Color(0xff690257),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            translate('Bewerte diese Episode'),
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          backgroundColor: Color(0xFF1f1f1f),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rating bar
                  FittedBox(
                      fit: BoxFit.fitWidth,
                      child: RatingBar.builder(
                        itemSize: 22,
                        initialRating: userAccountState.ratedValue,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        glowColor: Colors.pink,
                        glow: true,
                        unratedColor: Color(0xff690257),
                        itemCount: 10,
                        itemPadding: EdgeInsets.symmetric(horizontal: 1.5),
                        itemBuilder: (context, _) => Icon(
                          CupertinoIcons.film,
                          color: Color(0xffd6069b),
                        ),
                        onRatingUpdate: (updatedRating) {
                          rating = updatedRating;
                        },
                      ))
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Logic to submit the rating
                deleteRatingTVEpisode(innerContext, rating, userAccountState.id, seasonNumber, episodeNumber);
                HapticFeedback.mediumImpact();
                Navigator.of(innerContext).pop();
                final snackBar = SnackBar(
                  /// need to set following properties for best effect of awesome_snackbar_content
                  elevation: 20,
                  behavior: SnackBarBehavior.fixed,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: translate('Gelöscht!'),
                    message: translate(
                        'Bewertung der Episode wurde erfolgreich gelöscht!'),

                    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                    contentType: ContentType.failure,
                    color: Singleton.fifthTabColor,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
              },
              child: Text(
                translate('Löschen'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(innerContext).pop();
              },
              child: Text(
                translate('Abbruch'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                // Logic to submit the rating
                submitRatingTVEpisode(innerContext, rating, userAccountState.id, seasonNumber, episodeNumber);
                HapticFeedback.mediumImpact();
                Navigator.of(innerContext).pop();
                final snackBar = SnackBar(
                  /// need to set following properties for best effect of awesome_snackbar_content
                  elevation: 20,
                  behavior: SnackBarBehavior.fixed,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: translate('Erfolg!'),
                    message: translate('Serie erfolgreich bewertet!'),

                    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                    contentType: ContentType.success,
                    color: Singleton.firstTabColor,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
              },
              child: Text(
                translate('Anwenden'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }


  static void submitRatingTVEpisode(
      BuildContext context, double rating, int id, int seasonNumber, int episodeNumber) async {
    String? sessionId = await SessionManager.getSessionId();

    final url = Uri.parse('https://api.themoviedb.org/3/tv/$id/season/$seasonNumber/episode/$episodeNumber/rating?api_key=$apiKey&session_id=$sessionId&language=$defaultLanguage');

    Map<String, dynamic> requestBody = {
      'value': rating
    };

    print(url);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json;charset=utf-8',
          'Authorization': 'Bearer $sessionId',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Rating submitted successfully');
      } else {
        print('Failed to submit rating: ${response.statusCode}');
      }
    } catch (error) {
      print('Error submitting rating: $error');
    }
  }




  static void deleteRatingTVEpisode(
      BuildContext context, double rating, int id, int seasonNumber, int episodeNumber) async {
    String? sessionId = await SessionManager.getSessionId();

    final url = Uri.parse('https://api.themoviedb.org/3/tv/$id/season/$seasonNumber/episode/$episodeNumber/rating?api_key=$apiKey&session_id=$sessionId&language=$defaultLanguage');

    print(url);
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json;charset=utf-8',
          'Authorization': 'Bearer $sessionId',
        },
      );

      if (response.statusCode == 200) {
        print('Rating submitted successfully');
      } else {
        print('Failed to submit rating: ${response.statusCode}');
      }
    } catch (error) {
      print('Error submitting rating: $error');
    }
  }

  static void showRatingDialogTV(
      BuildContext context, UserAccountState userAccountState) {
    double rating = 0;
    showAnimatedDialog(
      context: context,
      barrierDismissible: true,
      animationType: DialogTransitionType.slideFromBottom,
      curve: Curves.fastOutSlowIn,
      duration: Duration(seconds: 1),
      builder: (BuildContext innerContext) {
        return AlertDialog(
          shadowColor: Color(0xff690257),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            translate('Bewerte diese Serie'),
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          backgroundColor: Color(0xFF1f1f1f),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rating bar
                  FittedBox(
                      fit: BoxFit.fitWidth,
                      child: RatingBar.builder(
                        itemSize: 22,
                        initialRating: userAccountState.ratedValue,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        glowColor: Colors.pink,
                        glow: true,
                        unratedColor: Color(0xff690257),
                        itemCount: 10,
                        itemPadding: EdgeInsets.symmetric(horizontal: 1.5),
                        itemBuilder: (context, _) => Icon(
                          CupertinoIcons.film,
                          color: Color(0xffd6069b),
                        ),
                        onRatingUpdate: (updatedRating) {
                          rating = updatedRating;
                        },
                      ))
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Logic to submit the rating
                deleteRatingTV(innerContext, rating, userAccountState.id);
                HapticFeedback.mediumImpact();
                Navigator.of(innerContext).pop();
                final snackBar = SnackBar(
                  /// need to set following properties for best effect of awesome_snackbar_content
                  elevation: 20,
                  behavior: SnackBarBehavior.fixed,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: translate('Gelöscht!'),
                    message: translate(
                        'Bewertung der Serie wurde erfolgreich gelöscht!'),

                    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                    contentType: ContentType.failure,
                    color: Singleton.fifthTabColor,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
              },
              child: Text(
                translate('Löschen'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(innerContext).pop();
              },
              child: Text(
                translate('Abbruch'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                // Logic to submit the rating
                submitRatingTV(innerContext, rating, userAccountState.id);
                HapticFeedback.mediumImpact();
                Navigator.of(innerContext).pop();
                final snackBar = SnackBar(
                  /// need to set following properties for best effect of awesome_snackbar_content
                  elevation: 20,
                  behavior: SnackBarBehavior.fixed,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: translate('Erfolg!'),
                    message: translate('Serie erfolgreich bewertet!'),

                    /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                    contentType: ContentType.success,
                    color: Singleton.firstTabColor,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
              },
              child: Text(
                translate('Anwenden'),
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }

  static void submitRatingTV(
      BuildContext context, double rating, int id) async {
    // Get the movie ID and rating from the state
    String? sessionId = await SessionManager.getSessionId();

    Map<dynamic, dynamic> postResult = isGuest
        ? await tmdbWithCustLogs.v3.tv
            .rateTvShow(id, rating, guestSessionId: sessionId)
        : await tmdbWithCustLogs.v3.tv
            .rateTvShow(id, rating, sessionId: sessionId);
  }

  static void deleteRatingTV(
      BuildContext context, double rating, int id) async {
    // Get the session ID and account ID
    String? sessionId = await SessionManager.getSessionId();

    Map<dynamic, dynamic> postResult = isGuest
        ? await tmdbWithCustLogs.v3.tv
            .deleteRating(id, guestSessionId: sessionId)
        : await tmdbWithCustLogs.v3.tv.deleteRating(id, sessionId: sessionId);
  }

  static Widget buildErrorContainer() {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 40,
        ),
      ),
    );
  }

  static Matrix4 getTransformMatrix(TransformableListItem item) {
    /// final scale of child when the animation is completed
    const endScaleBound = 0.3;

    /// 0 when animation completed and [scale] == [endScaleBound]
    /// 1 when animation starts and [scale] == 1
    final animationProgress = item.visibleExtent / item.size.height;

    /// result matrix
    final paintTransform = Matrix4.identity();

    /// animate only if item is on edge
    if (item.position != TransformableListItemPosition.middle) {
      final scale = endScaleBound + ((1 - endScaleBound) * animationProgress);

      paintTransform
        ..translate(item.size.width / 2)
        ..scale(scale)
        ..translate(-item.size.width / 2);
    }

    return paintTransform;
  }

  static Matrix4 getWheelMatrix(TransformableListItem item) {
    /// rotate item to 36 degrees
    const maxRotationTurnsInRadians = pi / 5.0;
    const minScale = 0.6;
    const maxScale = 1.0;

    /// perception of depth when the item rotates
    const depthFactor = 0.001;

    /// offset when [animationProgress] == 0
    final medianOffset = item.constraints.viewportMainAxisExtent / 2;
    final animationProgress =
        1 - item.offset.dx.clamp(0, double.infinity) / medianOffset;
    final scale = minScale + (maxScale - minScale) * animationProgress.abs();

    /// alignment of item
    final translationOffset = FractionalOffset.center.alongSize(item.size);
    final rotationMatrix = Matrix4.identity()
      ..setEntry(2, 2, depthFactor)
      ..rotateY(maxRotationTurnsInRadians * animationProgress)
      ..scale(scale);

    final result = Matrix4.identity()
      ..translate(translationOffset.dx, translationOffset.dy)
      ..multiply(rotationMatrix)
      ..translate(-translationOffset.dx, -translationOffset.dy);

    return result;
  }

  static Matrix4 getRotateMatrix(TransformableListItem item) {
    /// rotate item to 90 degrees
    const maxRotationTurnsInRadians = pi / 2.0;

    /// 0 when animation starts and [rotateAngle] == 0 degrees
    /// 1 when animation completed and [rotateAngle] == 90 degrees
    final animationProgress = 1 - item.visibleExtent / item.size.height;

    /// result matrix
    final paintTransform = Matrix4.identity();

    /// animate only if item is on edge
    if (item.position != TransformableListItemPosition.middle) {
      /// rotate to the left if even
      /// rotate to the right if odd
      final isEven = item.index?.isEven ?? false;

      /// To select corner of the rotation
      final FractionalOffset fractionalOffset;
      final int rotateDirection;

      switch (item.position) {
        case TransformableListItemPosition.topEdge:
          fractionalOffset = isEven
              ? FractionalOffset.bottomLeft
              : FractionalOffset.bottomRight;
          rotateDirection = isEven ? -1 : 1;
          break;
        case TransformableListItemPosition.middle:
          return paintTransform;
        case TransformableListItemPosition.bottomEdge:
          fractionalOffset =
              isEven ? FractionalOffset.topLeft : FractionalOffset.topRight;
          rotateDirection = isEven ? 1 : -1;
          break;
      }

      final rotateAngle = animationProgress * maxRotationTurnsInRadians;
      final translation = fractionalOffset.alongSize(item.size);

      paintTransform
        ..translate(translation.dx, translation.dy)
        ..rotateZ(rotateDirection * rotateAngle)
        ..translate(-translation.dx, -translation.dy);
    }

    return paintTransform;
  }

  static Matrix4 getScaleDownMatrix(TransformableListItem item) {
    /// final scale of child when the animation is completed
    const endScaleBound = 0.3;

    /// 0 when animation completed and [scale] == [endScaleBound]
    /// 1 when animation starts and [scale] == 1
    final animationProgress = item.visibleExtent / item.size.height;

    /// result matrix
    final paintTransform = Matrix4.identity();

    /// animate only if item is on edge
    if (item.position != TransformableListItemPosition.middle) {
      final scale = endScaleBound + ((1 - endScaleBound) * animationProgress);

      paintTransform
        ..translate(item.size.width / 2)
        ..scale(scale)
        ..translate(-item.size.width / 2);
    }

    return paintTransform;
  }

  static Future<void> addToRecommendations(
      BuildContext context,
      Future<int?> accountID,
      Future<String?> sessionID,
      bool isMovie,
      int id) async {
    // Implement the logic to add the movie/TV show to the user's watchlist
    int? accountId = await accountID;
    String? sessionId = await sessionID;
    TMDB tmdbWithCustLogs = TMDB(
        ApiKeys(RawgApiService.getApiKey(), RawgApiService.getReadAccToken()),
        logConfig: ConfigLogger(showLogs: true, showErrorLogs: true));
    tmdbWithCustLogs.v3.account.markAsFavorite(
        sessionId!, accountId!, id, isMovie ? MediaType.movie : MediaType.tv);
    final snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 20,
      behavior: SnackBarBehavior.fixed,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: translate('Empfohlen!'),
        message: isMovie
            ? translate('Film erfolgreich zu deinen Empfehlungen hinzugefügt!')
            : translate(
                'Serie erfolgreich zu deinen Empfehlungen hinzugefügt!'),

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        color: Singleton.firstTabColor,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static Future<void> removeFromRecommendations(
      BuildContext context,
      Future<int?> accountID,
      Future<String?> sessionID,
      bool isMovie,
      int id) async {
    try {
      int? accountId = await accountID;
      String? sessionId = await sessionID;

      final apiUrl = Uri.parse(
          'https://api.themoviedb.org/3/account/$accountId/favorite?api_key=${RawgApiService.getApiKey()}&session_id=$sessionId');

      final payload = {
        "media_type": isMovie ? "movie" : "tv",
        "media_id": id,
        "favorite": false,
      };

      final headers = {'Content-Type': 'application/json;charset=utf-8'};

      final response = await http.post(
        apiUrl,
        headers: headers,
        body: json.encode(payload),
      );

      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 20,
        behavior: SnackBarBehavior.fixed,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: translate('Nicht mehr empfohlen!'),
          message: isMovie
              ? translate('Film erfolgreich aus deinen Empfehlungen entfernt!')
              : translate(
                  'Serie erfolgreich aus deinen Empfehlungen entfernt!'),

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.success,
          color: Singleton.firstTabColor,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);

      if (response.statusCode == 201) {
        // Marking as not favorite was successful
        print("Marked as not favorite successfully");
      } else {
        // Handle error response
        print("Error marking as not favorite: ${response.statusCode}");
      }
    } catch (error) {
      // Handle exceptions
      print("Error: $error");
    }
  }

  static Future<void> addToWatchlist(
      BuildContext context,
      Future<int?> accountID,
      Future<String?> sessionID,
      bool isMovie,
      int id) async {
    // Implement the logic to add the movie/TV show to the user's watchlist
    int? accountId = await accountID;
    String? sessionId = await sessionID;
    Singleton.tmdbWithCustLogs.v3.account.addToWatchList(
        sessionId!, accountId!, id, isMovie ? MediaType.movie : MediaType.tv);

    final snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 20,
      behavior: SnackBarBehavior.fixed,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: translate('Watchlist!'),
        message: isMovie
            ? translate('Film erfolgreich zu deiner Watchlist hinzugefügt!')
            : translate('Serie erfolgreich zu deiner Watchlist hinzugefügt!'),

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        color: Singleton.firstTabColor,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static Future<void> removeFromWatchlist(
      BuildContext context,
      Future<int?> accountID,
      Future<String?> sessionID,
      bool isMovie,
      int id) async {
    try {
      int? accountId = await accountID;
      String? sessionId = await sessionID;

      final apiUrl = Uri.parse(
          'https://api.themoviedb.org/3/account/$accountId/watchlist?api_key=${RawgApiService.getApiKey()}&session_id=$sessionId');

      final payload = {
        "media_type": isMovie ? "movie" : "tv",
        "media_id": id,
        "watchlist": false,
      };

      final headers = {'Content-Type': 'application/json;charset=utf-8'};

      final response = await http.post(
        apiUrl,
        headers: headers,
        body: json.encode(payload),
      );

      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 20,
        behavior: SnackBarBehavior.fixed,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: translate('Nicht mehr in Watchlist!'),
          message: isMovie
              ? translate('Film erfolgreich aus deiner Watchlist entfernt!')
              : translate('Serie erfolgreich aus deiner Watchlist entfernt!'),

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.success,
          color: Singleton.firstTabColor,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);

      if (response.statusCode == 201) {
        // Marking as not favorite was successful
        print("Marked as not favorite successfully");
      } else {
        // Handle error response
        print("Error marking as not favorite: ${response.statusCode}");
      }
    } catch (error) {
      // Handle exceptions
      print("Error: $error");
    }
  }

  static Widget buildInfoRow(IconData iconData, String text) {
    return text.isNotEmpty ? Row(
      children: [
        Icon(iconData, color: Colors.white),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    ):Container();
  }

  static Widget buildCountupRow(IconData iconData, String? prefix, double value,
      Color color, String? suffix) {
    return Row(
      children: [
        Icon(iconData, color: color),
        SizedBox(width: 8),
        Countup(
          begin: 0,
          end: value,
          prefix: prefix!,
          suffix: suffix!.isNotEmpty ? suffix : '',
          duration: Duration(seconds: 3),
          separator: '.',
          style: TextStyle(
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  static Widget customWidget(String text, BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Singleton.fourthTabColor,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  Text(
                      textAlign: TextAlign.center,
                    text,
                    style: TextStyle(color: Colors.white, fontSize: 20.0,),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(

                    onPressed: () {
                      logout(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Singleton.secondTabColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: 8.0),
                        Text(translate('LoginScreen'), style: TextStyle(fontSize: 24),),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('sessionId');
    prefs.remove('isGuest');
    FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (BuildContext context) => MyHomePage()),
          (route) => false,
    );
  }

}
