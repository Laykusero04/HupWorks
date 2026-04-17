import 'package:freelancer/screen/widgets/data.dart';

// Global flags (to be replaced by BLoC state in Phase 6)
bool isClient = false;
bool isFreelancer = false;
bool isFavorite = false;
const String currencySign = '\$';

//__________Gender______________________________________________________
const List<String> gender = ['Male', 'Female'];
String selectedGender = 'Male';

const List<String> catName = ['Graphics Design', 'Video Editing', 'Digital Marketing', 'Business', 'Writing & Translation', 'Programming', 'Lifestyle'];
const List<String> catIcon = ['images/graphic.png', 'images/videoicon.png', 'images/dm.png', 'images/b.png', 'images/t.png', 'images/p.png', 'images/l.png'];

//__________Language____________________________________________________
const List<String> language = ['English', 'Bengali'];
String selectedLanguage = 'English';

const List<String> languageLevel = ['Fluent', 'Weak'];
String selectedLanguageLevel = 'Fluent';

//__________Skill Level_________________________________________________
const List<String> skillLevel = ['Expert', 'Fresher'];
String selectedSkillLevel = 'Expert';

//__________Periods_____________________________________________________
const List<String> period = ['Last Month', 'This Month'];
String selectedPeriod = 'Last Month';

const List<String> staticsPeriod = ['Last Month', 'This Month'];
String selectedStaticsPeriod = 'Last Month';

const List<String> earningPeriod = ['Last Month', 'This Month'];
String selectedEarningPeriod = 'Last Month';

Map<String, double> dataMap = {
  "Impressions": 5,
  "Interaction": 3,
  "Reached-Out": 2,
};

//__________Category____________________________________________________
const List<String> category = ['Digital Marketing', 'App Development', 'Graphics Design'];
String selectedCategory = 'App Development';

const List<String> subcategory = ['Flutter', 'React Native', 'Java'];
String selectedSubCategory = 'Flutter';

//__________Service Type________________________________________________
const List<String> serviceType = ['Online', 'Offline'];
String selectedServiceType = 'Online';

//__________Delivery Time_______________________________________________
const List<String> deliveryTime = ['3 days', '5 days', '7 days', '12 days', '15 days', '20 days'];
String selectedDeliveryTime = '3 days';

const List<String> pageCount = ['10 screen', '15 days', '20 days'];
String selectedPageCount = '10 screen';

List<TitleModel> list = [
  TitleModel("Responsive design", false),
  TitleModel("Prototype", false),
  TitleModel("Source file", false),
];

List<TitleModel> selectedTitle = [];

const List<String> titleList = ['Active', 'Pending', 'Completed', 'Cancelled'];
String isSelected = 'Active';

const List<String> deliveryTimeList = ['3 days', '5 days', '7 days', '12 days', '15 days', '20 days'];
String selectedDeliveryTimeList = '3 days';

const List<String> revisionTime = ['1 time', '2 time', '3 time', '4 time'];
String selectedRevisionTime = '1 time';

const List<String> reportTitle = ['Non original content', 'Trademark Violations', 'Copyright Violations', 'Other reasons'];
String selectedReportTitle = 'Non original content';

const List<String> gateWay = ['PayPal', 'Credit Card', 'Bkash'];
String selectedGateWay = 'PayPal';

const List<String> currency = ['USD', 'BDT'];
String selectedCurrency = 'USD';
