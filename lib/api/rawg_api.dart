import 'dart:convert';
import 'package:http/http.dart' as http;

import '../widgets/singleton.dart';

class RawgApiService {
  static String apiKey = '02bc1c7ed97745508cde5a2a234f4cd7'; // Replace with your TMDB API key
  static String readAccToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyNGIzZjk5YWE0MjRmNjJlMmRkNTQ1MmI4M2FkMmU0MyIsInN1YiI6IjYzNjI3NmU5YTZhNGMxMDA4MmRhN2JiOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.fiB3ZZLqxCWYrIvehaJyw6c4LzzOFwlqoLh8Dw77SUw';


  static String getApiKey() {
    return apiKey;
  }

  static String getReadAccToken() {
    return readAccToken;
  }

  static Future<List<dynamic>> getMovieWatchList(String sessionId, int accountId) async {
String def = Singleton.defaultLanguage;
    final String apiUrl = 'https://api.themoviedb.org/3/account/$accountId/watchlist/movies?api_key=$apiKey&session_id=$sessionId&language=$def';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final movies = jsonDecode(response.body)['results'];
      return movies;
    } else {
      print('Failed to get watchlist: ${response.statusCode}');
      return [];
    }
  }

  static Future<List<dynamic>> getSeriesWatchList(String sessionId, int accountId) async {
    String def = Singleton.defaultLanguage;
    final url = Uri.parse('https://api.themoviedb.org/3/account/$accountId/watchlist/tv?api_key=$apiKey&session_id=$sessionId&language=$def');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedJson = json.decode(response.body);
      final series = decodedJson['results'];
      return series;
    } else {
      throw Exception('Failed to load watchlist series');
    }
  }


  static Future<List<dynamic>> getAccountRatedMovies(String sessionId) async {
    String def = Singleton.defaultLanguage;
    final String apiUrl = 'https://api.themoviedb.org/3/account/{account_id}/rated/movies?api_key=$apiKey&session_id=$sessionId&language=$def';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final movies = jsonDecode(response.body)['results'];
      return movies;
    } else {
      print('Failed to get rated movies: ${response.statusCode}');
      return [];
    }
  }


  static Future<List<dynamic>> getAccountRatedTVShows(String sessionId) async {
    String def = Singleton.defaultLanguage;
    final String apiUrl = 'https://api.themoviedb.org/3/account/{account_id}/rated/tv?api_key=$apiKey&session_id=$sessionId&language=$def';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final series = jsonDecode(response.body)['results'];
      return series;
    } else {
      print('Failed to get rated series: ${response.statusCode}');
      return [];
    }
  }

  static Future<String?> login(String username, String password) async {
    final String? token = await _getRequestToken();
    if (token != null) {
      final String? sessionId = await _validateTokenWithLogin(token, username, password);
      return sessionId;
    }
    return null;
  }

  static Future<String?> loginV4(String username, String password) async {
    final String? token = await _getRequestTokenV4();
    if (token != null) {
      final String? sessionId = await _validateTokenWithLogin(token, username, password);
      return sessionId;
    }
    return null;
  }

  static Future<String> getRequestTokenV4(String apiKey) async {
    String url = 'https://api.themoviedb.org/4/auth/request_token';
    Map<String, String> headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json;charset=utf-8',
    };

    http.Response response = await http.post(Uri.parse(url), headers: headers);
    Map<String, dynamic> json = jsonDecode(response.body);
    return json['request_token'];
  }

  static Future<String> generateAccessTokenV4(String apiKey, String requestToken) async {
    String url = 'https://api.themoviedb.org/4/auth/access_token';
    Map<String, String> headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json;charset=utf-8',
    };

    Map<String, dynamic> body = {
      'request_token': requestToken,
    };

    http.Response response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
    Map<String, dynamic> json = jsonDecode(response.body);
    return json['access_token'];
  }

  static Future<String?> _getRequestToken() async {
    final String apiUrl = 'https://api.themoviedb.org/3/authentication/token/new?api_key=$apiKey';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['request_token'];
      return token;
    } else {
      print('Failed to get request token: ${response.statusCode}');
      return null;
    }
  }

  static Future<String?> _getRequestTokenV4() async {
    final String apiUrl = 'https://api.themoviedb.org/4/auth/request_token';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['request_token'];
      return token;
    } else {
      print('Failed to get request token: ${response.statusCode}');
      return null;
    }
  }

  static Future<String?> _validateTokenWithLogin(String token, String username, String password) async {
    final String apiUrl = 'https://api.themoviedb.org/3/authentication/token/validate_with_login?api_key=$apiKey';
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final String body = jsonEncode({'username': username, 'password': password, 'request_token': token});
    final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);

    if (response.statusCode == 200) {
      final validatedToken = jsonDecode(response.body)['request_token'];
      final sessionId = await _createSession(validatedToken);
      return sessionId;
    } else {
      print('Failed to validate token with login: ${response.statusCode}');
      return null;
    }
  }

  static Future<String?> _createSession(String validatedToken) async {
    final String apiUrl = 'https://api.themoviedb.org/3/authentication/session/new?api_key=$apiKey';
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final String body = jsonEncode({'request_token': validatedToken});
    final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);

    if (response.statusCode == 200) {
      final sessionId = jsonDecode(response.body)['session_id'];
      return sessionId;
    } else {
      print('Failed to create session: ${response.statusCode}');
      return null;
    }
  }

  static Future<int?> getAccountId(String sessionId) async {
    final String apiUrl = 'https://api.themoviedb.org/3/account?api_key=$apiKey&session_id=$sessionId';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final accountData = jsonDecode(response.body);
      final int? accountId = accountData['id'];
      return accountId;
    } else {
      print('Failed to retrieve account ID: ${response.statusCode}');
      return null;
    }
  }
}
