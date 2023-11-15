import 'package:game_grove/screens/all_movies.dart';
import 'package:game_grove/utils/text.dart';
import 'package:flutter/material.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';


class CollectionScreen extends StatefulWidget {
  final Map collections;
  final String title;
  final Color buttonColor;
  final int? listID;
  final int? accountID;
  final String? sessionID;

  const CollectionScreen({
    Key? key,
    required this.collections,
    required this.title,
    required this.buttonColor,
    this.listID,
    this.accountID,
    this.sessionID,
  }) : super(key: key);

  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: mod_Text(text: widget.title, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 10),
          Center(child: SizedBox(
              height: 270,
              child: FutureBuilder<double>(
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Singleton.buildShimmerPlaceholder();
                  } else {
                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                         Get.to(() =>
                                  AllMoviesScreen(
                                      title: widget.collections['name'],
                                      appBarColor: widget.buttonColor,
                                      typeOfApiCall: 11, collectionID: widget.collections['id'],),
                             transition: Transition.downToUp, duration: Duration(milliseconds: 700)
                        );
                      },
                      child: SizedBox(
                        width: 140,
                        child: Column(
                          children: [
                            widget.collections['poster_path'] != null ?
                            Flexible(
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      'https://image.tmdb.org/t/p/w500' +
                                          widget.collections['poster_path'],
                                    ),
                                  ),
                                ),
                              ),
                            ) : Singleton.buildShimmerPlaceholder(),
                            mod_Text(
                              text: widget.collections['name'] ?? 'Loading',
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }, future: null,
              )
          ),
          )

        ],
      ),
    );
  }

}
