import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';

class FluidPage extends StatelessWidget {
  final String sessionId;

  FluidPage({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return Future.value(false);
      },
      child: LiquidTabBar(),
    );
  }


}
