import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';

import '../../widgets/constant.dart';

/// Client favourites are not supported (sellers save jobs only).
/// Kept as a lightweight placeholder if an old route still opens it.
class ClientFavList extends StatelessWidget {
  const ClientFavList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.favouriteList,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          l10n.noFavouritesYet,
          style: kTextStyle.copyWith(color: kLightNeutralColor),
        ),
      ),
    );
  }
}
