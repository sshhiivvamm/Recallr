import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/features/category/tag_provider.dart';


class AddCategorySheet extends ConsumerStatefulWidget {
  const AddCategorySheet({super.key});

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final nameController = TextEditingController();

  Color selectedColor = Colors.blue;
  IconData? selectedIcon;

  final icons = [
    Icons.code,
    Icons.book,
    Icons.school,
    Icons.work,
    Icons.favorite,
    Icons.star,
    Icons.lightbulb,
  ];

  final colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// Title
              Text(
                "Create Category",
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 20),

              /// Name Field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Category Name",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// Color Picker
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Pick Color",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                children: colors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: color,
                      child: selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              /// Icon Picker
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Optional Icon",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                children: icons.map((icon) {
                  final selected = selectedIcon == icon;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                    child: CircleAvatar(
                      backgroundColor:
                      selected ? Colors.blue : Colors.grey.shade200,
                      child: Icon(
                        icon,
                        color: selected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),

              /// Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    await ref.read(tagRepositoryProvider).addTag(
                      name: name,
                      colorHex:
                      "#${selectedColor.value.toRadixString(16).substring(2)}",
                      icon: selectedIcon?.codePoint.toString(),
                    );

                    if (mounted) Navigator.of(context).pop();
                  },
                  child: const Text("Save Category"),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}