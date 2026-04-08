import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/services/dashboard_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../client service details/client_service_details.dart';

class ClientFavList extends StatefulWidget {
  const ClientFavList({Key? key}) : super(key: key);

  @override
  State<ClientFavList> createState() => _ClientFavListState();
}

class _ClientFavListState extends State<ClientFavList> {
  List<Map<String, dynamic>> _favourites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    try {
      final favs = await DashboardService.getFavourites();
      if (mounted) {
        setState(() {
          _favourites = favs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleRemoveFavourite(String favId, int index) async {
    try {
      await DashboardService.removeFavourite(favId);
      if (mounted) {
        setState(() => _favourites.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favourites')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Favorite List',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _favourites.isEmpty
                  ? Center(
                      child: Text('No favourites yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                    )
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _loadFavourites,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                        itemCount: _favourites.length,
                        itemBuilder: (_, i) {
                          final fav = _favourites[i];
                          final service = fav['services'] as Map<String, dynamic>?;
                          if (service == null) return const SizedBox();

                          final seller = service['profiles'] as Map<String, dynamic>?;
                          final images = service['images'] as List<dynamic>?;
                          final imageUrl = (images != null && images.isNotEmpty) ? images[0] : null;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: GestureDetector(
                              onTap: () {
                                ClientServiceDetails(serviceId: service['id']).launch(context);
                              },
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: kBorderColorTextField),
                                  boxShadow: const [
                                    BoxShadow(color: kDarkWhite, blurRadius: 5.0, spreadRadius: 2.0, offset: Offset(0, 5)),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      alignment: Alignment.topLeft,
                                      children: [
                                        Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(8.0),
                                              topLeft: Radius.circular(8.0),
                                            ),
                                            image: DecorationImage(
                                              image: imageUrl != null
                                                  ? NetworkImage(imageUrl) as ImageProvider
                                                  : const AssetImage('images/shot1.png'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _handleRemoveFavourite(fav['id'], i),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Container(
                                              height: 25,
                                              width: 25,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black12, blurRadius: 10.0, spreadRadius: 1.0, offset: Offset(0, 2)),
                                                ],
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.favorite, color: Colors.red, size: 16.0),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              service['title'] ?? 'Service',
                                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5.0),
                                            Row(
                                              children: [
                                                const Icon(IconlyBold.star, color: Colors.amber, size: 18.0),
                                                const SizedBox(width: 2.0),
                                                Text('${service['rating'] ?? 0}', style: kTextStyle.copyWith(color: kNeutralColor)),
                                                const SizedBox(width: 2.0),
                                                Text('(${service['review_count'] ?? 0})', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                                const SizedBox(width: 20),
                                                RichText(
                                                  text: TextSpan(
                                                    text: 'Price: ',
                                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                    children: [
                                                      TextSpan(
                                                        text: '$currencySign${service['price'] ?? 0}',
                                                        style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5.0),
                                            Row(
                                              children: [
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    image: DecorationImage(
                                                      image: seller?['profile_image_url'] != null
                                                          ? NetworkImage(seller!['profile_image_url']) as ImageProvider
                                                          : const AssetImage('images/profilepic2.png'),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5.0),
                                                Text(
                                                  seller?['name'] ?? 'Seller',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
      ),
    );
  }
}
