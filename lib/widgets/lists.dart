import 'package:cached_network_image/cached_network_image.dart';
import 'package:game_grove/screens/all_list_items.dart';
import 'package:game_grove/screens/all_lists.dart';
import 'package:game_grove/utils/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';


class ListsScreen extends StatefulWidget {
  final List lists;
  final List allMovies;
  final String title;
  final Color buttonColor;
  final int? listID;
  final int? accountID;
  final String? sessionID;

  const ListsScreen({
    Key? key,
    required this.lists,
    required this.allMovies,
    required this.title,
    required this.buttonColor,
    this.listID,
    this.accountID,
    required this.sessionID,
  }) : super(key: key);

  @override
  _ListsScreenState createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              mod_Text(text: widget.title, color: Colors.white, size: 22),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                 Get.to(() => AllListsScreen(
                        movies: widget.allMovies,
                        title: widget.title,
                        appBarColor: widget.buttonColor,
                        movieID: widget.listID,
                        sessionID: widget.sessionID,
                        accountID: widget.accountID,
                      ),transition: Transition.downToUp, duration: Duration(milliseconds: 700)
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
          const SizedBox(height: 10),
          SizedBox(
            height: 270,
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: widget.lists.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                Map<String, dynamic> list = widget.lists[index];
                double voteAverage =
                    double.parse(list['favorite_count'].toString());
                int movieId = list['id'];
                return InkWell(
                  onTap: () {
                    Get.to(() => AllListsItemsScreen(
                      sessionID: widget.sessionID,
                          listID: movieId,
                          title: widget.title,
                          appBarColor: widget.buttonColor,
                        ),transition: Transition.downToUp, duration: Duration(milliseconds: 700)
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
                                  list['profile_path'] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                'https://image.tmdb.org/t/p/w500' +
                                                    list['profile_path'],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: Colors.grey,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: mod_Text(
                                              text: list['name'] ?? 'Loading',
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
