import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/seller%20screen/seller%20home/my%20service/service_details.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/seller_service_management.dart';
import 'package:nb_utils/nb_utils.dart';

class MyServices extends StatefulWidget {
  const MyServices({Key? key}) : super(key: key);

  @override
  State<MyServices> createState() => _MyServicesState();
}

class _MyServicesState extends State<MyServices> {
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final services = await SellerServiceManagement.getMyServices();
      if (mounted) {
        setState(() {
          _services = services;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: kDarkWhite,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'My Services',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _services.isEmpty
              ? Center(child: Text('No services yet', style: kTextStyle.copyWith(color: kLightNeutralColor)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: const BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30.0),
                              topRight: Radius.circular(30.0),
                            ),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10.0,
                              crossAxisSpacing: 10.0,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _services.length,
                            itemBuilder: (_, i) {
                              final service = _services[i];
                              final images = service['images'] as List<dynamic>?;
                              final imageUrl = (images != null && images.isNotEmpty) ? images[0] : null;
                              final isPaused = service['status'] == 'paused';

                              return GestureDetector(
                                onTap: () async {
                                  await ServiceDetails(serviceId: service['id']).launch(context);
                                  _loadServices();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: kBorderColorTextField),
                                    boxShadow: const [
                                      BoxShadow(color: kDarkWhite, blurRadius: 5.0, spreadRadius: 2.0, offset: Offset(0, 5)),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          Container(
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.only(
                                                topRight: Radius.circular(8.0),
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
                                          if (isPaused)
                                            Container(
                                              margin: const EdgeInsets.all(5),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text('Paused', style: kTextStyle.copyWith(color: kWhite, fontSize: 10)),
                                            ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                                Flexible(
                                                  child: Text(
                                                    '(${service['review_count'] ?? 0})',
                                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5.0),
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
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
