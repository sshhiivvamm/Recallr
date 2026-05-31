import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:recallr/theme/ui_helpers.dart';

import '../core/database/providers/isar_provider.dart';
import '../data/models/Link/link_model.dart';
import '../data/models/Tag/tag_model.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import '../theme/recallr_colors.dart';
import '../theme/recallr_textstyle.dart';

class ReWid {
  TextEditingController linkController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController notesController = TextEditingController();

  final tagListProvider = StreamProvider<List<TagModel>>((ref) async* {
    final isar = await ref.watch(isarProvider.future);

    yield* isar.tagModels.where().sortByName().watch(fireImmediately: true);
  });

  String getSiteName(String domain) {
    if (domain.contains("youtube")) return "YouTube";
    if (domain.contains("instagram")) return "Instagram";
    if (domain.contains("github")) return "GitHub";
    if (domain.contains("medium")) return "Medium";
    if (domain.contains("twitter") || domain.contains("x.com")) return "X";
    return domain;
  }

  Future<void> saveLink(WidgetRef ref) async {
    final isar = await ref.read(isarProvider.future);
    final selectedTag = ref.read(selectedTagProvider);

    final url = linkController.text.trim();

    if (url.isEmpty) return;

    // 🔥 FETCH METADATA
    final data = await MetadataFetch.extract(url);

    final uri = Uri.tryParse(url);
    final domain = uri?.host ?? "";

    final link = LinkModel()
      ..url = url
      // ✅ TITLE (priority: user > metadata > url)
      ..title = titleController.text.isNotEmpty
          ? titleController.text
          : (data?.title ?? url)
      // ✅ METADATA
      ..description = data?.description
      ..thumbnail = data?.image
      ..siteName = getSiteName(domain)
      ..domain = domain
      // ✅ FAVICON (always generate)
      ..favicon = "https://www.google.com/s2/favicons?domain=$domain"
      // ✅ USER NOTES (separate field)
      ..notes = notesController.text;

    await isar.writeTxn(() async {
      await isar.linkModels.put(link);

      if (selectedTag != null) {
        link.tags.add(selectedTag);
        await link.tags.save();
      }
    });

    // 🧾 DEBUG
    debugPrint("------ LINK SAVED ------");
    debugPrint("Title: ${link.title}");
    debugPrint("Domain: ${link.domain}");
    debugPrint("Description: ${link.description}");
    debugPrint("Notes: ${link.notes}");
    debugPrint("Thumbnail: ${link.thumbnail}");
    debugPrint("Favicon: ${link.favicon}");
    debugPrint("-----------------------");

    // 🧹 CLEANUP
    linkController.clear();
    titleController.clear();
    notesController.clear();
    ref.read(selectedTagProvider.notifier).state = null;
  }

  final selectedTagProvider = StateProvider<TagModel?>((ref) => null);

  void openSaveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          builder: (context, controller) {
            final c = context.colors;

            return Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),

              child: ListView(
                controller: controller,
                padding: EdgeInsets.all(16),

                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.borderSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  Text(
                    "SAVE LINK",
                    style: AppTypography.h3.copyWith(
                      color: c.accent,
                      letterSpacing: 2.9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  Column(
                    // mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: linkController,
                        decoration: InputDecoration(hintText: 'Paste Link'),
                        onChanged: (value) async {
                          if (value.startsWith("http")) {
                            final data = await MetadataFetch.extract(value);

                            if (data != null) {
                              titleController.text = data.title ?? "";
                              notesController.text = data.description ?? "";
                            }
                          }
                        },
                      ),

                      SizedBox(height: 20),

                      Text("Category"),
                      Consumer(
                        builder: (context, ref, _) {
                          final tagAsync = ref.watch(tagListProvider);
                          final selectedTag = ref.watch(selectedTagProvider);

                          return tagAsync.when(
                            data: (tags) {
                              if (tags.isEmpty) {
                                return Text("No categories found");
                              }

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...tags.map((tag) {
                                    final isSelected =
                                        selectedTag?.id == tag.id;
                                    return ChoiceChip(
                                      label: Text(tag.name),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        ref
                                            .read(selectedTagProvider.notifier)
                                            .state = isSelected
                                            ? null
                                            : tag;
                                      },
                                    );
                                  }),
                                  ActionChip(
                                    label: Text("+ Add"),
                                    onPressed: () async {
                                      final newTagNameController =
                                          TextEditingController();

                                      // Use showDialog with the correct context
                                      final newTagName =
                                          await showDialog<String>(
                                            context: context,
                                            builder: (dialogContext) =>
                                                AlertDialog(
                                                  title: Text("New Category"),
                                                  content: TextField(
                                                    controller:
                                                        newTagNameController,
                                                    autofocus: true,
                                                    decoration: InputDecoration(
                                                      hintText: "Category name",
                                                    ),
                                                    onSubmitted: (value) =>
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(
                                                          value,
                                                        ), // use dialogContext
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(); // safe cancel
                                                      },
                                                      child: Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(
                                                          newTagNameController
                                                              .text,
                                                        ); // safe add
                                                      },
                                                      child: Text("Add"),
                                                    ),
                                                  ],
                                                ),
                                          );

                                      // If user added a valid name, save it
                                      if (newTagName != null &&
                                          newTagName.trim().isNotEmpty) {
                                        final isar = await ref.read(
                                          isarProvider.future,
                                        );
                                        final newTag = TagModel()
                                          ..name = newTagName.trim();
                                        await isar.writeTxn(
                                          () async =>
                                              await isar.tagModels.put(newTag),
                                        );
                                        ref.invalidate(
                                          tagListProvider,
                                        ); // refresh chips
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                            loading: () => CircularProgressIndicator(),
                            error: (e, _) => Text("Error: $e"),
                          );
                        },
                      ),

                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Why is this resource important?",
                        ),
                      ),

                      Ui.gap(12),

                      Consumer(
                        builder: (context, ref, _) {
                          return ElevatedButton(
                            onPressed: () async {
                              await saveLink(ref);

                              Navigator.pop(context); // optional: close sheet
                            },
                            child: Text("Save"),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
