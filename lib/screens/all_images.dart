import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:http/http.dart' as http;

import '../utils/SessionManager.dart';

class AllImagesScreen extends StatefulWidget {
  final String title;
  final Color appBarColor;
  final int movieID;
  final int imageType;
  final int isMovie;
  final Map images;

  AllImagesScreen({
    required this.title,
    required this.appBarColor,
    required this.movieID,
    required this.imageType,
    required this.isMovie, required this.images,
  });

  @override
  _AllPeopleState createState() => _AllPeopleState();
}

class _AllPeopleState extends State<AllImagesScreen> {
  int currentIndex = 0;
  List shownImages = [];

  @override
  void initState() {
    super.initState();
    getImages();
  }

  Future<void> getImages() async {


     setState(() {
        if (widget.imageType == 0) {
          shownImages = widget.images['logos'];
        } else if (widget.imageType == 1) {
          shownImages = widget.images['backdrops'];
        } else if (widget.imageType == 2) {
          shownImages = widget.images['posters'];
        } else if (widget.imageType == 3) {
          shownImages = widget.images['profiles'];

        } else if (widget.imageType == 4 ) {
          shownImages = widget.images['stills'];
        }
      });
    }

  @override
  Widget build(BuildContext context) {
    double _w = MediaQuery.of(context).size.width;
    int columnCount = 2;

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
        body: AnimationLimiter(
            child: GridView.builder(
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.all(_w / 60),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            childAspectRatio: widget.imageType == 0 || widget.imageType == 1 || widget.imageType == 4
                ? 16 / 9
                : 2 / 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: shownImages.length,
          itemBuilder: (BuildContext context, int index) {
            final imageUrl = 'https://image.tmdb.org/t/p/w500' +
                shownImages[index]['file_path'];

            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: Duration(milliseconds: 500),
              columnCount: columnCount,
              child: ScaleAnimation(
                duration: Duration(milliseconds: 900),
                curve: Curves.fastLinearToSlowEaseIn,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      currentIndex = index;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoViewGallery.builder(
                          scrollPhysics: const BouncingScrollPhysics(),
                          builder: _buildItem,
                          itemCount: shownImages.length,
                          loadingBuilder: _loadingBuilder,
                          pageController:
                              PageController(initialPage: currentIndex),
                          onPageChanged: onPageChanged,
                        ),
                      ),
                    );
                  },
                  child: shownImages[index]['file_path'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ),
              ),
            );
          },
        )));
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final imageUrl =
        'https://image.tmdb.org/t/p/w500' + shownImages[index]['file_path'];

    return PhotoViewGalleryPageOptions(
      imageProvider: NetworkImage(imageUrl),
      initialScale: PhotoViewComputedScale.contained * 0.8,
      heroAttributes: PhotoViewHeroAttributes(tag: shownImages[index]['file_path']),
    );
  }

  Center _loadingBuilder(BuildContext context, ImageChunkEvent? event) {
    return Center(
      child: Container(
        width: 20.0,
        height: 20.0,
        child: CircularProgressIndicator(
          value: event == null
              ? 0
              : event.cumulativeBytesLoaded / (event.expectedTotalBytes as num),
        ),
      ),
    );
  }
}
