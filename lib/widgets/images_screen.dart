import 'package:cached_network_image/cached_network_image.dart';
import 'package:game_grove/screens/all_images.dart';
import 'package:game_grove/screens/images_overview.dart';
import 'package:game_grove/utils/text.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:shimmer/shimmer.dart';


class ImageScreen extends StatelessWidget {
  final int movieID;
  final List images;
  final String title;
  final Map allImages;
  final Color buttonColor;
  final bool backdrop;
  final bool overview;
  int? imageType;
  final int isMovie;

  ImageScreen(
      {Key? key,
      required this.images,
      required this.title,
      required this.buttonColor,
      required this.movieID,
      required this.backdrop,
      required this.overview,
      this.imageType,
      required this.isMovie, required this.allImages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                mod_Text(text: title, color: Colors.white, size: 22),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => overview
                            ? ImagesOverview(
                                movieID: movieID,
                                isMovie: isMovie, images: allImages,
                              )
                            : AllImagesScreen(
                                title: translate('Images'),
                                appBarColor: buttonColor,
                                movieID: movieID,
                                imageType: imageType!,
                                isMovie: isMovie, images: allImages,
                              ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: buttonColor, // Set custom background color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Set custom corner radius
                    ),
                  ),
                  child: Text(translate('Alle')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (backdrop)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: images.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          width: 250,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              fit: BoxFit.contain,
                              imageUrl: images[index]['file_path'] != null
                                  ? 'https://image.tmdb.org/t/p/w500' +
                                      images[index]['file_path']
                                  : 'Failed Path',
                              placeholder: (context, url) =>
                                  Shimmer.fromColors(
                                    baseColor: Singleton.thirdTabColor!,
                                    highlightColor: Colors.grey[100]!,
                                    child: SizedBox(
                                      width: 160,
                                      height: 250,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )

          // If backdrop is false, display images horizontally in a smaller size
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: images.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                      ), // Add horizontal padding
                      child: SizedBox(
                        width: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: images[index]['file_path'] != null
                                ? 'https://image.tmdb.org/t/p/w500' +
                                    images[index]['file_path']
                                : 'Failed Path',
                            placeholder: (context, url) =>
                                Shimmer.fromColors(
                                  baseColor: Singleton.thirdTabColor!,
                                  highlightColor: Colors.grey[100]!,
                                  child: SizedBox(
                                    width: 140,
                                    height: 200,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
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
