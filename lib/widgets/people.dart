import 'package:cached_network_image/cached_network_image.dart';
import 'package:game_grove/peopleDetail.dart';
import 'package:game_grove/screens/all_people.dart';
import 'package:game_grove/utils/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';


class PeopleScreen extends StatelessWidget {
  final List people;
  final List allPeople;
  final String title;
  final Color buttonColor;

  const PeopleScreen({
    Key? key,
    required this.people,
    required this.allPeople,
    required this.title,
    required this.buttonColor,
  }) : super(key: key);

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
                mod_Text(text: title, color: Colors.white, size: 22),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Get.to(() => AllPeopleScreen(
                          people: allPeople,
                          title: title,
                          appBarColor: buttonColor,
                        ),transition: Transition.downToUp, duration: Duration(milliseconds: 700)
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: buttonColor,
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
            height: 270,
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: people.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Get.to(() => DescriptionPeople(
                          peopleID: people[index]['id'],
                          isMovie: true,
                        ),transition: Transition.zoom, duration: Duration(milliseconds: 500)
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              margin: EdgeInsets.only(bottom: 8),
                              height: 250,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  people[index]['profile_path'] != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CachedNetworkImage(
                                      imageUrl: 'https://image.tmdb.org/t/p/w500' +
                                          people[index]['profile_path'],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                      : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                    alignment: Alignment.center,
                                  ),
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
                                              text: people[index]['name'] ?? 'Loading',
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          mod_Text(
                                            text: people[index]['character'] != null
                                                ? '(' + people[index]['character'] + ')'
                                                : people[index]['job'] != null
                                                ? people[index]['job']
                                                : '',
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(height: 4),
                                          mod_Text(
                                            text: people[index]['known_for_department'] != null
                                                ? people[index]['known_for_department']
                                                : 'Loading',
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
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
