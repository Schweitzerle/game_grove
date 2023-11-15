import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Database/userAccountState.dart';
import '../utils/text.dart';
import '../widgets/singleton.dart';
import 'package:http/http.dart' as http;

class GenreButton extends StatefulWidget {
  final String id;
  final String name;
  bool? isSelected;
  final String logoPath;
  final VoidCallback onTap;

  GenreButton(
      {super.key,
      required this.id,
      required this.name,
      this.isSelected,
      required this.onTap,
      required this.logoPath});

  @override
  _GenreButtonState createState() => _GenreButtonState();
}

class _GenreButtonState extends State<GenreButton> {
  bool isSelected = false;
  String logoPath = '';

  @override
  void initState() {
    isSelected = widget.isSelected!;
    logoPath = widget.logoPath!;
    super.initState();
  }

  @override
  void didUpdateWidget(GenreButton oldWidget) {
    if (oldWidget.isSelected != widget.isSelected) {
      setState(() {
        isSelected = widget.isSelected!;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected = !isSelected;
        });
        widget.onTap();
      },
      child: logoPath.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0), // Rounded corners
                color: isSelected ? Colors.grey : Singleton.fourthTabColor,
              ),
              child: ClipRRect(
                // ClipRRect added to make image rounded
                borderRadius: BorderRadius.circular(20.0),
                child: Opacity(
                  opacity: isSelected ? 1.0 : 0.4,
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w500' + logoPath,
                    width: MediaQuery.of(context).size.width * 0.21,
                    height: MediaQuery.of(context).size.width * 0.21,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0), // Rounded corners
                color: isSelected ? Singleton.fourthTabColor : Colors.grey,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                widget.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}

class MovieFilterWidget extends StatefulWidget {
  @override
  _MovieFilterWidgetState createState() => _MovieFilterWidgetState();
}

class _MovieFilterWidgetState extends State<MovieFilterWidget> {
  List<String> selectedGenres = [];
  List<String> selectedMonetizationTypes = [];
  List<String> selectedWatchProviders = [];
  double minVoteCount = 0;
  RangeValues voteAverageRange = RangeValues(1.0, 10.0);
  RangeValues releaseYearRange =
      RangeValues(1900.toDouble(), DateTime.now().year.toDouble());
  String sortMoviesBy = 'popularity.desc';
  bool isMovieSelected = true; // Added boolean flag for movie selection

  List<GenreButton> movieGenresList = []; // Separate genre list for movies
  List<GenreButton> tvSeriesGenresList =
      []; // Separate genre list for TV series
  List<GenreButton> watchProvidersListMovie = []; // Separate
  List<GenreButton> watchProvidersListTV = []; // Separate
  List<GenreButton> monetizationTypes = []; // Separate
  bool darkenSeenMovies = false; // Initially show seen movies

  List<Map<String, String>> sortByOptions = [
    {'popularity.asc': translate('popularity.asc')},
    {'popularity.desc': translate('popularity.desc')},
    {'primary_release_date.asc': translate('primary_release_date.asc')},
    {'primary_release_date.desc': translate('primary_release_date.desc')},
    {'revenue.asc': translate('revenue.asc')},
    {'revenue.desc': translate('revenue.desc')},
    {'vote_average.asc': translate('vote_average.asc')},
    {'vote_average.desc': translate('vote_average.desc')},
    {'vote_count.asc': translate('vote_count.asc')},
    {'vote_count.desc': translate('vote_count.desc')},
  ];

  late final PagingController<int, dynamic> _pagingController;
  Map<int, UserAccountState> userRatingCache = {};

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      _fetchMoviesPage(pageKey);
    });
    getGenres();
    getWatchProviders();
    getMonetizationTypes();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchMoviesPage(int page) async {
    try {
      final List<dynamic> movies = await _fetchMovies(page);

      final isLastPage = movies.isEmpty;

      if (isLastPage) {
        _pagingController.appendLastPage(movies.toList());
        print('Appended last page with ${movies.length} items');
      } else {
        final nextPageKey = page + 1;
        _pagingController.appendPage(movies.toList(), nextPageKey);
        print('Appended page $nextPageKey with ${movies.length} items');
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<List<dynamic>> _fetchMovies(int page) async {
    String genres = selectedGenres.join(',');
    String watchProviders = selectedWatchProviders.join('|');
    String monetizations = selectedMonetizationTypes.join('|');
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String defaultCountry = prefs.getString('selectedCountry')!;

    String def = Singleton.defaultLanguage;

    final url = Uri.parse(
        'https://api.themoviedb.org/3/discover/${isMovieSelected ? 'movie' : 'tv'}?api_key=${Singleton.apiKey}&include_adult=false&${isMovieSelected ? 'primary_release_date.gte=' : 'first_air_date.gte='}${DateTime(releaseYearRange.start.toInt()).toIso8601String()}&${isMovieSelected ? 'primary_release_date.lte=' : 'first_air_date.lte='}${DateTime(releaseYearRange.end.toInt()).toIso8601String()}&sort_by=$sortMoviesBy&vote_average.gte=${voteAverageRange.start.toInt()}&vote_average.lte=${voteAverageRange.end.toInt()}&with_genres=$genres&with_watch_monetization_types=$monetizations&with_watch_providers=$watchProviders&watch_region=$defaultCountry&vote_count.gte=$minVoteCount&page=$page&language=$def');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    List<dynamic> watchlistSeries = data['results'];
    return watchlistSeries;
  }

  void applyFilters() {
    _pagingController.refresh();
    setState(() {
      darkenSeenMovies = false;
    });
    Navigator.pop(context);
  }

  void getMonetizationTypes() {
    Map<String, String> monetizationTypeMappings = {
      'flatrate': '1',
      'free': '2',
      'ads': '3',
      'rent': '4',
      'buy': '5',
    };
    setState(() {
      monetizationTypes = List<GenreButton>.from(
        monetizationTypeMappings.entries.map(
          (provider) => GenreButton(
            id: provider.value,
            name: provider.key,
            onTap: () => toggleWatchMonetizationType(provider.key.toString()),
            isSelected: false,
            logoPath: '',
          ),
        ),
      );
    });
  }

  Future<void> getWatchProviders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String defaultCountry = prefs.getString('selectedCountry')!;
    final urlMovie = Uri.parse(
        'https://api.themoviedb.org/3/watch/providers/movie?api_key=${Singleton.apiKey}&language=en-US&watch_region=$defaultCountry');
    final responseMovie = await http.get(urlMovie);
    final dataMovie = jsonDecode(responseMovie.body);

    List<dynamic> watchProviderResultsMovie = dataMovie['results'];

    setState(() {
      watchProvidersListMovie = List<GenreButton>.from(
        watchProviderResultsMovie.map(
          (provider) => GenreButton(
            id: provider['provider_id'].toString(),
            name: provider['provider_name'],
            logoPath: provider['logo_path'],
            onTap: () =>
                toggleWatchProvider(provider['provider_id'].toString()),
            isSelected: false,
          ),
        ),
      );
    });

    final urlTV = Uri.parse(
        'https://api.themoviedb.org/3/watch/providers/tv?api_key=${Singleton.apiKey}&language=en-US&watch_region=$defaultCountry');
    final responseTV = await http.get(urlTV);
    final dataTV = jsonDecode(responseTV.body);

    List<dynamic> watchProviderResultsTV = dataTV['results'];

    setState(() {
      watchProvidersListTV = List<GenreButton>.from(
        watchProviderResultsTV.map(
          (provider) => GenreButton(
            id: provider['provider_id'].toString(),
            name: provider['provider_name'],
            onTap: () =>
                toggleWatchProvider(provider['provider_id'].toString()),
            isSelected: false,
            logoPath: provider['logo_path'],
          ),
        ),
      );
    });
  }

  Future<void> getGenres() async {
    Map movieGenresResults =
        await Singleton.tmdbWithCustLogs.v3.genres.getMovieList();
    Map tvSeriesGenresResults =
        await Singleton.tmdbWithCustLogs.v3.genres.getTvlist();

    setState(() {
      movieGenresList = List<GenreButton>.from(
        movieGenresResults['genres'].map(
          (genre) => GenreButton(
            id: genre['id'].toString(),
            name: genre['name'],
            onTap: () => toggleGenre(genre['id'].toString()),
            isSelected: false,
            logoPath: '',
          ),
        ),
      );

      tvSeriesGenresList = List<GenreButton>.from(
        tvSeriesGenresResults['genres'].map(
          (genre) => GenreButton(
            id: genre['id'].toString(),
            name: genre['name'],
            onTap: () => toggleGenre(genre['id'].toString()),
            isSelected: false,
            logoPath: '',
          ),
        ),
      );
    });
  }

  void toggleWatchProvider(String genreId) {
    setState(() {
      if (isMovieSelected) {
        final genre =
            watchProvidersListMovie.firstWhere((g) => g.id == genreId);
        genre.isSelected = !genre.isSelected!;

        if (genre.isSelected!) {
          selectedWatchProviders.add(genreId);
        } else {
          selectedWatchProviders.remove(genreId);
        }
      } else {
        final genre = watchProvidersListTV.firstWhere((g) => g.id == genreId);
        genre.isSelected = !genre.isSelected!;

        if (genre.isSelected!) {
          selectedWatchProviders.add(genreId);
        } else {
          selectedWatchProviders.remove(genreId);
        }
      }
    });
  }

  void toggleWatchMonetizationType(String monetizationTypeName) {
    setState(() {
      if (isMovieSelected) {
        final genre =
            monetizationTypes.firstWhere((g) => g.name == monetizationTypeName);
        genre.isSelected = !genre.isSelected!;

        if (genre.isSelected!) {
          selectedMonetizationTypes.add(monetizationTypeName);
        } else {
          selectedMonetizationTypes.remove(monetizationTypeName);
        }
      } else {
        final genre =
            monetizationTypes.firstWhere((g) => g.name == monetizationTypeName);
        genre.isSelected = !genre.isSelected!;

        if (genre.isSelected!) {
          selectedMonetizationTypes.add(monetizationTypeName);
        } else {
          selectedMonetizationTypes.remove(monetizationTypeName);
        }
      }
    });
  }

  void toggleGenre(String genreId) {
    setState(() {
      if (isMovieSelected) {
        final genre = movieGenresList.firstWhere((g) => g.id == genreId);
        genre.isSelected = !genre.isSelected!;

        if (genre.isSelected!) {
          selectedGenres.add(genreId);
        } else {
          selectedGenres.remove(genreId);
        }
      } else {
        final genre = tvSeriesGenresList.firstWhere((g) => g.id == genreId);
        genre.isSelected = !genre.isSelected!;

        if (genre.isSelected!) {
          selectedGenres.add(genreId);
        } else {
          selectedGenres.remove(genreId);
        }
      }
    });
  }

  void resetFilters() {
    setState(() {
      selectedGenres.clear();
      selectedMonetizationTypes.clear();
      selectedWatchProviders.clear();
      voteAverageRange = RangeValues(1.0, 10.0);
      minVoteCount = 0;
      releaseYearRange = RangeValues(
        1900.toDouble(),
        DateTime.now().year.toDouble(),
      );

      _pagingController.refresh();
      if (isMovieSelected) {
        for (final genre in movieGenresList) {
          genre.isSelected = false;
        }
        for (final genre in watchProvidersListMovie) {
          genre.isSelected = false;
        }
      } else {
        for (final genre in tvSeriesGenresList) {
          genre.isSelected = false;
        }
        for (final genre in watchProvidersListTV) {
          genre.isSelected = false;
        }
      }
    });
  }

  void openFilterMenu() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Singleton.fifthTabColor.withOpacity(0.87),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 20),
                      // Dropdown menu for 'Typ'
                      SizedBox(height: 8),
                      Container(
                        width: screenWidth * 0.8,
                        padding: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        // Add padding
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: Singleton.secondTabColor),
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(
                              10), // Add rounded corners
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  translate('Typ'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Container(
                              width: screenWidth,
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              // Add padding
                              decoration: BoxDecoration(
                                color: Singleton.fifthTabColor
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(
                                    10), // Add rounded corn
                              ),
                              child:  DropdownButton<bool>(
                                borderRadius: BorderRadius.circular(20),
                                dropdownColor:
                                Singleton.fourthTabColor.withOpacity(0.87),
                                value: isMovieSelected,
                                onChanged: (newValue) {
                                  setState(() {
                                    isMovieSelected = newValue!;
                                    selectedGenres.clear();
                                  });
                                },
                                items: [
                                  DropdownMenuItem<bool>(
                                    value: true,
                                    child: mod_Text(
                                      text: translate('Filme'),
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  DropdownMenuItem<bool>(
                                    value: false,
                                    child: mod_Text(
                                      text: translate('Serien'),
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Dropdown menu for 'Sortieren nach'
                      SizedBox(height: 8),
                      Container(
                        width: screenWidth * 0.8,
                        padding: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        // Add padding
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: Singleton.secondTabColor),
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(
                              10), // Add rounded corners
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  translate('Sortieren nach:'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Container(
                              width: screenWidth,
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              // Add padding
                              decoration: BoxDecoration(
                                color: Singleton.fifthTabColor
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(
                                    10), // Add rounded corn
                              ),
                              child:   DropdownButton<String>(
                                borderRadius: BorderRadius.circular(20),
                                dropdownColor:
                                Singleton.fourthTabColor.withOpacity(0.87),
                                value: sortMoviesBy,
                                onChanged: (String? value) {
                                  setState(() {
                                    sortMoviesBy = value!;
                                  });
                                },
                                items: sortByOptions.map((Map<String, String> sortBy) {
                                  String sortByValue = sortBy.keys.first;
                                  String displayString = sortBy.values.first;
                                  return DropdownMenuItem<String>(
                                    value: sortByValue,
                                    child: mod_Text(
                                      text: displayString,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Dropdown menu for 'Genres'
                      // Expandable section for 'Genres'
                      Container(
                        width: screenWidth * 0.8,
                        padding: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        // Add padding
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: Singleton.secondTabColor),
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(
                              10), // Add rounded corners
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  translate('Genres'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              // Add padding
                              decoration: BoxDecoration(
                                color: Singleton.fifthTabColor
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(
                                    10), // Add rounded corn
                              ),
                              child:   ExpansionTile(
                                title: mod_Text(
                                  text: translate('Genres'),
                                  color: Singleton.secondTabColor,
                                  size: 18,
                                ),
                                children: [
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: (isMovieSelected ? movieGenresList : tvSeriesGenresList)
                                        .map<Widget>((genre) {
                                      return GenreButton(
                                        id: genre.id,
                                        name: genre.name,
                                        isSelected: genre.isSelected,
                                        onTap: () => toggleGenre(genre.id),
                                        logoPath: '',
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Expandable section for 'Streamingdienste'

                      SizedBox(height: 20),

                      Container(
                        width: screenWidth * 0.8,
                        padding: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        // Add padding
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: Singleton.secondTabColor),
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(
                              10), // Add rounded corners
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  translate('Streamingdienste'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              // Add padding
                              decoration: BoxDecoration(
                                color: Singleton.fifthTabColor
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(
                                    10), // Add rounded corn
                              ),
                              child:   ExpansionTile(
                                title: mod_Text(
                                  text: translate('Streamingdienste'),
                                  color: Singleton.secondTabColor,
                                  size: 18,
                                ),
                                children: [
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: (isMovieSelected
                                        ? watchProvidersListMovie
                                        : watchProvidersListTV)
                                        .map<Widget>((genre) {
                                      return GenreButton(
                                        id: genre.id,
                                        name: genre.name,
                                        isSelected: genre.isSelected,
                                        onTap: () => toggleWatchProvider(genre.id),
                                        logoPath: genre.logoPath,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),

                            ),
                          ],
                        ),
                      ),
                      // Expandable section for 'Streamingoptionen'
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        width: screenWidth * 0.8,
                        padding: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        // Add padding
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: Singleton.secondTabColor),
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(
                              10), // Add rounded corners
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  translate('Streamingoptionen'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              // Add padding
                              decoration: BoxDecoration(
                                color: Singleton.fifthTabColor
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(
                                    10), // Add rounded corn
                              ),
                              child:    ExpansionTile(
                                title: mod_Text(
                                  text: translate('Streamingoptionen'),
                                  color: Singleton.secondTabColor,
                                  size: 18,
                                ),
                                children: [
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: monetizationTypes.map<Widget>((genre) {
                                      return GenreButton(
                                        id: genre.id,
                                        name: genre.name,
                                        isSelected: genre.isSelected,
                                        onTap: () => toggleWatchMonetizationType(genre.name),
                                        logoPath: '',
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),


                      SizedBox(height: 20),
                      ListTile(
                        title: mod_Text(
                          text: translate('Bewertungsspanne'),
                          color: Singleton.secondTabColor,
                          size: 18,
                        ),
                        subtitle: RangeSlider(
                          inactiveColor: Singleton.secondTabColor,
                          activeColor: Singleton.firstTabColor,
                          values: voteAverageRange,
                          min: 1.0,
                          max: 10.0,
                          divisions: 9,
                          onChanged: (values) {
                            setState(() {
                              voteAverageRange = values;
                            });
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            mod_Text(
                              text: voteAverageRange.start.toStringAsFixed(1),
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8.0),
                            mod_Text(
                              text: '-',
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8.0),
                            mod_Text(
                              text: voteAverageRange.end.toStringAsFixed(1),
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      ListTile(
                        title: mod_Text(
                          text: translate('Veröffentlichungszeitraum'),
                          color: Singleton.secondTabColor,
                          size: 18,
                        ),
                        subtitle: RangeSlider(
                          inactiveColor: Singleton.secondTabColor,
                          activeColor: Singleton.firstTabColor,
                          values: releaseYearRange,
                          min: 1900.toDouble(),
                          max: DateTime.now().year.toDouble(),
                          onChanged: (values) {
                            setState(() {
                              releaseYearRange = values;
                            });
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            mod_Text(
                              text: releaseYearRange.start.toInt().toString(),
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8.0),
                            mod_Text(
                              text: '-',
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8.0),
                            mod_Text(
                              text: releaseYearRange.end.toInt().toString(),
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      ListTile(
                        title: mod_Text(
                          text: translate('Mindest Anzahl an Bewertungen'),
                          color: Singleton.secondTabColor,
                          size: 18,
                        ),
                        subtitle: Slider(
                          inactiveColor: Singleton.secondTabColor,
                          activeColor: Singleton.firstTabColor,
                          thumbColor: Singleton.fourthTabColor,
                          value: minVoteCount,
                          min: 0.0,
                          max: 10000.0,
                          divisions: 1000,
                          onChanged: (values) {
                            setState(() {
                              minVoteCount = values;
                            });
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            mod_Text(
                              text: minVoteCount.toStringAsFixed(1),
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            primary: Singleton.fourthTabColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 20),
                            textStyle: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.normal)),
                        onPressed: applyFilters,
                        child: mod_Text(
                          text: translate('Filter anwenden'),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            primary: Singleton.fourthTabColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 20),
                            textStyle: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.normal)),
                        onPressed: () {
                          resetFilters();
                          Navigator.pop(context);
                        },
                        child: mod_Text(
                          text: translate('Filter zurücksetzen'),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleFilterChange(bool value) {
    setState(() {
      darkenSeenMovies = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Flex(direction: Axis.vertical, children: [
          Container(
              child: isMovieSelected
                  ? Singleton.allMovieItemsGridView(context,
                      _pagingController, true, darkenSeenMovies)
                  : Singleton.allTVItemsGridView(context,
                      _pagingController, true, darkenSeenMovies)),
        ]),

          Positioned(
            bottom: 100.0, // Adjust the position as needed
            right: 20.0, // A
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: openFilterMenu,
                child: Icon(Icons.movie_filter_outlined),
                backgroundColor: Singleton.fourthTabColor,
                foregroundColor: Singleton.firstTabColor,
              ),
              SizedBox(height: 10,),
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
            ],
          ),
        )]
      ),
    );
  }
}
