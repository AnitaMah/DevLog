import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dev_log/models/module.dart';
import 'package:dev_log/helpers/icon_helper.dart';

class MenuNavigation extends StatelessWidget {
  const MenuNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Module>('modules').listenable(),
      builder: (context, Box<Module> box, _) {
        final rootModules = box.values.where((m) => m.parentId == null).toList();

        return ListView.builder(
          shrinkWrap: true,
          itemCount: rootModules.length,
          itemBuilder: (context, index) {
            final module = rootModules[index];
            final subModules = box.values
                .where((m) => m.parentId == module.id)
                .toList();

            return ExpansionTile(
              leading: IconHelper.getFaIcon(
                module.iconName,
                color: Colors.white70,
                size: 20,
              ),
              title: Text(
                module.title,
                style: const TextStyle(color: Colors.white),
              ),
              children: subModules.map((sub) {
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 40),
                  leading: IconHelper.getFaIcon(
                    sub.iconName,
                    color: Colors.white38,
                    size: 16,
                  ),
                  title: Text(
                    sub.title,
                    style: const TextStyle(color: Colors.white60),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}