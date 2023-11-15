
import 'package:game_grove/widgets/images_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';



class ImagesOverview extends StatefulWidget {
  final int movieID;
  final int isMovie;
  final Map images;

  const ImagesOverview({super.key, required this.movieID, required this.isMovie, required this.images});


@override
_ImagesOverviewState createState() => _ImagesOverviewState();
}

class _ImagesOverviewState extends State<ImagesOverview> {

  List backdrops = [];
  List logos = [];
  List posters = [];
  List profiles = [];
  List stills = [];


  @override
  void initState() {
    getImages();
    super.initState();
  }

  Future<void> getImages() async {
      setState(() {
        backdrops = widget.images['backdrops'] != null ? widget.images['backdrops'] : [];
        logos = widget.images['logos'] != null ? widget.images['logos'] : [];
        posters = widget.images['posters'] != null ? widget.images['posters'] : [];
        profiles = widget.images['profiles'] != null ? widget.images['profiles'] : [];
        stills = widget.images['stills'] != null ? widget.images['stills'] : [];
      });
    }


  @override
  Widget build(BuildContext context) {

    print(backdrops);
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Bilder')),
        backgroundColor: Color(0xff540126),
      ),

      backgroundColor: Colors.black,
      body: Padding(padding: EdgeInsets.only(bottom: 0), child: ListView(
          physics: BouncingScrollPhysics(),
          children: [
        backdrops.isNotEmpty ? ImageScreen(images: backdrops.length < 10 ? backdrops : backdrops.sublist(0, 10), title: translate('Banner'), buttonColor: Color(0xff540126), movieID: widget.movieID, backdrop: true, overview: false, imageType: 1, isMovie: widget.isMovie, allImages: widget.images,) : Container(),

        posters.isNotEmpty ? ImageScreen(images: posters.length < 10 ? posters : posters.sublist(0, 10), title: translate('Poster'), buttonColor: Color(0xff540126), movieID: widget.movieID, backdrop: false, overview: false, imageType: 2, isMovie: widget.isMovie, allImages: widget.images,) : Container(),

        logos.isNotEmpty ? ImageScreen(images: logos.length < 10 ? logos : logos.sublist(0, 10), title: translate('Logos'), buttonColor: Color(0xff540126), movieID: widget.movieID, backdrop: true, overview: false, imageType: 0, isMovie: widget.isMovie, allImages: widget.images,) : Container(),

            profiles.isNotEmpty ? ImageScreen(images: profiles.length < 10 ? profiles : profiles.sublist(0, 10), title: translate('Bilder'), buttonColor: Color(0xff540126), movieID: widget.movieID, backdrop: true, overview: false, imageType: 3, isMovie: widget.isMovie, allImages: widget.images,) : Container(),

            stills.isNotEmpty ? ImageScreen(images: stills.length < 10 ? stills : stills.sublist(0, 10), title: translate('Bilder'), buttonColor: Color(0xff540126), movieID: widget.movieID, backdrop: true, overview: false, imageType: 4, isMovie: widget.isMovie, allImages: widget.images,) : Container(),


          ]),
    ));
  }
}
