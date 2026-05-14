import 'package:freelancer/core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobPostsService {
  static final _client = Supabase.instance.client;

  /// Stored in `workers_needed` when the client does not set a cap (DB requires int ≥ 1).
  static const int workersNeededNoLimitSentinel = 999;

  /// How [budget_min] / [budget_max] should be read (`job_posts.budget_basis`).
  static const String budgetBasisFixed = 'fixed';
  static const String budgetBasisPerHour = 'per_hour';
  static const String budgetBasisPerDay = 'per_day';
  static const String budgetBasisPerMonth = 'per_month';

  static String normalizeBudgetBasis(Object? raw) {
    final s = raw?.toString().toLowerCase().trim() ?? '';
    if (s == budgetBasisPerHour) return budgetBasisPerHour;
    if (s == budgetBasisPerDay) return budgetBasisPerDay;
    if (s == budgetBasisPerMonth) return budgetBasisPerMonth;
    return budgetBasisFixed;
  }

  static double? _parseMoney(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _formatMoneyAmount(double v) {
    if (v == v.roundToDouble()) return '$currencySign${v.toInt()}';
    return '$currencySign${v.toStringAsFixed(1)}';
  }

  /// Detail / row text, e.g. "€10 – €50 per hour" or "€500 (fixed project)".
  static String formatBudgetRange(Object? min, Object? max, Object? basis) {
    final mn = _parseMoney(min);
    final mx = _parseMoney(max);
    if (mn == null && mx == null) return '';
    final lo = mn ?? 0.0;
    final hi = mx ?? lo;
    final a = _formatMoneyAmount(lo);
    final b = _formatMoneyAmount(hi);
    final range = (lo - hi).abs() < 0.0001 ? a : '$a – $b';
    switch (normalizeBudgetBasis(basis)) {
      case budgetBasisPerHour:
        return '$range per hour';
      case budgetBasisPerDay:
        return '$range per day';
      case budgetBasisPerMonth:
        return '$range per month';
      default:
        return '$range (fixed project)';
    }
  }

  /// Shorter line for list cards, e.g. "€10–€50/hr".
  static String formatBudgetRangeShort(Object? min, Object? max, Object? basis) {
    final mn = _parseMoney(min);
    final mx = _parseMoney(max);
    if (mn == null && mx == null) return '';
    final lo = mn ?? 0.0;
    final hi = mx ?? lo;
    final a = _formatMoneyAmount(lo);
    final b = _formatMoneyAmount(hi);
    final range = (lo - hi).abs() < 0.0001 ? a : '$a–$b';
    switch (normalizeBudgetBasis(basis)) {
      case budgetBasisPerHour:
        return '$range/hr';
      case budgetBasisPerDay:
        return '$range/day';
      case budgetBasisPerMonth:
        return '$range/mo';
      default:
        return range;
    }
  }

  /// Single seller offer amount (`job_offers.price` + `price_basis`).
  static String formatOfferAmountLine(Object? priceRaw, Object? basis) {
    final p = _parseMoney(priceRaw) ?? 0;
    final s = _formatMoneyAmount(p);
    switch (normalizeBudgetBasis(basis)) {
      case budgetBasisPerHour:
        return '$s per hour';
      case budgetBasisPerDay:
        return '$s per day';
      case budgetBasisPerMonth:
        return '$s per month';
      default:
        return '$s (fixed total)';
    }
  }

  /// Compact for chips / lists, e.g. "€40/hr" or "€500 total".
  static String formatOfferAmountShort(Object? priceRaw, Object? basis) {
    final p = _parseMoney(priceRaw) ?? 0;
    final s = _formatMoneyAmount(p);
    switch (normalizeBudgetBasis(basis)) {
      case budgetBasisPerHour:
        return '$s/hr';
      case budgetBasisPerDay:
        return '$s/day';
      case budgetBasisPerMonth:
        return '$s/mo';
      default:
        return '$s total';
    }
  }

  static int parseWorkersNeeded(Object? raw) {
    if (raw == null) return 1;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw.toString()) ?? 1;
  }

  /// Short label for detail rows (e.g. job details screen).
  static String workersNeededDetailLabel(Object? raw) {
    final n = parseWorkersNeeded(raw);
    if (n >= workersNeededNoLimitSentinel) return 'No set limit';
    return '$n';
  }

  /// One-line text for list cards when [workersNeededShowOnCard] is true.
  static String workersNeededCardLine(Object? raw) {
    final n = parseWorkersNeeded(raw);
    if (n >= workersNeededNoLimitSentinel) return 'Open hiring — no set limit';
    return '$n workers needed';
  }

  static bool workersNeededShowOnCard(Object? raw) {
    final n = parseWorkersNeeded(raw);
    return n > 1 || n >= workersNeededNoLimitSentinel;
  }

  /// `workers_needed` at or above [workersNeededNoLimitSentinel] means no hiring cap.
  static bool workersNeededIsUnlimited(Object? raw) {
    return parseWorkersNeeded(raw) >= workersNeededNoLimitSentinel;
  }

  static int countAcceptedOffers(Iterable<Map<String, dynamic>> offers) {
    var n = 0;
    for (final o in offers) {
      if ((((o['status'] as String?) ?? '').toLowerCase()) == 'accepted') n++;
    }
    return n;
  }

  /// Whether hiring this applicant reaches the finite cap (server closes the job only; no auto-reject).
  static bool acceptingFillsAllSlots(Object? workersNeededRaw, int currentAcceptedCount) {
    if (workersNeededIsUnlimited(workersNeededRaw)) return false;
    final cap = parseWorkersNeeded(workersNeededRaw);
    return currentAcceptedCount + 1 >= cap;
  }

  /// Fetch client's job posts
  static Future<List<Map<String, dynamic>>> getClientJobPosts() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('job_posts')
        .select('*, categories(name)')
        .eq('client_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Create a new job post
  static Future<Map<String, dynamic>> createJobPost({
    required String title,
    required String description,
    String? categoryId,
    double? budgetMin,
    double? budgetMax,
    String budgetBasis = budgetBasisFixed,
    DateTime? deadline,
    String jobType = 'gig',
    String? location,
    int workersNeeded = 1,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final data = await _client.from('job_posts').insert({
      'client_id': user.id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'budget_basis': normalizeBudgetBasis(budgetBasis),
      'deadline': deadline?.toIso8601String(),
      'status': 'open',
      'job_type': jobType,
      'location': location,
        'workers_needed': workersNeeded,
    }).select().single();

    return data;
  }

  /// Fetch single job post details
  static Future<Map<String, dynamic>> getJobPostDetails(String jobPostId) async {
    final data = await _client
        .from('job_posts')
        .select('*, categories(name)')
        .eq('id', jobPostId)
        .single();
    return data;
  }

  /// Fetch seller offers on a job post
  static Future<List<Map<String, dynamic>>> getJobOffers(String jobPostId) async {
    final data = await _client
        .from('job_offers')
        .select('*, profiles:seller_id(name, profile_image_url, rating)')
        .eq('job_post_id', jobPostId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Accept or reject an offer.
  /// For "accepted" prefer [acceptJobOffer], which atomically also creates
  /// the contract and closes the job post.
  static Future<void> updateOfferStatus(String offerId, String status) async {
    await _client.from('job_offers').update({'status': status}).eq('id', offerId);
  }

  /// Accept an application atomically: marks the offer accepted, rejects
  /// other pending offers on the same job, closes the job post, and creates
  /// the contract (orders row). Returns the new order id.
  static Future<String> acceptJobOffer(String offerId) async {
    final result = await _client.rpc(
      'accept_job_offer',
      params: {'p_offer_id': offerId},
    );
    return result.toString();
  }

  /// Close a job post
  static Future<void> closeJobPost(String jobPostId) async {
    await _client.from('job_posts').update({'status': 'closed'}).eq('id', jobPostId);
  }

  /// Fetch categories for dropdown
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await _client.from('categories').select('id, name').order('name');
    return List<Map<String, dynamic>>.from(data);
  }
}
