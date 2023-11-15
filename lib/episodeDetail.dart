import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:countup/countup.dart';
import 'package:game_grove/utils/AdMobService.dart';
import 'package:game_grove/utils/SessionManager.dart';
import 'package:game_grove/widgets/genreWidget.dart';
import 'package:game_grove/widgets/images_screen.dart';
import 'package:game_grove/widgets/people.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:game_grove/widgets/reviews.dart';
import 'package:game_grove/widgets/series.dart';
import 'package:game_grove/widgets/tv_seasons.dart';
import 'package:game_grove/widgets/video_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slimy_card/flutter_slimy_card.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_fade/image_fade.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:http/http.dart' as http;

import 'Database/WatchProvider.dart';
import 'Database/user.dart';
import 'Database/userAccountState.dart';
import 'api/rawg_api.dart';

class DescriptionEpisode extends StatefulWidget {
  final int seriesID;
  final int seasonNumber;
  final double voteAverage;
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
  final int episodeNumber;
  final String seasonPosterUrl;





  DescriptionEpisode({Key? key, required this.seriesID, required this.voteAverage, required this.inProduction, required this.revenue, required this.status, required this.tagline, required this.type, required this.recommendedSeries, required this.similarSeries, required this.genres, required this.keywords, required this.sessionId, required this.accountId, required this.reviews, required this.seasonNumber, required this.episodeNumber, required this.seasonPosterUrl})
      : super(key: key);

  @override
  _DescriptionEpisodeState createState() => _DescriptionEpisodeState();
}

class _DescriptionEpisodeState extends State<DescriptionEpisode>
    with SingleTickerProviderStateMixin {
  final Future<int?> accountID = SessionManager.getAccountId();
  final Future<String?> sessionID = SessionManager.getSessionId();
  Map<String, dynamic> episodeData = {};
  String seriesID = "";
  List creditData = [];
  String? apiKey;
  double voteAverage = 0;
  String title = '';
  String posterUrl = '';
  String launchOn = '';
  String description = '';
  int id = 0;
  bool inProduction = false;
  int revenue = 0;
  int numberOfEpisodes = 0;
  int numberOfSeasons = 0;
  String status = '';
  String tagline = '';
  String type = '';
  int voteCount = 0;
  List recommendedSeries = [];
  List similarSeries = [];
  List<dynamic> seasons = [];
  List images = [];
  List genres = [];
  List keywords = [];
  List reviews = [];
  List videoItems = [];
  Color colorpalette = Colors.black;
  Color lightColor = Colors.black;
  Color darkColor = Colors.black;

  Map<AppUser, double> users = {};

  NumberFormat formatter = NumberFormat('###,###,###,###');
  String sessionId = '';
  int accountId = 0;

  String defaultCountry = '';
  String defaultLanguage = '';

  BannerAd? _bannerAd;

  bool dataLoaded = false;
  bool isColorLoaded = false;

  int seasonNumber = 0;

  Color lightColorMuted = Colors.black;

  int episodeNumber = 0;

  Map allImages = {};

  bool watchlistState = false;
  bool reccState = false;
  double initialRating = 0.0;
  bool isRated = false;
  UserAccountState? userAccountState = null;


  late Animation<double> _animation;
  late AnimationController _animationController;


  @override
  void initState() {
    super.initState();
    loadAd();
    initialize();
  }

  Future<void> initialize() async {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );
    final curvedAnimation =
    CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    apiKey = RawgApiService.getApiKey();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultCountry = prefs.getString('selectedCountry')!;
      defaultLanguage = prefs.getString('selectedLanguage')!;
    });
    await setIDs();

    await Future.wait([fetchTasks(),
    ]);

    fetchUserData();

    setState(() {
      dataLoaded = true;
    });
  }

  Future<void> fetchUserData() async {
    if (accountId! >= 1) {
      await Future.wait([
        getUserRating(),
        _searchUsers(),
        getUserAccounts()
      ]);
    }
  }



  Future<void> _searchUsers() async {
    users.clear();
    List<AppUser> _users = [];
    final ref = FirebaseDatabase.instance
        .ref("users")
        .child(accountId.toString())
        .child('following');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final value in data.values) {
        final accountId = value['accountId'] as int;
        final sessionId = value['sessionId'] as String;
        final user = AppUser(accountId: accountId, sessionId: sessionId);
        await user.loadUserData();
        setState(() {
          _users.add(user);
        });
      }
    } else {
      print('No data available.');
    }

    for (AppUser user in _users) {
      String? sessionIdUser = user.sessionId;

      final url = Uri.parse('https://api.themoviedb.org/3/tv/$seriesID/season/$seasonNumber/episode/$episodeNumber/account_states?api_key=$apiKey&session_id=$sessionIdUser');

      print(url);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionIdUser',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> ratedSeriesResult = json.decode(response.body);

        double ratedValue = 0.0;

        if (ratedSeriesResult['rated'] is Map<String, dynamic>) {
          Map<String, dynamic> ratedData = ratedSeriesResult['rated'];
          ratedValue = ratedData['value']?.toDouble() ?? 0.0;
        }

        if (ratedValue != 0.0) {
          setState(() {
            users[user] = ratedValue;
          });
        }
      }
      else {
        throw Exception('Failed to load user rating');
      }
    }
  }


  Future<void> getUserRating() async {
    String? sessionIDCurrentUser = await SessionManager.getSessionId();

    final url = Uri.parse('https://api.themoviedb.org/3/tv/$seriesID/season/$seasonNumber/episode/$episodeNumber/account_states?api_key=$apiKey&session_id=$sessionIDCurrentUser');

    print(url);
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $sessionIDCurrentUser',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> ratedSeriesResult = json.decode(response.body);

      double ratedValue = 0.0;

      if (ratedSeriesResult['rated'] is Map<String, dynamic>) {
        Map<String, dynamic> ratedData = ratedSeriesResult['rated'];
        ratedValue = ratedData['value']?.toDouble() ?? 0.0;
      }

      setState(() {
        initialRating = ratedValue;
        isRated = ratedValue == 0.0 ? false : true;
        watchlistState = false;
        reccState = false;
      });

    } else {
      throw Exception('Failed to load user rating');
    }
  }





  Future<void> getUserAccounts() async {
    UserAccountState? userRating =
    await Singleton.getUserRatingTVEpisode(widget.seriesID, widget.seasonNumber, widget.episodeNumber);
    setState(() {
      userAccountState = userRating;
    });
  }

  Future<void> fetchTasks() async {
    await Future.wait([
      fetchData(),
    ]);
  }

  void loadAd() {
    _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: AdMobService.bannerAdUnitId!,
        listener: AdMobService.bannerAdListener,
        request: const AdRequest())
      ..load();
  }

  Future<void> setIDs() async {
    sessionId = (await sessionID)!;
    accountId = (await accountID)!;
    sessionId = widget.sessionId;
    accountId = widget.accountId;
    seriesID = widget.seriesID.toString();
    voteAverage = widget.voteAverage;
    inProduction = widget.inProduction;
    revenue = widget.revenue;
    status = widget.status;
    tagline = widget.tagline;
    type = widget.type;
    recommendedSeries = widget.recommendedSeries;
    similarSeries = widget.similarSeries;
    genres = widget.genres;
    keywords = widget.keywords;
    reviews = widget.reviews;
    seasonNumber = widget.seasonNumber;
    episodeNumber = widget.episodeNumber;
  }

  Future<void> fetchData() async {
    String ID = widget.seriesID.toString();
    int seasonNumber = widget.seasonNumber;
    final url = Uri.parse(
        'https://api.themoviedb.org/3/tv/$ID/season/$seasonNumber/episode/$episodeNumber?api_key=$apiKey&session_id=$sessionId&language=$defaultLanguage&append_to_response=images,videos,credits');



    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        episodeData = data;
        voteAverage = episodeData['vote_average'] != null
            ? Singleton.parseDouble(episodeData['vote_average'])
            : 0.0;
        title = episodeData['name'] != null && episodeData['name'].isNotEmpty
            ? episodeData['name']
            : '';
        launchOn = episodeData['air_date'] != null && episodeData['air_date'].isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(episodeData['air_date']))
            : '';
        description = episodeData['overview'] != null && episodeData['overview'].isNotEmpty ? episodeData['overview'] : '';
        voteCount = episodeData['vote_count'] != null ? episodeData['vote_count'] : 0;
        id = episodeData['id'] != null ? episodeData['id'] : 0;
        posterUrl = episodeData['still_path'] != null && episodeData['still_path'].isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500' + episodeData['still_path']
            : '';
        creditData = episodeData['credits']['cast'] ?? [];
        videoItems = episodeData['videos']['results'] ?? [];
        images = episodeData['images']['stills'] ?? [];
        allImages = episodeData['images'] ?? [];

      });
    } else {
      throw Exception('Failed to fetch data');
    }


    getColorPalette();




  }

  Future<void> getColorPalette() async {
    if (posterUrl.isNotEmpty) {
      final PaletteGenerator paletteGenerator =
      await PaletteGenerator.fromImageProvider(
        NetworkImage(posterUrl),
        size: Size(100, 150), // Adjust the image size as needed
        maximumColorCount: 10, // Adjust the maximum color count as needed
      );
      setState(() {
        colorpalette = paletteGenerator.dominantColor?.color ?? Singleton.thirdTabColor;
        lightColor = paletteGenerator.lightVibrantColor?.color ?? colorpalette;
        darkColor = paletteGenerator.darkVibrantColor?.color ?? colorpalette;
        isColorLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        backgroundColor: Colors.black,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: !Singleton.isGuest ? dataLoaded ? Padding(
          padding: EdgeInsets.only(bottom: 70, right: 10),
          child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Singleton.showRatingDialogTVEpisode(context, userAccountState!, seasonNumber, episodeNumber);
              _animationController.reverse();
            },
            backgroundColor: Singleton.firstTabColor,
            child: Icon(
              isRated ? CupertinoIcons.star_fill : CupertinoIcons.star,
              color: isRated ? Colors.yellow : Colors.white,
            ),
          ),
        ): Container() :Container(),

        //Init Floating Action Bubble
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.0, 0.4), // Start at the middle left
              end: Alignment(0.0, 0.1), // End a little above the middle
              colors: [darkColor.withOpacity(0.8), Colors.black],
            ),
          ),
          child:  dataLoaded ? Stack(
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
                      episodeData['still_path'] != null
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
                          posterUrl,
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
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                    bottom: 10,
                    top: MediaQuery.of(context).size.height * 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                title.isNotEmpty ? title : translate('Loading...'),
                                speed: Duration(milliseconds: 150),
                                textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            isRepeatingAnimation: true,
                            repeatForever: false,
                            totalRepeatCount: 2,
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    height: MediaQuery.of(context).size.width * 0.65,
                                    width: MediaQuery.of(context).size.width * 0.4,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                            color: lightColor,
                                            offset: Offset(4.0, 4.0),
                                            blurRadius: 15.0,
                                            spreadRadius: 1.0
                                        ),
                                        BoxShadow(
                                            color: lightColor,
                                            offset: Offset(-4.0, -4.0),
                                            blurRadius: 15.0,
                                            spreadRadius: 1.0
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: widget.seasonPosterUrl.isNotEmpty
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: ImageFade(
                                        image: NetworkImage(
                                         widget.seasonPosterUrl,
                                        ),
                                        // slow fade for newly loaded images:
                                        duration: Duration(seconds: 4),
                                        alignment: Alignment.center,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors
                                            .grey, // Customize the color here
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.photo,
                                          color: Colors.white,
                                          // Customize the icon color here
                                          size: 50,
                                        ),
                                      ),
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
                                  Positioned(
                                    bottom: 1,
                                    left: 1,
                                    child: CircularPercentIndicator(
                                      radius: 28.0,
                                      lineWidth: 8.0,
                                      animation: true,
                                      animationDuration: 4000,
                                      percent: voteAverage / 10,
                                      center: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Countup(
                                            begin: 0,
                                            precision: 1,
                                            end: voteAverage,
                                            //here you insert the number or its variable
                                            duration: Duration(seconds: 4),
                                            separator: '.',
                                            //this is the character you want to add to seperate between every 3 digits
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          initialRating != 0.0
                                              ? SizedBox(height: 2)
                                              : SizedBox(height: 0),
                                          initialRating != 0.0
                                              ? Countup(
                                            begin: 0,
                                            precision: 1,
                                            end: initialRating,
                                            //here you insert the number or its variable
                                            duration: Duration(seconds: 3),
                                            separator: '.',
                                            //this is the character you want to add to seperate between every 3 digits
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          )
                                              : Container(),
                                        ],
                                      ),
                                      circularStrokeCap: CircularStrokeCap.round,
                                      backgroundColor: Colors.transparent,
                                      progressColor: Singleton.getCircleColor(
                                        Singleton.parseDouble(voteAverage),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    tagline.isNotEmpty ?
                                    Text(
                                      tagline.isNotEmpty ? tagline : translate('Loading...'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ): Container(),
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
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 5,
                                              runSpacing: 5,
                                              children: [
                                                Singleton.buildInfoRow(
                                                    Icons.category, '$type', false),
                                                Singleton.buildInfoRow(
                                                    Icons.info, '$status', false),
                                                Singleton.buildInfoRow(
                                                    Icons.production_quantity_limits,
                                                    '$inProduction', false),
                                                Singleton.buildInfoRow(
                                                    Icons.calendar_today,
                                                    '${launchOn ?? ''}', false),
                                                Singleton.buildCountupRow(Icons.star, '', voteCount.toDouble(), Colors.orange, ''),
                                                SizedBox(height: 10),
                                                genres.isNotEmpty
                                                    ? FittedBox(
                                                  child: GenreList(
                                                    genres: genres,
                                                    color: Color(0xff540126),
                                                    isMovieKeyword: false,
                                                  ),
                                                )
                                                    : Container(),
                                              ],
                                            )
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
                          users.isNotEmpty
                              ? SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1,
                            child: ListView.builder(
                              physics: BouncingScrollPhysics(),

                              scrollDirection: Axis.horizontal,
                              itemCount: users.length,
                              itemBuilder: (BuildContext context, int index) {
                                AppUser user = users.keys.elementAt(index);
                                double? rating = users[user];
                                return Container(
                                  margin: EdgeInsets.only(right: 10),
                                  width:
                                  MediaQuery.of(context).size.width * 0.2,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          user.imagePath,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 1,
                                        left: 1,
                                        child: Container(
                                          width: MediaQuery.of(context)
                                              .size
                                              .width *
                                              0.1,
                                          height: MediaQuery.of(context)
                                              .size
                                              .height *
                                              0.05,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Singleton.getCircleColor(
                                                rating!),
                                          ),
                                          child: Center(
                                            child: Text(
                                              rating.toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                              : Container(),
                          SizedBox(height: 10),
                          keywords.isNotEmpty
                              ? GenreList(
                            genres: keywords,
                            color: Color(0xff690257),
                            isMovieKeyword: false,
                          )
                              : Container(),
                          SizedBox(height: 10,),
                          ExpansionTile(
                            shape: const ContinuousRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(30))
                            ),
                            collapsedShape: const ContinuousRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(30))
                            ),
                            collapsedBackgroundColor:
                            Singleton.fifthTabColor.withOpacity(0.6),
                            backgroundColor: Singleton.fourthTabColor.withOpacity(0.6),
                            childrenPadding: EdgeInsets.all(10),
                            iconColor: Singleton.thirdTabColor,
                            collapsedIconColor: Singleton.firstTabColor,
                            title: Text(
                              translate('Beschreibung'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              SizedBox(height: 10),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    _bannerAd != null
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 10,
                        ),

                        Container(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      ],
                    )
                        : Container(),
                    SizedBox(height: 10),
                    creditData.isNotEmpty
                        ? PeopleScreen(
                      people: creditData.length < 10
                          ? creditData
                          : creditData.sublist(0, 10),
                      allPeople: creditData,
                      title: translate('Cast und Crew'),
                      buttonColor: Color(0xff540126),
                    )
                        : Container(),
                    SizedBox(height: 10),
                    recommendedSeries.isNotEmpty
                        ? GamesScreen(
                      gameID: widget.seriesID,
                      games: recommendedSeries,
                      buttonColor: Color(0xff540126),
                      title: translate('Empfohlene Serien'),
                      typeOfApiCall: 1,
                    )
                        : Container(),
                    SizedBox(height: 10),
                    similarSeries.isNotEmpty
                        ? GamesScreen(
                      gameID: widget.seriesID,
                      games: similarSeries,
                      title: translate('Ähnliche Serien'),
                      buttonColor: Color(0xff540126),
                      typeOfApiCall: 0,
                    )
                        : Container(),
                    SizedBox(height: 10),
                    reviews.isNotEmpty
                        ? RatingsDisplayWidget(
                      id: widget.seriesID,
                      isMovie: false,
                      reviews: reviews.length < 10
                          ? reviews
                          : reviews.sublist(0, 10),
                      movieID: widget.seriesID,
                    )
                        : Container(),
                    SizedBox(height: 10),
                    videoItems.isNotEmpty
                        ? VideoWidget(
                      videoItems: videoItems,
                      title: translate('Videos'),
                      buttonColor: Color(0xff540126),
                    )
                        : Container(),
                    SizedBox(height: 10),
                    images.isNotEmpty
                        ? ImageScreen(
                      images: images.length < 10
                          ? images
                          : images.sublist(0, 10),
                      movieID: widget.seriesID,
                      title: translate('Bilder'),
                      buttonColor: Color(0xff540126),
                      backdrop: true,
                      overview: true,
                      isMovie: 2, allImages: allImages,
                    )
                        : Container(),
                  ],
                ),
              ),
            ],
          ): isColorLoaded ? Singleton.ShimmerEffectDetailScreens(context, lightColor) : Container() ,
        ));
  }


}
