import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';

import 'common/widgets.dart';
import 'core/features/links/all_links.dart';
import 'core/features/view/re_addcategory.dart';
import 'core/features/view/re_category.dart';
import 'core/features/view/re_collection_links.dart';
import 'core/features/view/re_collections.dart';
import 'core/features/view/re_filtered_links.dart';
import 'core/features/view/re_onboarding.dart';
import 'core/features/view/re_profile.dart';
import 'core/features/view/re_reader.dart';
import 'core/features/view/re_review.dart';
import 'core/features/view/re_search.dart';
import 'core/features/view/recallr_home.dart';
import 'data/models/collection_model.dart';
import 'main.dart' show pendingSharedUrl;
import 'navigation/nav_file.dart';
import 'theme/recallr_colors.dart';

// Set by main() before runApp — true if user has completed onboarding before.
bool onboardingDone = false;

class ReNav {
  static final GoRouter router = GoRouter(
    initialLocation: pendingSharedUrl != null ? '/share-intent' : '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Onboarding takes priority over everything except the share-intent route
      if (!onboardingDone && loc != '/onboarding' && loc != '/share-intent') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      // ── Share-intent entry point ─────────────────────────────────────────
      // Launched when the app is cold-started via an Android share action.
      // Shows the save sheet immediately on the first frame — no home-screen
      // flash — then navigates to '/' once the sheet is dismissed.
      GoRoute(
        path: '/share-intent',
        builder: (context, state) => const _ShareIntentPage(),
      ),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const ReOnboarding(),
      ),
      // In-app reader — opened with extra: {'url': '...', 'linkId': id}
      GoRoute(
        path: '/reader',
        name: 'reader',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ReReader(
            url:    extra['url'] as String,
            linkId: extra['linkId'] as int?,
          );
        },
      ),
      // Review queue — full-screen, no nav bar
      GoRoute(
        path: '/review',
        name: 'review',
        builder: (context, state) => const ReReview(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(child: child);
        },

        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const RecallrHome(),
            routes: [
              GoRoute(
                path: 'all-links',
                name: 'alllinks',
                builder: (context, state) => const AllLinksScreen(),
              ),
            ],
          ),

          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const ReSearch(),
          ),

          GoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) => const ReCategory(),
            routes: [
              GoRoute(
                path: 'filter',
                name: 'filteredLinks',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return ReFilteredLinks(
                    title:         extra['title'] as String,
                    color:         extra['color'] as Color,
                    icon:          extra['icon'] as IconData,
                    tagId:         extra['tagId'] as int?,
                    domainKeyword: extra['domainKeyword'] as String?,
                  );
                },
              ),
            ],
          ),

          GoRoute(
            path: '/collections',
            name: 'collections',
            builder: (context, state) => const ReCollections(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'collectionLinks',
                builder: (context, state) {
                  final folder = state.extra as FolderModel;
                  return ReCollectionLinks(folder: folder);
                },
              ),
            ],
          ),

          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ReProfile(),
            routes: [
              GoRoute(
                path: 'add-category',
                name: 'addCategory',
                builder: (context, state) => const ReAddcategory(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ── Share-intent page ─────────────────────────────────────────────────────────
// Lightweight entry route for cold-start share intents. Renders a branded
// background so the sheet has something clean behind it, opens the save sheet
// on the first frame, then hands off to home once the sheet closes.

class _ShareIntentPage extends StatefulWidget {
  const _ShareIntentPage();

  @override
  State<_ShareIntentPage> createState() => _ShareIntentPageState();
}

class _ShareIntentPageState extends State<_ShareIntentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final url = pendingSharedUrl;
      pendingSharedUrl = null;
      await ReWid.openSaveSheet(context, initialUrl: url);
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: context.colors.background);
  }
}
