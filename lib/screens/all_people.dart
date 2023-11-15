
import 'package:game_grove/peopleDetail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../utils/text.dart';

class AllPeopleScreen extends StatefulWidget {
  final List people;
  final String title;
  final Color appBarColor;

  AllPeopleScreen({super.key, required this.people, required this.title, required this.appBarColor});

  @override
  _AllPeopleState createState() => _AllPeopleState();
}

class _AllPeopleState extends State<AllPeopleScreen> {




  @override
  Widget build(BuildContext context) {
    print(widget.people.toString());
    double _w = MediaQuery.of(context).size.width;
    int columnCount = 2;
    double initRating = 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: widget.appBarColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: AnimationLimiter(
          child: GridView.count(
            physics: BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.all(_w / 60),
            crossAxisCount: columnCount,
            childAspectRatio: 2 / 3, // Set the aspect ratio for the grid items
            mainAxisSpacing: 16, // Add spacing between grid items vertically
            crossAxisSpacing: 16, // Add spacing between grid items horizontally
            children: List.generate(
              widget.people.length,
                  (int index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: Duration(milliseconds: 500),
                  columnCount: columnCount,
                  child: ScaleAnimation(
                    duration: Duration(milliseconds: 900),
                    curve: Curves.fastLinearToSlowEaseIn,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        onLongPress: () {
                          /*getUserMovieRating(widget.movies[index]['id']);
                        print('Rat: '+initRating.toString());
                        MovieDialogHelper.showMovieRatingDialog(context, initRating, rating, widget.movies[index]['id']);
                      */},
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Get.to(() => DescriptionPeople(peopleID: widget.people[index]['id'], isMovie: true),
                              transition: Transition.zoom, duration: Duration(milliseconds: 500)
                          );
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            widget.people[index]['profile_path'] != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                'https://image.tmdb.org/t/p/w500' +
                                    widget.people[index]['profile_path'],
                                fit: BoxFit.cover,
                              ),
                            )
                                : Container(),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  color: Colors.black.withOpacity(0.6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 4),
                                      child: mod_Text(
                                        text: widget.people[index]['name'] != null
                                            ? widget.people[index]['name']
                                            : 'Loading',
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    mod_Text(
                                      text: widget.people[index]['character'] != null
                                          ? '(' + widget.people[index]['character'] + ')'
                                          : widget.people[index]['job'] != null
                                          ? widget.people[index]['job']
                                          : '',
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    mod_Text(
                                      text: widget.people[index]['known_for_department'] != null
                                          ? widget.people[index]['known_for_department']
                                          : 'Loading',
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

}

