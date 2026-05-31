// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../../../data/models/Tag/tag_model.dart';
// import '../../../theme/controller/theme_controller.dart';
// import '../../../theme/recallr_colors.dart';
// import '../../../theme/ui_helpers.dart';
// import '../category/tag_list_provider.dart';

//
// class ReCategory extends ConsumerWidget {
//   const ReCategory({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     IconData getIcon(String? name) {
//       switch (name) {
//         case "code":
//           return Icons.code;
//         case "study":
//           return Icons.school;
//         case "design":
//           return Icons.design_services;
//         default:
//           return Icons.folder;
//       }
//     }
//
//     final c = context.colors;
//     final txtTheme = Theme
//         .of(context)
//         .textTheme;
//     final themeMode = ref.watch(themeProvider);
//     final tagsAsync = ref.watch(tagListProvider);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Categories")),
//
//       body: tagsAsync.when(
//         data: (tags) {
//           if (tags.isEmpty) {
//             return const Center(child: Text("No categories yet"));
//           }
//
//           return Padding(
//             padding: const EdgeInsets.all(22.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "L I B R A R Y",
//                   style: txtTheme.titleLarge!.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: c.accent,
//                   ),
//                 ),
//                 Ui.gap8,
//                 Text(
//                   "Categories",
//                   style: txtTheme.displayLarge!.copyWith(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 42,
//                   ),
//                 ),
//                 Ui.gap(12),
//
//                 Container(
//                   height: 4,
//                   width: 110,
//
//                   decoration: BoxDecoration(
//                     color: c.accent,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//
//                 Ui.gap(12),
//
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: tags.length,
//                     itemBuilder: (context, index) {
//                       final TagModel tag = tags[index];
//                       final linkCount = tag.links.length;
//                       final icon = tag.icon != null ? tag.icon! : Icons.folder;
//
//                       print(icon);
//
//                       return _CategoryCard(
//                         tag: tag,
//                         color: c.accent,
//                         icon: getIcon(tag.icon),
//                         linkCount: linkCount,
//                         theme: txtTheme,
//                         onDelete: () async {
//                           final confirm = await showDialog(
//                             context: context, builder: (_) =>
//                               AlertDialog(
//                                 title: Text("Delete Category"),
//                                 content: Text(
//                                     "Are you sure you want to delete '${tag
//                                         .name}'? "
//                                         "All links will remain, but this category will be removed from them."
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () =>
//                                         Navigator.pop(context, false),
//                                     child: Text("Cancel"),
//                                   ),
//                                   TextButton(
//                                     onPressed: () =>
//                                         Navigator.pop(context, true),
//                                     child: Text("Delete",
//                                         style: TextStyle(color: Colors.red)),
//                                   ),
//                                 ],
//                               ),
//                           );
//
//                           if (confirm == true) {
//                             final isar = await ref.read(isarProvider.future);
//
//                             await isar.writeTxn(() async {
//                               // Remove this tag from all linked links
//                               for (final link in tag.links) {
//                                 link.tags.remove(tag);
//                                 await link.tags.save();
//                               }
//
//                               // Delete the tag itself
//                               await isar.tagModels.delete(tag.id);
//                             });
//
//                             // Refresh provider to update UI
//                             ref.invalidate(tagListProvider);
//
//
//
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//
//         loading: () => const Center(child: CircularProgressIndicator()),
//
//         error: (e, _) {
//           print(e.toString());
//
//           return Center(child: Text(e.toString()));
//         },
//       ),
//     );
//   }
// }
//
// class _CategoryCard extends StatelessWidget {
//   final TagModel tag;
//   final Color color;
//   final IconData icon;
//   final TextTheme? theme;
//   final VoidCallback? onDelete;
//   final int linkCount;
//
//   _CategoryCard({
//     required this.tag,
//     required this.icon,
//     required this.color,
//     this.theme,
//     this.onDelete,
//     required this.linkCount,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final c = context.colors;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: c.surface,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: c.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: color.withOpacity(.15),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: color, size: 22),
//           ),
//
//           Ui.gap(20),
//
//           /// Top Row
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // const SizedBox(width: 14),
//
//               /// Title + description
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Text(
//                       tag.name,
//                       style: Theme
//                           .of(context)
//                           .textTheme
//                           .titleLarge,
//                     ),
//
//                     Ui.gap8,
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 14),
//
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 4,
//                 ),
//
//                 child: Text(
//                   "$linkCount items",
//                   style: theme?.labelLarge!.copyWith(color: c.textSecondary),
//                 ),
//               ),
//
//               const Spacer(),
//
//               Icon(Icons.arrow_outward_outlined, size: 32, color: c.accent),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/Tag/tag_model.dart';
import '../../../theme/controller/theme_controller.dart';
import '../../../theme/recallr_colors.dart';
import '../../../theme/ui_helpers.dart';
import 'package:go_router/go_router.dart';
import '../../database/providers/isar_provider.dart';
import '../category/tag_list_provider.dart';

class ReCategory extends ConsumerWidget {
  const ReCategory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData getIcon(String? name) {
      switch (name) {
        case "code":
          return Icons.code;
        case "study":
          return Icons.school;
        case "design":
          return Icons.design_services;
        default:
          return Icons.folder;
      }
    }

    final c = context.colors;
    final txtTheme = Theme.of(context).textTheme;
    final tagsAsync = ref.watch(tagListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),

      body: tagsAsync.when(
        data: (tags) {
          if (tags.isEmpty) {
            return const Center(child: Text("No categories yet"));
          }

          return Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "L I B R A R Y",
                  style: txtTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: c.accent,
                  ),
                ),
                Ui.gap8,
                Text(
                  "Categories",
                  style: txtTheme.displayLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 42,
                  ),
                ),
                Ui.gap(12),
                Container(
                  height: 4,
                  width: 110,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Ui.gap(12),

                Expanded(
                  child: ListView.builder(
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final TagModel tag = tags[index];
                      final linkCount = tag.links.length;

                      return _CategoryCard(
                        tag: tag,
                        color: c.accent,
                        icon: getIcon(tag.icon),
                        linkCount: linkCount,
                        theme: txtTheme,
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Delete Category"),
                              content: Text(
                                "Are you sure you want to delete '${tag.name}'?  "
                                    "All links will remain, but this category will be removed from them.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => context.pop(false),
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => context.pop(true),
                                  child: Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final messenger = ScaffoldMessenger.of(context);
                            final tagName = tag.name;

                            final isar = await ref.read(isarProvider.future);

                            await isar.writeTxn(() async {
                              for (final link in tag.links) {
                                link.tags.remove(tag);
                                await link.tags.save();
                              }
                              await isar.tagModels.delete(tag.id);
                            });

                            // Refresh provider to update UI
                            ref.invalidate(tagListProvider);

                            messenger.showSnackBar(
                              SnackBar(content: Text("'$tagName' deleted !")),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },

        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final TagModel tag;
  final Color color;
  final IconData icon;
  final TextTheme? theme;
  final VoidCallback? onDelete;
  final int linkCount;

  _CategoryCard({
    required this.tag,
    required this.icon,
    required this.color,
    this.theme,
    this.onDelete,
    required this.linkCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Spacer(),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(15),
                      child: Icon(Icons.delete, color: c.accent)),
                ),
            ],
          ),

          Ui.gap(20),

          Text(
            tag.name,
            style: theme?.titleLarge ?? Theme.of(context).textTheme.titleLarge,
          ),

          Ui.gap8,

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$linkCount items",
                style: theme?.labelLarge?.copyWith(color: c.textSecondary),
              ),
              Icon(Icons.arrow_outward_outlined, size: 32, color: c.accent),
            ],
          ),

          


        ],
      ),
    );
  }
}