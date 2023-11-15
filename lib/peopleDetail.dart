import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:game_grove/widgets/images_screen.dart';
import 'package:game_grove/widgets/movies.dart';
import 'package:game_grove/utils/SessionManager.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:game_grove/widgets/series.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'api/rawg_api.dart';

class DescriptionPeople extends StatefulWidget {
  final int peopleID;
  late bool isMovie;

  DescriptionPeople({super.key, required this.peopleID, required this.isMovie});

  @override
  _DescriptionState createState() => _DescriptionState();
}

class _DescriptionState extends State<DescriptionPeople> {
  Map<String, dynamic> dataColl = {};
  List movieData = [];
  List seriesData = [];
  late Future<String?> sessionID;
  late String apiKey;
  String title = '';
  String posterUrl = '';
  String birthday = '';
  String biography = '';
  int id = 0;
  String deathday = '';
  int gender = 0;
  String known_for_department = '';
  String placeOfBirth = '';
  List images = [];
  Color colorpalette = Colors.black;
  Color lightColor = Colors.black;
  Color darkColor = Colors.black;

  String defaultLanguage  = '';

  bool dataLoaded = false;
  bool isColorLoaded = false;

  Map allImages = {};

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultLanguage = prefs.getString('selectedLanguage')!;
      sessionID = SessionManager.getSessionId();
      apiKey = RawgApiService.getApiKey();
    });
    await fetchData();
    await getImages();
    setState(() {
      dataLoaded = true;
    });
  }

  Future<void> getImages() async {
    String? sessionId = await SessionManager.getSessionId();

    final response = await http.get(Uri.parse(
        'https://api.themoviedb.org/3/person/${widget.peopleID}/images?api_key=$apiKey&session_id=$sessionId&language=$defaultLanguage'));

    if (response.statusCode == 200) {
      Map data = json.decode(response.body);

      // Access the avatar path from the response data

      setState(() {
      });
    }
  }

  fetchData() async {
    String? sessionId = await sessionID;
    int ID = widget.peopleID;
    final url = Uri.parse(
        'https://api.themoviedb.org/3/person/$ID.?api_key=$apiKey&session_id=$sessionId&language=$defaultLanguage&append_to_response=images,movie_credits,tv_credits');

    print(url);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        dataColl = data;
        title = dataColl['name'] != null && dataColl['name'].isNotEmpty
            ? dataColl['name']
            : '';
        posterUrl = dataColl['profile_path'] != null && dataColl['profile_path'].isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500' + dataColl['profile_path']
            : '';
        birthday = dataColl['birthday'] != null && dataColl['birthday'].isNotEmpty ? dataColl['birthday'] : '';
        biography = dataColl['biography'] != null && dataColl['biography'].isNotEmpty ? dataColl['biography'] : '';
        id = dataColl['id'] != null ? dataColl['id'] : 0;
        deathday = dataColl['deathday'] != null && dataColl['deathday'].isNotEmpty ? dataColl['deathday'] : '';
        gender = dataColl['gender'] != null ? dataColl['gender'] : '';
        known_for_department = dataColl['known_for_department'] != null && dataColl['known_for_department'].isNotEmpty ? dataColl['known_for_department'] : '';
        placeOfBirth = dataColl['place_of_birth'] != null && dataColl['place_of_birth'].isNotEmpty ? dataColl['place_of_birth'] : '';
        images = dataColl['images']['profiles'] ?? [];
        movieData = dataColl['movie_credits']['cast'] ?? [];
        seriesData = dataColl['tv_credits']['cast'] ?? [];
        allImages = dataColl['images'] ?? [];



      });
    } else {
      throw Exception('Failed to fetch data');
    }

    getColorPalette();

  }

  @override
  Widget build(BuildContext context) {
    String genderResult = gender == 2 ? 'Male' : 'Female';

    return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.0, 0.4), // Start at the middle left
              end: Alignment(0.0, 0.1), // End a little above the middle
              colors: [colorpalette.withOpacity(0.8), Colors.black],
            ),
          ),
          child: dataLoaded ? SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 100, bottom:20),
            child:  Column(
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
                              fontSize: 22,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 200,
                            width: 140,
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
                            child: dataColl['profile_path'] != null ?
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                posterUrl,
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
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  '${translate('Geschlecht')}: $genderResult',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  '${translate('Geburtstag')}: $birthday',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                deathday.isNotEmpty
                                    ? SizedBox(height: 10)
                                    : SizedBox.shrink(),
                                deathday.isNotEmpty
                                    ? Text(
                                  '${translate('Todestag')}: $deathday',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                )
                                    : SizedBox.shrink(),
                                SizedBox(height: 10),
                                Text(
                                  '${translate('Geburtsort')}: $placeOfBirth',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  '${translate('Department')}: $known_for_department',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ExpansionTile(
                        shape: const ContinuousRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(30))
                        ),
                        collapsedShape: const ContinuousRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(30))
                        ),
                        collapsedBackgroundColor:
                        Singleton.fifthTabColor.withOpacity(0.6),
                        backgroundColor: Colors.black.withOpacity(0.6),
                        childrenPadding: EdgeInsets.all(10),
                        iconColor: Singleton.thirdTabColor,
                        collapsedIconColor: Singleton.firstTabColor,
                        title: Text(
                          translate('Biographie'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          SizedBox(height: 10),
                          Text(
                            biography,
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

                movieData.isNotEmpty ? SizedBox(height: 20) : SizedBox.shrink(),
                movieData.isNotEmpty
                    ? MoviesScreen(
                  movies: movieData.length < 10
                      ? movieData
                      : movieData.sublist(0, 10),
                  allMovies: movieData,
                  title: translate('Mitgewirkte Filme'),
                  buttonColor: Color(0xff540126),
                  typeOfApiCall: 8,
                  peopleID: widget.peopleID,
                )
                    : SizedBox.shrink(),
                seriesData.isNotEmpty
                    ? SizedBox(height: 20)
                    : SizedBox.shrink(),
                seriesData.isNotEmpty
                    ? GamesScreen(
                  games: seriesData.length < 10
                      ? seriesData
                      : seriesData.sublist(0, 10),
                  title: translate('Mitgewirkte Serien'),
                  buttonColor: Color(0xff540126),
                  typeOfApiCall: 8,
                  peopleID: widget.peopleID,
                )
                    : SizedBox.shrink(),
                images.isNotEmpty ? SizedBox(height: 20) : SizedBox.shrink(),
                images.isNotEmpty
                    ? ImageScreen(
                  images:
                  images.length < 10 ? images : images.sublist(0, 10),
                  title: translate('Bilder'),
                  buttonColor: Color(0xff540126),
                  backdrop: false,
                  overview: false,
                  imageType: 3,
                  isMovie: 3,
                  movieID: widget.peopleID, allImages: allImages,
                )
                    : SizedBox.shrink(),
              ],
            ) ,
          ): isColorLoaded ? Singleton.ShimmerEffectDetailScreens(context, lightColor) : Container(),
        ));
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

}