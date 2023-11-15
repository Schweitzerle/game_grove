import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../screens/all_movies.dart';

class GenreList extends StatelessWidget {
  final List genres;
  final Color color;
  final bool isMovieKeyword;
  final String? sessionID;

  GenreList(
      {required this.genres,
      required this.color,
      required this.isMovieKeyword, this.sessionID});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: genres.map((genre) {
        return GestureDetector(
          onTap: isMovieKeyword
              ? () {
                  HapticFeedback.lightImpact();
                  Get.to(()=> AllMoviesScreen(
                                title: genre['name'],
                                appBarColor: Color(0xff540126),
                                typeOfApiCall: 10,
                                keywordID: genre['id'],
                            sessionID: sessionID,
                              ),transition: Transition.downToUp, duration: Duration(milliseconds: 700));
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Text(
              genre['name'],
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }).toList(),
    );
  }
}
