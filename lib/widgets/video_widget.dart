import 'package:cached_network_image/cached_network_image.dart';
import 'package:game_grove/peopleDetail.dart';
import 'package:game_grove/screens/all_images.dart';
import 'package:game_grove/screens/all_movies.dart';
import 'package:game_grove/screens/all_people.dart';
import 'package:game_grove/screens/images_overview.dart';
import 'package:game_grove/utils/text.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../movieDetail.dart';

class VideoWidget extends StatelessWidget {
  final List videoItems;
  final String title;
  final Color buttonColor;

  VideoWidget({
    Key? key,
    required this.videoItems,
    required this.title,
    required this.buttonColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: 10),child: mod_Text(text: translate('Videos'), color: Colors.white, size: 22)),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.all(10),
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: videoItems.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final videoItem = videoItems[index];

                  YoutubePlayerController _controller = YoutubePlayerController(
                    initialVideoId: videoItem['key'],
                    flags: YoutubePlayerFlags(
                      autoPlay: false,
                      mute: true,
                      enableCaption: true,
                      loop: false,
                      controlsVisibleAtStart: true,
                    ),
                  );

                  return InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        width: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: YoutubePlayer(
                                    controller: _controller,
                                    showVideoProgressIndicator: true,
                                    progressIndicatorColor: buttonColor,
                                    progressColors: ProgressBarColors(
                                      playedColor: buttonColor,
                                      handleColor: buttonColor,
                                    ),
                                    onReady: () {},
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              videoItem['name'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${translate('Typ')}: ${videoItem['type']}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${translate('Offiziell')}: ${videoItem['official'] ? 'Yes' : 'No'}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${translate('Seite')}: ${videoItem['site']}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
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
          ),
        ],
      ),
    );
  }
}
