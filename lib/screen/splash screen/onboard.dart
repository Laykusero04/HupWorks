import 'package:flutter/material.dart';
import 'package:freelancer/core/locale/locale_controller.dart';
import 'package:freelancer/core/locale/locale_scope.dart';
import 'package:freelancer/core/onboarding/onboarding_prefs.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoard extends StatefulWidget {
  const OnBoard({super.key});

  @override
  State<OnBoard> createState() => _OnBoardState();
}

class _OnBoardState extends State<OnBoard> {
  final _pageController = PageController();
  int _index = 0;

  static const _contentPageCount = 3;
  static const _pageCount = _contentPageCount + 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingPrefs.markSeen();
    if (!mounted) return;
    context.go('/welcome');
  }

  void _next() {
    if (_index >= _pageCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  List<_OnboardPageData> _contentPages(AppLocalizations l10n) => [
        _OnboardPageData(
          image: AppInfo.onBoard1,
          title: l10n.appOnboardPage1Title,
          body: l10n.appOnboardPage1Body,
          accent: kPrimaryColor,
        ),
        _OnboardPageData(
          image: AppInfo.onBoard2,
          title: l10n.appOnboardPage2Title,
          body: l10n.appOnboardPage2Body,
          accent: kSecondaryColor,
        ),
        _OnboardPageData(
          image: AppInfo.onBoard3,
          title: l10n.appOnboardPage3Title,
          body: l10n.appOnboardPage3Body,
          accent: kPrimaryColor,
        ),
      ];

  Color _accentForIndex(List<_OnboardPageData> pages) {
    if (_index == 0) return kPrimaryColor;
    return pages[_index - 1].accent;
  }

  Widget _buildLanguagePage(LocaleController localeController) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final l10n = context.l10n;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Icon(
                Icons.language_rounded,
                size: 72,
                color: kPrimaryColor.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.appOnboardLanguageTitle,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appOnboardLanguageSubtitle,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              for (final option in LocaleController.languageOptionEntries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LanguageOptionTile(
                    label: option.nativeLabel,
                    selected: localeController.isSelected(option.locale),
                    onTap: () => localeController.setLocale(option.locale),
                  ),
                ),
              const Spacer(flex: 2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentPage(_OnboardPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Image.asset(
            page.image,
            height: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 36),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: kTextStyle.copyWith(
              color: kSubTitleColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeController = LocaleScope.of(context);
    final l10n = context.l10n;
    final pages = _contentPages(l10n);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isLast = _index >= _pageCount - 1;
    final accent = _accentForIndex(pages);

    return Scaffold(
      backgroundColor: kDarkWhite,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  foregroundColor: kSubTitleColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  l10n.appOnboardSkip,
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _buildLanguagePage(localeController);
                  }
                  return _buildContentPage(pages[i - 1]);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pageCount,
                    effect: ExpandingDotsEffect(
                      dotHeight: 7,
                      dotWidth: 7,
                      expansionFactor: 3.2,
                      spacing: 8,
                      activeDotColor: accent,
                      dotColor: accent.withValues(alpha: 0.22),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: isLast
                        ? l10n.appOnboardGetStarted
                        : l10n.appOnboardNext,
                    onPressed: _next,
                    accentColor: accent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? kPrimaryColor.withValues(alpha: 0.1) : kWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kPrimaryColor : kBorderColorTextField,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: kPrimaryColor,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPageData {
  const _OnboardPageData({
    required this.image,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String image;
  final String title;
  final String body;
  final Color accent;
}
