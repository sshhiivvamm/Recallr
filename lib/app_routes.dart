import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';

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
import 'navigation/nav_file.dart';

// Set by main() before runApp — true if user has completed onboarding before.
bool onboardingDone = false;

class ReNav {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (!onboardingDone && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
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
