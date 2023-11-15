import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:game_grove/utils/AdMobService.dart';
import 'package:game_grove/utils/SessionManager.dart';
import 'package:game_grove/utils/text.dart';
import 'package:game_grove/widgets/genreWidget.dart';
import 'package:game_grove/widgets/images_screen.dart';
import 'package:game_grove/widgets/people.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:game_grove/widgets/reviews.dart';
import 'package:game_grove/widgets/series.dart';
import 'package:game_grove/widgets/tv_seasons.dart';
import 'package:game_grove/widgets/video_widget.dart';
import 'package:countup/countup.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slimy_card/flutter_slimy_card.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:game_grove/widgets/watchProviders.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_fade/image_fade.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
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
import 'episodeDetail.dart';

class DescriptionSeason extends StatefulWidget {
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
  final Map<AppUser, double> users;
  final String seriesBannerUrl;

  DescriptionSeason(
      {Key? key,
      required this.seriesID,
      required this.voteAverage,
      required this.inProduction,
      required this.revenue,
      required this.status,
      required this.tagline,
      required this.type,
      required this.recommendedSeries,
      required this.similarSeries,
      required this.genres,
      required this.keywords,
      required this.sessionId,
      required this.accountId,
      required this.reviews,
      required this.users,
      required this.seasonNumber,
      required this.seriesBannerUrl})
      : super(key: key);

  @override
  _DescriptionSeasonState createState() => _DescriptionSeasonState();
}

class _DescriptionSeasonState extends State<DescriptionSeason>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> seasonData = {};
  Map<String, dynamic> imageData = {};
  int seriesID = 0;
  List creditData = [];
  List<WatchProvider> watchProvidersList = [];
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
  List recommendedSeries = [];
  List episodes = [];
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

  Map allImages = {};

  @override
  void initState() {
    super.initState();
    loadAd();
    initialize();
  }

  Future<void> initialize() async {
    apiKey = RawgApiService.getApiKey();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultCountry = prefs.getString('selectedCountry')!;
      defaultLanguage = prefs.getString('selectedLanguage')!;
    });
    await setIDs();

    await Future.wait([
      fetchTasks(),
    ]);

    setState(() {
      dataLoaded = true;
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
    sessionId = widget.sessionId;
    accountId = widget.accountId;
    seriesID = widget.seriesID;
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
    users = widget.users;
    seasonNumber = widget.seasonNumber;
  }

  Future<double> getUserRating(int episodeNumber) async {
    String? sessionIDCurrentUser = await SessionManager.getSessionId();

    final url = Uri.parse(
        'https://api.themoviedb.org/3/tv/$seriesID/season/$seasonNumber/episode/$episodeNumber/account_states?api_key=$apiKey&session_id=$sessionIDCurrentUser');

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

      return ratedValue;
    } else {
      throw Exception('Failed to load user rating');
    }
  }

  Future<void> fetchData() async {
    String ID = widget.seriesID.toString();
    int seasonNumber = widget.seasonNumber;
    final url = Uri.parse(
        'https://api.themoviedb.org/3/tv/$ID/season/$seasonNumber?api_key=$apiKey&session_id=$sessionId&language=$defaultLanguage&append_to_response=images,videos,credits,watch/providers');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        seasonData = data;
        voteAverage = seasonData['vote_average'] != null
            ? Singleton.parseDouble(seasonData['vote_average'])
            : 0.0;
        title = seasonData['name'] != null && seasonData['name'].isNotEmpty
            ? seasonData['name']
            : '';
        launchOn =
            seasonData['air_date'] != null && seasonData['air_date'].isNotEmpty
                ? DateFormat('dd.MM.yyyy')
                    .format(DateTime.parse(seasonData['air_date']))
                : '';
        description =
            seasonData['overview'] != null && seasonData['overview'].isNotEmpty
                ? seasonData['overview']
                : '';
        id = seasonData['id'] != null ? seasonData['id'] : 0;
        posterUrl = seasonData['poster_path'] != null &&
                seasonData['poster_path'].isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500' + seasonData['poster_path']
            : '';
        creditData = seasonData['credits']['cast'] ?? [];
        videoItems = seasonData['videos']['results'] ?? [];
        images = seasonData['images']['posters'] ?? [];
        episodes = seasonData['episodes'] ?? [];
        allImages = seasonData['images'] ?? [];

        Map<dynamic, dynamic> watchProviderData = seasonData['watch/providers'];

        watchProviderData['results'].forEach((country, data) {
          String link = data['link'];
          List<Map<String, dynamic>> flatrate =
              data['flatrate'] != null ? List.from(data['flatrate']) : [];
          List<Map<String, dynamic>> rent =
              data['rent'] != null ? List.from(data['rent']) : [];
          List<Map<String, dynamic>> buy =
              data['buy'] != null ? List.from(data['buy']) : [];

          WatchProvider watchProvider = WatchProvider(
            country: country,
            link: link,
            flatrate: flatrate,
            rent: rent,
            buy: buy,
          );

          watchProvidersList.add(watchProvider);
        });
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
        colorpalette =
            paletteGenerator.dominantColor?.color ?? Singleton.thirdTabColor;
        lightColor = paletteGenerator.lightVibrantColor?.color ?? colorpalette;
        darkColor = paletteGenerator.darkVibrantColor?.color ?? colorpalette;
        isColorLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        //Init Floating Action Bubble
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.0, 0.4), // Start at the middle left
              end: Alignment(0.0, 0.1), // End a little above the middle
              colors: [darkColor.withOpacity(0.8), Colors.black],
            ),
          ),
          child: dataLoaded
              ? Stack(
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
                            widget.seriesBannerUrl.isNotEmpty
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
                                      widget.seriesBannerUrl,
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
                                      title.isNotEmpty
                                          ? title
                                          : translate('Loading...'),
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
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.65,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4,
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                  color: lightColor,
                                                  offset: Offset(4.0, 4.0),
                                                  blurRadius: 15.0,
                                                  spreadRadius: 1.0),
                                              BoxShadow(
                                                  color: lightColor,
                                                  offset: Offset(-4.0, -4.0),
                                                  blurRadius: 15.0,
                                                  spreadRadius: 1.0),
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: seasonData['poster_path'] !=
                                                  null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: ImageFade(
                                                    image: NetworkImage(
                                                      posterUrl,
                                                    ),
                                                    // slow fade for newly loaded images:
                                                    duration:
                                                        Duration(seconds: 4),
                                                    alignment: Alignment.center,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Countup(
                                                  begin: 0,
                                                  precision: 1,
                                                  end: voteAverage,
                                                  //here you insert the number or its variable
                                                  duration:
                                                      Duration(seconds: 4),
                                                  separator: '.',
                                                  //this is the character you want to add to seperate between every 3 digits
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            circularStrokeCap:
                                                CircularStrokeCap.round,
                                            backgroundColor: Colors.transparent,
                                            progressColor:
                                                Singleton.getCircleColor(
                                              Singleton.parseDouble(
                                                  voteAverage),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 10),
                                          tagline.isNotEmpty
                                              ? Text(
                                                  tagline.isNotEmpty
                                                      ? tagline
                                                      : translate('Loading...'),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : Container(),
                                          SizedBox(height: 10),
                                          Card(
                                            color: Colors.transparent,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Wrap(
                                                    spacing: 5,
                                                    runSpacing: 5,
                                                    children: [
                                                      Singleton.buildInfoRow(
                                                          Icons.category,
                                                          '$type', false),
                                                      Singleton.buildInfoRow(
                                                          Icons.info,
                                                          '$status', false),
                                                      Singleton.buildInfoRow(
                                                          Icons
                                                              .production_quantity_limits,
                                                          '$inProduction', false),
                                                      Singleton.buildInfoRow(
                                                          Icons.calendar_today,
                                                          '${launchOn ?? ''}', false),
                                                      Singleton.buildCountupRow(
                                                          Icons.playlist_play,
                                                          '',
                                                          episodes.length
                                                              .toDouble(),
                                                          Colors.yellow,
                                                          ''),
                                                      SizedBox(height: 10),
                                                      genres.isNotEmpty
                                                          ? FittedBox(
                                                              child: GenreList(
                                                                genres: genres,
                                                                color: Color(
                                                                    0xff540126),
                                                                isMovieKeyword:
                                                                    false,
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
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.1,
                                        child: ListView.builder(
                                          physics: BouncingScrollPhysics(),
                                          scrollDirection: Axis.horizontal,
                                          itemCount: users.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            AppUser user =
                                                users.keys.elementAt(index);
                                            double? rating = users[user];
                                            return Container(
                                              margin:
                                                  EdgeInsets.only(right: 10),
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.2,
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
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
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.05,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Singleton
                                                            .getCircleColor(
                                                                rating!),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          rating.toString(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                SizedBox(
                                  height: 10,
                                ),
                                ExpansionTile(
                                  shape: const ContinuousRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(30))),
                                  collapsedShape:
                                      const ContinuousRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(30))),
                                  collapsedBackgroundColor:
                                      Singleton.fifthTabColor.withOpacity(0.6),
                                  backgroundColor:
                                      Singleton.fourthTabColor.withOpacity(0.6),
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
                                SizedBox(height: 10),
                                watchProvidersList.isNotEmpty
                                    ? WatchProvidersScreen(
                                        watchProviders: watchProvidersList,
                                        selectedCountry: defaultCountry,
                                      )
                                    : Container(),
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
                          isColorLoaded
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: mod_Text(
                                          text: translate('Episoden'),
                                          color: Colors.white,
                                          size: 22),
                                    ),
                                    SizedBox(height: 10),
                                    SingleChildScrollView(
                                      physics: BouncingScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      // Set the scroll direction to horizontal
                                      child: Row(
                                        children: episodes.map((episode) {
                                          return FutureBuilder<
                                                  UserAccountState>(
                                              future: Singleton
                                                  .getUserRatingTVEpisode(
                                                      seriesID,
                                                      seasonNumber,
                                                      episode[
                                                          'episode_number']),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 8),
                                                    child: Shimmer.fromColors(
                                                      baseColor: Singleton
                                                          .thirdTabColor!,
                                                      highlightColor:
                                                          Colors.grey[100]!,
                                                      child: SizedBox(
                                                        width: 160,
                                                        height: 250,
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .grey[300],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                } else if (snapshot.hasData) {
                                                  UserAccountState? userRating =
                                                      snapshot.data;
                                                  double voteAverageEpisode = episode['vote_average'];
                                                  return GestureDetector(
                                                    onLongPress: () {
                                                      HapticFeedback
                                                          .lightImpact();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              DescriptionEpisode(
                                                            seriesID:
                                                                widget.seriesID,
                                                            voteAverage:
                                                                voteAverageEpisode,
                                                            inProduction:
                                                                inProduction,
                                                            revenue: revenue,
                                                            status: status,
                                                            tagline: tagline,
                                                            type: type,
                                                            recommendedSeries:
                                                                recommendedSeries,
                                                            similarSeries:
                                                                similarSeries,
                                                            genres: genres,
                                                            keywords: keywords,
                                                            sessionId:
                                                                sessionId,
                                                            accountId:
                                                                accountId,
                                                            reviews: reviews,
                                                            seasonNumber:
                                                                seasonNumber,
                                                            episodeNumber: episode[
                                                                'episode_number'],
                                                            seasonPosterUrl:
                                                                posterUrl,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 10),
                                                      // Add spacing between items
                                                      child: Stack(
                                                        children: [
                                                          FlutterSlimyCard(
                                                            color: lightColor,
                                                            borderRadius: 15,
                                                            slimeEnabled: true,
                                                            bottomCardHeight:
                                                                150,
                                                            topCardHeight: 150,
                                                            bottomCardWidget:
                                                            Container(
                                                              decoration: BoxDecoration(
                                                                color: Color(0xFF1f1f1f),
                                                                borderRadius:
                                                                BorderRadius.circular(
                                                                    20),
                                                              ),
                                                              margin: EdgeInsets.all(5),
                                                              child:
                                                              Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child:  Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    AutoSizeText(
                                                                      '${translate('Air Date')}: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(episode['air_date']))}',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              18,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                      maxLines: 2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            10),
                                                                    AutoSizeText(
                                                                      '${episode['overview']}',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          color: Colors
                                                                              .white),
                                                                      maxLines: 4,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            topCardWidget:
                                                                Container(
                                                              decoration: episode[
                                                                          'still_path'] !=
                                                                      null
                                                                  ? BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                      image:
                                                                          DecorationImage(
                                                                        image:
                                                                            NetworkImage(
                                                                          'https://image.tmdb.org/t/p/w500' +
                                                                              episode['still_path'],
                                                                        ),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    )
                                                                  : BoxDecoration(
                                                                      color: Singleton
                                                                          .thirdTabColor,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                    ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                padding:
                                                                    EdgeInsets
                                                                        .only(
                                                                  left: 8,
                                                                  right: 8,
                                                                  bottom: 8,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  gradient:
                                                                      LinearGradient(
                                                                    begin: Alignment
                                                                        .topCenter,
                                                                    end: Alignment
                                                                        .bottomCenter,
                                                                    colors: [
                                                                      Colors
                                                                          .transparent,
                                                                      Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.7),
                                                                    ],
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .only(
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            20),
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            20),
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    CircularPercentIndicator(
                                                                      radius:
                                                                          28.0,
                                                                      lineWidth:
                                                                          8.0,
                                                                      animation:
                                                                          true,
                                                                      animationDuration:
                                                                          1000,
                                                                      percent:
                                                                          voteAverageEpisode /
                                                                              10,
                                                                      center:
                                                                          Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            voteAverageEpisode.toStringAsFixed(1),
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.white,
                                                                              fontSize: 18,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                          if (userRating != null &&
                                                                              userRating.ratedValue != 0.0)
                                                                            SizedBox(height: 2),
                                                                          if (userRating != null &&
                                                                              userRating.ratedValue != 0.0)
                                                                            Text(
                                                                              userRating.ratedValue.toStringAsFixed(1),
                                                                              style: TextStyle(
                                                                                color: Colors.white,
                                                                                fontSize: 14,
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                      circularStrokeCap:
                                                                          CircularStrokeCap
                                                                              .round,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .transparent,
                                                                      progressColor:
                                                                          Singleton
                                                                              .getCircleColor(
                                                                        Singleton.parseDouble(
                                                                            voteAverageEpisode),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            8),
                                                                    Expanded(
                                                                      child:
                                                                          Marquee(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.end,
                                                                        fadingEdgeEndFraction:
                                                                            0.9,
                                                                        fadingEdgeStartFraction:
                                                                            0.1,
                                                                        blankSpace:
                                                                            200,
                                                                        pauseAfterRound:
                                                                            Duration(seconds: 4),
                                                                        text:
                                                                            'Episode ${episode['episode_number']}',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              14,
                                                                        ),
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
                                                  );
                                                } else {
                                                  // Handle error or no data scenario
                                                  return Container();
                                                }
                                              });
                                        }).toList(),
                                      ),
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
                                  backdrop: false,
                                  overview: true,
                                  isMovie: 2,
                                  allImages: allImages,
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ],
                )
              : isColorLoaded
                  ? Singleton.ShimmerEffectDetailScreens(context, lightColor)
                  : Container(),
        ));
  }
}
