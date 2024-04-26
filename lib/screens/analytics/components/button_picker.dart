import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_button/group_button.dart';
import 'package:satsails/providers/transaction_type_show_provider.dart';

final selectedButtonProvider = StateProvider<String>((ref) => "Bitcoin");
final groupButtonControllerProvider = Provider<GroupButtonController>((ref) {
  return GroupButtonController(selectedIndex: 0);
});

class ButtonPicker extends ConsumerWidget {
  const ButtonPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(groupButtonControllerProvider);

    return GroupButton(
      isRadio: true,
      controller: controller,
      onSelected: (index, isSelected, isLongPress) {
        switch (isSelected) {
          case 0:
            ref.read(selectedButtonProvider.notifier).state = "All Transactions";
            ref.read(transactionTypeShowProvider.notifier).state = "All Transactions";
            break;
          case 1:
            ref.read(selectedButtonProvider.notifier).state = "Bitcoin";
            ref.read(transactionTypeShowProvider.notifier).state = "Bitcoin";
            break;
          case 2:
            ref.read(selectedButtonProvider.notifier).state = "Liquid";
            ref.read(transactionTypeShowProvider.notifier).state = "Liquid";
            break;
          case 3:
            ref.read(selectedButtonProvider.notifier).state = "Lightning";
            ref.read(transactionTypeShowProvider.notifier).state = "Lightning";
            break;
          case 4:
            ref.read(selectedButtonProvider.notifier).state = "Swap";
            ref.read(transactionTypeShowProvider.notifier).state = "Swap";
            break;
          default:
            ref.read(selectedButtonProvider.notifier).state = "Bitcoin";
            ref.read(transactionTypeShowProvider.notifier).state = "Bitcoin";
        }
      },
      buttons: const ["All Transactions", "Bitcoin", "Liquid", "Lightning", 'Swaps'],
      options: GroupButtonOptions(
        unselectedTextStyle: const TextStyle(fontSize: 16, color: Colors.black),
        selectedTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
        selectedColor: Colors.deepOrange,
        mainGroupAlignment: MainGroupAlignment.center,
        crossGroupAlignment: CrossGroupAlignment.center,
        groupRunAlignment: GroupRunAlignment.center,
        unselectedColor: Colors.white,
        groupingType: GroupingType.wrap,
        alignment: Alignment.center,
        elevation: 0,
        textPadding: EdgeInsets.zero,
        selectedShadow: <BoxShadow>[
          const BoxShadow(color: Colors.transparent)
        ],
        unselectedShadow: <BoxShadow>[
          const BoxShadow(color: Colors.transparent)
        ],
        borderRadius: BorderRadius.circular(30.0),
      ),
    );
  }
}