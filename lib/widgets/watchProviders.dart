
import 'package:game_grove/Database/WatchProvider.dart';
import 'package:game_grove/utils/text.dart';
import 'package:game_grove/widgets/singleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:shimmer/shimmer.dart';

class WatchProvidersScreen extends StatefulWidget {
  final List<WatchProvider> watchProviders;
  final String selectedCountry;

  const WatchProvidersScreen(
      {Key? key, required this.watchProviders, required this.selectedCountry})
      : super(key: key);

  @override
  _WatchProvidersScreenState createState() => _WatchProvidersScreenState();
}

class _WatchProvidersScreenState extends State<WatchProvidersScreen> {
  String selectedCountry = "";
  bool isLoading = true; // Flag to track loading state

  List<WatchProvider> getFilteredWatchProviders() {
    if (selectedCountry.isEmpty) {
      return [];
    } else {
      return widget.watchProviders
          .where((provider) => provider.country == selectedCountry)
          .toList();
    }
  }

  List<String> countries = [];

  @override
  void initState() {
    super.initState();
    // Simulate loading delay
    setState(() {
      selectedCountry = widget.selectedCountry;
    });

    Future.delayed(Duration(milliseconds: 700), () {
      countries = widget.watchProviders
          .map((provider) => provider.country)
          .toSet()
          .toList();
      setState(() {
        isLoading = false; // Set loading flag to false once the data is loaded
        selectedCountry = countries.contains(selectedCountry)
            ? selectedCountry
            : countries.first;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a Set to remove duplicate countries

    final List<WatchProvider> filteredWatchProviders =
        getFilteredWatchProviders();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              mod_Text(text: 'Watch Providers', color: Colors.black, size: 22),
              Container(
                height: 50,
                padding: EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                // Add padding
                decoration: BoxDecoration(
                  color: Colors.yellow
                      .withOpacity(0.7),
                  borderRadius: BorderRadius.circular(
                      10), // Add rounded corn
                ),
                child: DropdownButton<String>(
                  value: countries.contains(selectedCountry)
                      ? selectedCountry
                      : countries.firstOrNull,
                  items: countries
                      .map((country) => DropdownMenuItem<String>(
                            value: country,
                            child: Text(country),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCountry = value!;
                    });
                  },
                  style: TextStyle(
                    color: Colors.black, // Change the text color
                    fontSize: 26, // Change the font size
                  ),
                  dropdownColor: Colors.yellow,
                  borderRadius: BorderRadius.circular(10),
                  // Change the dropdown menu background color
                  icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                  // Change the dropdown icon color
                  underline: Container(), // Remove the default underline
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          mod_Text(
              text: 'Provided by JustWatch', color: Colors.yellow, size: 18),
          const SizedBox(height: 10),
          if (selectedCountry.isNotEmpty) ...[
            if (isLoading) ...[
              _buildLoadingRow(translate('Flatrate')),
              _buildLoadingRow(translate('Kaufen')),
              _buildLoadingRow(translate('Leihen')),
            ] else ...[
              _buildWatchProvidersRow(
                  translate('Flatrate'),
                  filteredWatchProviders
                      .map((provider) => provider.flatrate)
                      .toList()),
              _buildWatchProvidersRow(
                  translate('Kaufen'),
                  filteredWatchProviders
                      .map((provider) => provider.buy)
                      .toList()),
              _buildWatchProvidersRow(
                  translate('Leihen'),
                  filteredWatchProviders
                      .map((provider) => provider.rent)
                      .toList()),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingRow(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        mod_Text(text: title, color: Colors.black, size: 16),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: 7, // Display 3 shimmer placeholders
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return _buildShimmerProviderItem();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerProviderItem() {
    return Shimmer.fromColors(
      baseColor: Colors.yellow[300]!,
      highlightColor: Colors.white54!,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 80, // Adjust the width as needed
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildWatchProvidersRow(
      String title, List<List<Map<String, dynamic>>> providersList) {
    final List<Map<String, dynamic>> providers =
        providersList.expand((element) => element).toList();

    if (providers.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        mod_Text(text: title, color: Colors.black, size: 16),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: providers.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final Map<String, dynamic> provider = providers[index];

              return InkWell(
                onTap: () {
                  // Handle item tap
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 80, // Adjust the width as needed
                  child: Column(
                    children: [
                      provider['logo_path'] != null
                          ? Flexible(
                              child: Container(
                                height: 80, // Adjust the height as needed
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        'https://image.tmdb.org/t/p/w500${provider['logo_path']}'),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      /*mod_Text(
                        text: provider['provider_name'] != null ? provider['provider_name'] : 'Loading',
                        color: Colors.white,
                        size: 9, // Adjust the font size as needed
                      ),*/
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
