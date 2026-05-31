import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/add_category_sheet.dart';
import '../../../theme/controller/theme_controller.dart';
import '../../../theme/recallr_colors.dart';

class ReProfile extends ConsumerWidget {
  const ReProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(
          "P R O F I L E ",
          style: Theme.of(context).textTheme.headlineLarge!,
        ),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.add),
            title: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddCategorySheet(),
                );
              },
              child: Text(
                "Add Category",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),

          InkWell(
            onTap: (){
              context.go('/categories');

            },
            child: ListTile(
              leading: Icon(Icons.newspaper),
              title: Text("Categories",
              style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          )
          // ,ListTile(
          //   leading: Icon(Icons.add),
          //   title: Text("Add Category",
          //   style: Theme.of(context).textTheme.bodySmall,
          //   ),
          // ),ListTile(
          //   leading: Icon(Icons.add),
          //   title: Text("Add Category",
          //   style: Theme.of(context).textTheme.bodyLarge,
          //   ),
          // ),ListTile(
          //   leading: Icon(Icons.add),
          //   title: Text("Add Category",
          //   style: Theme.of(context).textTheme.titleLarge,
          //   ),
          // ),ListTile(
          //   leading: Icon(Icons.add),
          //   title: Text("Add Category",
          //   style: Theme.of(context).textTheme.titleMedium,
          //   ),
          // ),ListTile(
          //   leading: Icon(Icons.add),
          //   title: Text("Add Category",
          //   style: Theme.of(context).textTheme.titleSmall,
          //   ),
          // ),ListTile(
          //   leading: Icon(Icons.add),
          //   title: Text("Add Category",
          //   style: Theme.of(context).textTheme.labelLarge,
          //   ),
          // ),ListTile(
          //   leading: Icon(Icons.add),
          //   title: Text("Add Category",
          //   style: Theme.of(context).textTheme.labelMedium,
          //   ),
          // ),
        ],
      ),
    );
  }
}
