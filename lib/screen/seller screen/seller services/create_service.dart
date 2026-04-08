import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/seller_service_management.dart';
import 'package:nb_utils/nb_utils.dart';

import '../seller home/my service/service_details.dart';
import 'create_new_service.dart';

class CreateService extends StatefulWidget {
  const CreateService({Key? key}) : super(key: key);

  @override
  State<CreateService> createState() => _CreateServiceState();
}

class _CreateServiceState extends State<CreateService> {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: Text('Create Service', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateNewService()));
            _loadServices();
          },
          backgroundColor: kPrimaryColor,
          child: const Icon(FeatherIcons.plus, color: kWhite),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
          width: context.width(),
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _services.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 213, width: 269,
                          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('images/emptyservice.png'), fit: BoxFit.cover)),
                        ),
                        const SizedBox(height: 20.0),
                        Text('Empty Service', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 24.0)),
                      ],
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 15.0, bottom: 80.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 10.0, crossAxisSpacing: 10.0, childAspectRatio: 0.8,
                      ),
                      itemCount: _services.length,
                      itemBuilder: (_, i) {
                        final service = _services[i];
                        final images = service['images'] as List<dynamic>?;
                        final imageUrl = (images != null && images.isNotEmpty) ? images[0] : null;

                        return GestureDetector(
                          onTap: () async {
                            await ServiceDetails(serviceId: service['id']).launch(context);
                            _loadServices();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: kBorderColorTextField),
                              boxShadow: const [BoxShadow(color: kDarkWhite, blurRadius: 5.0, spreadRadius: 2.0, offset: Offset(0, 5))],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(topRight: Radius.circular(8.0), topLeft: Radius.circular(8.0)),
                                    image: DecorationImage(
                                      image: imageUrl != null ? NetworkImage(imageUrl) as ImageProvider : const AssetImage('images/shot1.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(service['title'] ?? 'Service', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 5.0),
                                      Row(
                                        children: [
                                          const Icon(IconlyBold.star, color: Colors.amber, size: 18.0),
                                          const SizedBox(width: 2.0),
                                          Text('${service['rating'] ?? 0}', style: kTextStyle.copyWith(color: kNeutralColor)),
                                          const SizedBox(width: 2.0),
                                          Flexible(child: Text('(${service['review_count'] ?? 0})', style: kTextStyle.copyWith(color: kLightNeutralColor), overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                      const SizedBox(height: 5.0),
                                      RichText(
                                        text: TextSpan(text: 'Price: ', style: kTextStyle.copyWith(color: kLightNeutralColor), children: [
                                          TextSpan(text: '$currencySign${service['price'] ?? 0}', style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                                        ]),
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
    );
  }
}
