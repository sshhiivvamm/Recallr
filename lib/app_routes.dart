import 'package:go_router/go_router.dart';

import 'core/features/links/all_links.dart';
import 'core/features/view/re_addcategory.dart';
import 'core/features/view/re_category.dart';
import 'core/features/view/re_collections.dart';
import 'core/features/view/re_profile.dart';
import 'core/features/view/re_search.dart';
import 'core/features/view/recallr_home.dart';
import 'navigation/nav_file.dart';

class ReNav {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
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
          ),

          GoRoute(
            path: '/collections',
            name: 'collections',
            builder: (context, state) => const ReCollections(),
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
