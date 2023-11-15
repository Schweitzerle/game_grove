import 'dart:ui';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:game_grove/screens/FluidTabBarScreen.dart';
import 'package:game_grove/screens/splash_screen.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Database/user.dart';
import 'api/rawg_api.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();
  Singleton.initDefaultLanguageAndCountry();
  Singleton.initIsGuest();
  var delegate = await LocalizationDelegate.create(
      fallbackLocale: 'en', supportedLocales: ['de', 'en']);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    LocalizedApp(
      delegate,
      GetMaterialApp(
        title: 'CouchCinema',
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    ),
  );
}

class CouchCinemaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('selectedLanguage')),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          String? selectedLanguage = snapshot.data;
          var localizationDelegate = LocalizedApp.of(context).delegate;
          if (selectedLanguage != null) {
            localizationDelegate.changeLocale(Locale(selectedLanguage));
          }

          return LocalizationProvider(
            state: LocalizationProvider.of(context).state,
            child: MaterialApp(
              title: 'CouchCinema',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                localizationDelegate,
              ],
              supportedLocales: localizationDelegate.supportedLocales,
              locale: localizationDelegate.currentLocale,
              home: MyHomePage(),
            ),
          );
        }

        return Container(); // Placeholder while waiting for the future to complete.
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoggedIn = false;
  String? sessionId;

  @override
  void initState() {
    super.initState();
    checkIfLoggedIn();
  }

  Future<void> checkIfLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      sessionId = prefs.getString('sessionId');
    });
    if (sessionId != null) {
      setState(() {
        _isLoggedIn = true;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = true;
    return Scaffold(
      body: _isLoggedIn ? FluidPage(sessionId: sessionId!) : LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final database = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Singleton.secondTabColor,
              Singleton.fourthTabColor,
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  color: Colors.white.withGreen(200),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AutofillGroup(
                            child: Column(
                              children: [
                                TextField(
                                  controller: _usernameController,
                                  autofillHints: [AutofillHints.username],
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.person),
                                    prefixIconColor: Singleton.secondTabColor,
                                    labelText: translate("Benutzername"),
                                    labelStyle: TextStyle(
                                        color: Singleton.secondTabColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0)),
                                      borderSide: BorderSide(
                                        color: Singleton.thirdTabColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      gapPadding: 20,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10.0)),
                                      borderSide: BorderSide(
                                          color: Singleton.firstTabColor),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                  obscureText: true,
                                  controller: _passwordController,
                                  autofillHints: [AutofillHints.password],
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock_open_rounded),
                                    prefixIconColor: Singleton.secondTabColor,
                                    labelText: translate("Passwort"),
                                    labelStyle: TextStyle(
                                        color: Singleton.secondTabColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0)),
                                      borderSide: BorderSide(
                                        color: Singleton.thirdTabColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      gapPadding: 20,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10.0)),
                                      borderSide: BorderSide(
                                          color: Singleton.firstTabColor),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                        SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                          children: [
                            // Forgotten password
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final Uri url = Uri.parse(
                                    'https://www.themoviedb.org/reset-password?language=de');
                                if (!await launchUrl(url)) {
                                  throw Exception(
                                      'Could not launch $url');
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Singleton.thirdTabColor
                                      .withOpacity(0.6),
                                  // Add this line (light grey color)
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  translate('Passwort vergessen'),
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Create new account
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final Uri url = Uri.parse(
                                    'https://www.themoviedb.org/signup');
                                if (!await launchUrl(url)) {
                                  throw Exception(
                                      'Could not launch $url');
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Singleton.thirdTabColor
                                      .withOpacity(0.6),
                                  // Add this line (light grey color)
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  translate('Bei TMDb registrieren'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    // Adjust text color
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            children: [
                              Text(
                                translate('Login Info'),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              InkWell(
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  String? sessionId =
                                  await RawgApiService.login(
                                    _usernameController.text,
                                    _passwordController.text,
                                  );
                                  if (sessionId != null) {
                                    int _accountId =
                                    (await RawgApiService.getAccountId(
                                        sessionId))!;
                                    try {
                                      final userSnapshot = await database
                                          .child('users')
                                          .orderByChild('accountId')
                                          .equalTo(_accountId)
                                          .once();

                                      if (userSnapshot.snapshot.exists) {
                                        print('User already exists');
                                      } else {
                                        // Create a new user entry in the database
                                        final newUser = AppUser(
                                            accountId: _accountId,
                                            sessionId: sessionId);
                                        final newUserRef = database
                                            .child('users')
                                            .child(_accountId.toString());
                                        await newUserRef.set(newUser.toMap());
                                        print('New user created successfully');
                                      }
                                    } catch (error) {
                                      print('Error storing data: $error');
                                    }
                                    saveSessionId(sessionId, _accountId);
                                    Singleton.setIsGuest(false);
                                    registerWithEmailAndPassword(
                                        _usernameController.text,
                                        _passwordController.text);

                                    TextInput.finishAutofillContext();

                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => FluidPage(
                                          sessionId: sessionId,
                                        ),
                                      ),
                                    );
                                    final snackBar = SnackBar(
                                      /// need to set following properties for best effect of awesome_snackbar_content
                                      elevation: 20,
                                      behavior: SnackBarBehavior.fixed,
                                      backgroundColor: Colors.transparent,
                                      content: AwesomeSnackbarContent(
                                        title: translate('Spitze'),
                                        message: translate('Login Erfolg'),

                                        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                        contentType: ContentType.failure,
                                        color: Singleton.fifthTabColor,
                                      ),
                                    );

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(snackBar);
                                  } else {
                                    final snackBar = SnackBar(
                                      /// need to set following properties for best effect of awesome_snackbar_content
                                      elevation: 20,
                                      behavior: SnackBarBehavior.fixed,
                                      backgroundColor: Colors.transparent,
                                      content: AwesomeSnackbarContent(
                                        title: translate('Schade'),
                                        message: translate('Login Fehler'),

                                        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                        contentType: ContentType.failure,
                                        color: Singleton.fifthTabColor,
                                      ),
                                    );

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(snackBar);
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  // Adjust as needed
                                  width: 200,
                                  // Adjust as needed
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Singleton.thirdTabColor, // Change the color as needed
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    translate('Einloggen'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                translate('Gäste Login Info'),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              InkWell(
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  String? sessionId = await Singleton
                                      .tmdbWithCustLogs.v3.auth
                                      .createGuestSession();
                                  if (sessionId != null) {
                                    saveSessionId(sessionId, -18);
                                    Singleton.setIsGuest(true);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FluidPage(
                                          sessionId: sessionId,
                                        ),
                                      ),
                                    );
                                    final snackBar = SnackBar(
                                      /// need to set following properties for best effect of awesome_snackbar_content
                                      elevation: 20,
                                      behavior: SnackBarBehavior.fixed,
                                      backgroundColor: Colors.transparent,
                                      content: AwesomeSnackbarContent(
                                        title: translate('Spitze'),
                                        message: translate('Login Erfolg'),

                                        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                        contentType: ContentType.failure,
                                        color: Singleton.fifthTabColor,
                                      ),
                                    );

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(snackBar);
                                  } else {
                                    final snackBar = SnackBar(
                                      /// need to set following properties for best effect of awesome_snackbar_content
                                      elevation: 20,
                                      behavior: SnackBarBehavior.fixed,
                                      backgroundColor: Colors.transparent,
                                      content: AwesomeSnackbarContent(
                                        title: translate('Schade'),
                                        message: translate('Login Fehler'),

                                        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                        contentType: ContentType.failure,
                                        color: Singleton.fifthTabColor,
                                      ),
                                    );

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(snackBar);
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  // Adjust as needed
                                  width: 200,
                                  // Adjust as needed
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Singleton.thirdTabColor, // Change the color as needed
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    translate('Gäste Login'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
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
  }


  void saveSessionId(String sessionId, int accountId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('sessionId', sessionId);
    prefs.setInt('accountId', accountId);
  }
}

void registerWithEmailAndPassword(String email, String password) async {
  email = email.trim();

  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: '$email@couchcinema.com',
      password: password,
    );
    User? user = userCredential.user;
    print(user?.email);

    if (user != null) {
      print('User ID: ${user.uid}');
    } else {
      print('Registration failed');
    }
  } catch (e) {
    print('Error: $e');
  }
  FirebaseAuth.instance.signInWithEmailAndPassword(
      email: '$email@couchcinema.com', password: password);
}

Future<void> launchUrlFunction(Uri url) async {
  if (await canLaunch(url.toString())) {
    await launch(url.toString());
  } else {
    throw 'Could not launch $url';
  }
}
