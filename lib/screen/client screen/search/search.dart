import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/constant.dart';

class CustomSearchDelegate extends SearchDelegate {
  List<String> searchItems = [
    'UI UX Designer',
    'Logo designer',
    'App developer',
    'Designer',
  ];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear, color: kNeutralColor),
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      color: kNeutralColor,
      onPressed: () => close(context, null),
      icon: const Icon(
        Icons.arrow_back,
        color: kNeutralColor,
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<String> matchQuery = [];
    for (var car in searchItems) {
      if (car.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(car);
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: matchQuery.length,
      itemBuilder: (_, i) {
        var result = matchQuery[i];
        return ListTile(
          title: Text(result),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var car in searchItems) {
      if (car.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(car);
      }
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: matchQuery.length,
      itemBuilder: (_, i) {
        return Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10),
          child: Row(
            children: [
              Text(
                matchQuery[i].toString(),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  query = '';
                  showSuggestions(context);
                },
                icon: const Icon(Icons.clear, color: kNeutralColor),
              )
            ],
          ),
        );
      },
    );
  }
}
