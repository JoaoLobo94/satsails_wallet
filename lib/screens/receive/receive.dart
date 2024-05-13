import 'package:Satsails/providers/boltz_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:Satsails/providers/address_receive_provider.dart';
import 'package:Satsails/providers/settings_provider.dart';
import 'package:Satsails/screens/receive/components/amount_input.dart';
import 'package:Satsails/screens/shared/copy_text.dart';
import 'package:Satsails/screens/shared/offline_transaction_warning.dart';
import 'package:Satsails/screens/shared/qr_code.dart';
import '../../providers/transaction_type_show_provider.dart';
import 'package:group_button/group_button.dart';

final selectedButtonProvider = StateProvider.autoDispose<String>((ref) => "Bitcoin");

class Receive extends ConsumerWidget {
  Receive({Key? key}) : super(key: key);

  final groupButtonControllerProvider = Provider<GroupButtonController>((ref) {
    return GroupButtonController(selectedIndex: 1);
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedButtonProvider);
    final bitcoinAddressAsyncValue = ref.watch(bitcoinReceiveAddressAmountProvider);
    final liquidAddressAsyncValue = ref.watch(liquidReceiveAddressAmountProvider);
    final controller = ref.watch(groupButtonControllerProvider);
    final online = ref.watch(settingsProvider).online;
    final claim = ref.watch(claimBoltzTransactionProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Receive'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(inputAmountProvider.notifier).state = '0.0';
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            OfflineTransactionWarning(online: online),
              GroupButton(
                isRadio: true,
                controller: controller,
                onSelected: (index, isSelected, isLongPress) {
                  switch (index) {
                    case 'Bitcoin':
                      ref.read(selectedButtonProvider.notifier).state = "Bitcoin";
                      ref.read(transactionTypeShowProvider.notifier).state = "Bitcoin";
                      break;
                    case 'Liquid':
                      ref.read(selectedButtonProvider.notifier).state = "Liquid";
                      ref.read(transactionTypeShowProvider.notifier).state = "Liquid";
                      break;
                    case 'Lightning':
                      ref.read(selectedButtonProvider.notifier).state = "Lightning";
                      ref.read(transactionTypeShowProvider.notifier).state = "Lightning";
                      break;
                    default:
                      'Bitcoin';
                  }
                },
                buttons: ["Lightning", 'Bitcoin', "Liquid"],
                options: GroupButtonOptions(
                  unselectedTextStyle: const TextStyle(
                      fontSize: 16, color: Colors.black),
                  selectedTextStyle: const TextStyle(
                      fontSize: 16, color: Colors.white),
                  selectedColor: Colors.deepOrange,
                  mainGroupAlignment: MainGroupAlignment.center,
                  crossGroupAlignment: CrossGroupAlignment.center,
                  groupRunAlignment: GroupRunAlignment.center,
                  unselectedColor: Colors.white,
                  groupingType: GroupingType.row,
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
              ),
            const SizedBox(height: 16.0),
            Column(
              children: [
                if (selectedIndex == 'Bitcoin')
                  bitcoinAddressAsyncValue.when(
                    data: (bitcoinAddress) {
                      return Column(
                        children: [
                          buildQrCode(bitcoinAddress, context),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: buildAddressText(bitcoinAddress, context),
                          ),
                        ],
                      );
                    },
                    loading: () =>Center(child: LoadingAnimationWidget.threeArchedCircle(size: MediaQuery.of(context).size.width * 0.6, color: Colors.orange)),
                    error: (error, stack) => Center(child: LoadingAnimationWidget.threeArchedCircle(size: MediaQuery.of(context).size.width * 0.6, color: Colors.orange)),
                  ),
                if (selectedIndex == "Liquid")
                  liquidAddressAsyncValue.when(
                    data: (liquidAddress) {
                      return Column(
                        children: [
                          buildQrCode(liquidAddress, context),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: buildAddressText(liquidAddress, context),
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        Center(child: LoadingAnimationWidget.threeArchedCircle(
                            size: MediaQuery.of(context).size.width * 0.6, color: Colors.orange)),
                    error: (error, stack) =>
                        Center(child: LoadingAnimationWidget.threeArchedCircle(
                            size: MediaQuery.of(context).size.width * 0.6, color: Colors.orange)),
                  ),
                if (selectedIndex == "Lightning")
                  ref.watch(boltzReceiveProvider).when(
                    data: (data) {
                      return Column(
                        children: [
                          buildQrCode(data.invoice, context),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: buildAddressText(data.invoice, context),
                          ),
                        ],
                      );
                    },
                    loading: () => Center(child: LoadingAnimationWidget.threeArchedCircle(size: MediaQuery.of(context).size.width * 0.6, color: Colors.orange)),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                  ),

                const AmountInput(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}