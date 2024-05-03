import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:satsails/helpers/bitcoin_formart_converter.dart';
import 'package:satsails/helpers/input_formatters/comma_text_input_formatter.dart';
import 'package:satsails/helpers/input_formatters/decimal_text_input_formatter.dart';
import 'package:satsails/providers/balance_provider.dart';
import 'package:satsails/providers/bitcoin_provider.dart';
import 'package:satsails/providers/liquid_provider.dart';
import 'package:satsails/providers/send_tx_provider.dart';
import 'package:satsails/providers/settings_provider.dart';
import 'package:satsails/providers/sideswap_provider.dart';

class Peg extends ConsumerWidget {
  Peg({Key? key}) : super(key: key);
  final controller = TextEditingController();


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicSizedBox = MediaQuery.of(context).size.height * 0.01;
    final dynamicPadding = MediaQuery.of(context).size.width * 0.05;
    final titleFontSize = MediaQuery.of(context).size.height * 0.03;
    final pegIn = ref.watch(pegInProvider);
    final btcFormart = ref.watch(settingsProvider).btcFormat;
    final btcBalanceInFormat = ref.watch(btcBalanceInFormatProvider(btcFormart));
    final liquidFormart = ref.watch(settingsProvider).btcFormat;
    final liquidBalanceInFormat = ref.watch(liquidBalanceInFormatProvider(liquidFormart));
    final dynamicFontSize = MediaQuery.of(context).size.height * 0.02;
    final status = ref.watch(sideswapStatusProvider);

    return Stack(
      children: [
        Column(
          children: [
            Text(
              "Balance to spend:",
              style: TextStyle(fontSize: dynamicFontSize, color: Colors.grey),
            ),
            if (pegIn)
              Text(
                '$btcBalanceInFormat $btcFormart',
                style: TextStyle(fontSize: titleFontSize, color: Colors.grey),
                textAlign: TextAlign.center,
              )
            else
              Text(
                '$liquidBalanceInFormat $liquidFormart',
                style: TextStyle(fontSize: titleFontSize, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: dynamicSizedBox / 2),
            if (pegIn)
              _buildBitcoinCard(ref, dynamicPadding, titleFontSize, pegIn)
            else
              _buildLiquidCard(ref, dynamicPadding, titleFontSize, pegIn),
            GestureDetector(
              onTap: () {
                ref.read(pegInProvider.notifier).state = !pegIn;
                ref.read(sendTxProvider.notifier).updateAddress('');
                ref.read(sendTxProvider.notifier).updateAmount(0);
                controller.clear();
                ref.read(sendBlocksProvider.notifier).state = 1;
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Switch", style: TextStyle(fontSize: titleFontSize / 2, color: Colors.grey)),
                  Icon(EvaIcons.swap, size: titleFontSize, color: Colors.grey),
                ],
              ),
            ),
            if (pegIn)
              _buildLiquidCard(ref, dynamicPadding, titleFontSize, pegIn)
            else
              _buildBitcoinCard(ref, dynamicPadding, titleFontSize, pegIn),
            if (pegIn)
              Text(
                'Minimum amount: ${btcInDenominationFormatted(status.minPegInAmount.toDouble(), btcFormart)} ${btcFormart}',
                style: TextStyle(fontSize: titleFontSize / 2, color: Colors.grey),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Minimum amount: ${btcInDenominationFormatted(status.minPegOutAmount.toDouble(), btcFormart)} ${btcFormart}',
                style: TextStyle(fontSize: titleFontSize / 2, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            if (pegIn)
              _bitcoinFeeSlider(ref, dynamicPadding, titleFontSize)
            else
              _pickBitcoinFeeSuggestions(ref, dynamicPadding, titleFontSize),
            if (!pegIn)
              Text(
                'Bitcoin Network fee: ${ref.watch(pegOutBitcoinCostProvider).toStringAsFixed(0)} sats',
                style: TextStyle(fontSize: titleFontSize / 2, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            if (pegIn)
              _buildBitcoinFeeInfo(ref, dynamicPadding, titleFontSize)
            else
              _buildLiquidFeeInfo(ref, dynamicPadding, titleFontSize),
          ],
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: pegIn ? _bitcoinSlideToSend(ref, dynamicPadding, titleFontSize, context) : _liquidSlideToSend(ref, dynamicPadding, titleFontSize, context),
        ),
      ],
    );
  }


Widget _liquidSlideToSend(WidgetRef ref, double dynamicPadding, double titleFontSize, BuildContext context) {
    final status = ref.watch(sideswapStatusProvider);
    final pegStatus = ref.watch(sideswapPegStatusProvider);

    return pegStatus.when(
      data: (peg) {
        return Padding(
          padding: const EdgeInsets.all(15.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ActionSlider.standard(
                sliderBehavior: SliderBehavior.stretch,
                width: double.infinity,
                backgroundColor: Colors.white,
                toggleColor: Colors.blueAccent,
                action: (controller) async {
                  controller.loading();
                  await Future.delayed(const Duration(seconds: 3));
                  try {
                    if (ref.watch(sendTxProvider).amount < status.minPegOutAmount) {
                      throw 'Amount is below minimum peg out amount';
                    }
                    await ref.watch(sendLiquidTransactionProvider.future);
                    await ref.read(sideswapHiveStorageProvider(peg.orderId!).future);
                    controller.success();
                    Fluttertoast.showToast(msg: "Swap done! Check Analytics for more info", toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.TOP, timeInSecForIosWeb: 1, backgroundColor: Colors.green, textColor: Colors.white, fontSize: 16.0);
                    ref.watch(closeSideswapProvider);
                    await Future.delayed(const Duration(seconds: 3));
                    Navigator.pushReplacementNamed(context, '/home');
                  } catch (e) {
                    controller.failure();
                    Fluttertoast.showToast(msg: e.toString(), toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.TOP, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
                    controller.reset();
                  }
                },
                child: const Text('Swap')
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(child: LoadingAnimationWidget.prograssiveDots(size:  titleFontSize * 2, color: Colors.grey)),
      ),
      error: (error, stack) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(ref.watch(sendTxProvider).amount == 0 ? '' : error.toString(), style: TextStyle(color: Colors.grey, fontSize:  titleFontSize))
      ),
    );
  }


  Widget _bitcoinSlideToSend(WidgetRef ref, double dynamicPadding, double titleFontSize, BuildContext context) {
    final pegStatus = ref.watch(sideswapPegStatusProvider);

    return pegStatus.when(
      data: (peg) {
        return Padding(
          padding: const EdgeInsets.all(15.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ActionSlider.standard(
                sliderBehavior: SliderBehavior.stretch,
                width: double.infinity,
                backgroundColor: Colors.white,
                toggleColor: Colors.deepOrangeAccent,
                action: (controller) async {
                  controller.loading();
                  await Future.delayed(const Duration(seconds: 3));
                  try {
                    if (ref.watch(sendTxProvider).amount < ref.watch(sideswapStatusProvider).minPegInAmount) {
                      throw 'Amount is below minimum peg in amount';
                    }
                    await ref.watch(sendBitcoinTransactionProvider.future);
                    await ref.read(sideswapHiveStorageProvider(peg.orderId!).future);
                    controller.success();
                    Fluttertoast.showToast(msg: "Swap done! Check Analytics for more info", toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.TOP, timeInSecForIosWeb: 1, backgroundColor: Colors.green, textColor: Colors.white, fontSize: 16.0);
                    ref.watch(closeSideswapProvider);
                    await Future.delayed(const Duration(seconds: 3));
                    Navigator.pushReplacementNamed(context, '/home');
                  } catch (e) {
                    controller.failure();
                    Fluttertoast.showToast(msg: e.toString(), toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.TOP, timeInSecForIosWeb: 1, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
                    controller.reset();
                  }
                },
                child: const Text('Swap')
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(child: LoadingAnimationWidget.prograssiveDots(size:  titleFontSize * 2, color: Colors.grey)),
      ),
      error: (error, stack) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(error.toString(), style: TextStyle(color: Colors.grey, fontSize:  titleFontSize / 2))
      ),
    );
  }

  Widget _pickBitcoinFeeSuggestions(WidgetRef ref, double dynamicPadding, double titleFontSize) {
    final status = ref.watch(sideswapStatusProvider).bitcoinFeeRates ?? [];
    return DropdownButton<dynamic>(
      hint: Text("How fast would you like to receive your bitcoin", style: TextStyle(fontSize:  titleFontSize / 2)),
      dropdownColor: Colors.white,
      items: status.map((dynamic value) {
        return DropdownMenuItem<dynamic>(
          value: value,
          child: Center(
            child: Text(
              "${value["blocks"]} blocks - ${value["value"]} sats/vbyte",
              style: TextStyle(fontSize:  titleFontSize / 2, color: Colors.grey),
            ),
          ),
        );
      }).toList(),
      onChanged: (dynamic? newValue) {
        if (newValue != null) {
          ref.read(pegOutBlocksProvider.notifier).state = newValue["blocks"];
        }
      },
    );
  }

  Widget _bitcoinFeeSlider(WidgetRef ref, double dynamicPadding, double titleFontSize) {
    return InteractiveSlider(
      centerIcon: Icon(Clarity.block_solid, color: Colors.black),
      foregroundColor: Colors.deepOrange,
      unfocusedHeight: titleFontSize ,
      focusedHeight: titleFontSize,
      initialProgress: 15,
      min: 5.0,
      max: 1.0,
      onChanged: (dynamic value){
        ref.read(sendBlocksProvider.notifier).state = value;
      },
    );
  }

  Widget _buildBitcoinFeeInfo (WidgetRef ref, double dynamicPadding, double titleFontSize) {
    return Column(
        children: [
          ref.watch(feeProvider).when(
            data: (int fee) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Sending Transaction fee: $fee sats',
                  style: TextStyle(fontSize:  titleFontSize / 2, fontWeight: FontWeight.bold, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.all(8.0),
              child: LoadingAnimationWidget.prograssiveDots(size:  titleFontSize / 2, color: Colors.grey),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                  onPressed: () { ref.refresh(feeProvider); },
                  child: Text(ref.watch(sendTxProvider).amount == 0 ? '' : error.toString(), style: TextStyle(color: Colors.grey, fontSize:  titleFontSize / 2))
              ),
            ),
          ),
        ]
    );
  }

  Widget _buildLiquidFeeInfo (WidgetRef ref, double dynamicPadding, double titleFontSize) {
    return Column(
        children: [
          ref.watch(liquidFeeProvider).when(
            data: (int fee) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Sending Transaction fee: $fee sats',
                  style: TextStyle(fontSize:  titleFontSize / 2, fontWeight: FontWeight.bold, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.all(8.0),
              child: LoadingAnimationWidget.prograssiveDots(size:  titleFontSize / 2, color: Colors.grey),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                  onPressed: () { ref.refresh(liquidFeeProvider); },
                  child: Text(ref.watch(sendTxProvider).amount == 0 ? '' : error.toString(), style: TextStyle(color: Colors.grey, fontSize:  titleFontSize / 2))
              ),
            ),
          ),
        ]
    );

  }

  Widget _buildBitcoinCard (WidgetRef ref, double dynamicPadding, double titleFontSize, bool pegIn) {
    final sideSwapStatus = ref.watch(sideswapStatusProvider);
    final btcFormart = ref.watch(settingsProvider).btcFormat;
    final valueToReceive = ref.watch(sendTxProvider).amount * ( 1- sideSwapStatus.serverFeePercentPegIn! / 100) - ref.watch(pegOutBitcoinCostProvider);
    final formattedValueToReceive = btcInDenominationFormatted(valueToReceive, btcFormart);
    final sideSwapPeg = ref.watch(sideswapPegProvider);

    return SizedBox(
      width: double.infinity,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 10,
        margin: EdgeInsets.all(dynamicPadding),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: dynamicPadding, top: dynamicPadding / 3),
                child: Text('Bitcoin', style: TextStyle(fontSize: titleFontSize / 1.5, color: Colors.white), textAlign: TextAlign.center),
              ),
              if (!pegIn) Padding(
                padding: EdgeInsets.only(bottom: dynamicPadding / 2 , top: dynamicPadding / 3),
                child: Column(
                  children: [
                    Text("Receive", style: TextStyle(fontSize: titleFontSize / 2, color: Colors.white), textAlign: TextAlign.center),
                    if (double.parse(formattedValueToReceive) <= 0)
                      Text("0", style: TextStyle(fontSize: titleFontSize / 2, color: Colors.white), textAlign: TextAlign.center)
                    else
                      Text(" ~ $formattedValueToReceive", style: TextStyle(fontSize: titleFontSize / 2, color: Colors.white), textAlign: TextAlign.center),
                  ],
                ),
              )
              else
                sideSwapPeg.when(data:
                    (peg) {
                  return TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [DecimalTextInputFormatter(decimalRange: 8), CommaTextInputFormatter()],
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                    onChanged: (value) async {
                      if (value.isEmpty) {
                        ref.read(sendTxProvider.notifier).updateAmountFromInput('0', btcFormart);
                        ref.read(sendTxProvider.notifier).updateAddress(peg.pegAddr!);
                      }
                      ref.read(sendTxProvider.notifier).updateAmountFromInput(value, btcFormart);
                      ref.read(sendTxProvider.notifier).updateAddress(peg.pegAddr!);
                    },
                  );
                },
                  loading: () => Padding(
                    padding: EdgeInsets.only(bottom: dynamicPadding, top: dynamicPadding / 3),
                    child: LoadingAnimationWidget.prograssiveDots(size:  titleFontSize / 2, color: Colors.white),
                  ),
                  error: (error, stack) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(error.toString(), style: TextStyle(color: Colors.white, fontSize:  titleFontSize / 2))
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidCard (WidgetRef ref, double dynamicPadding, double titleFontSize, bool pegIn) {
    final sideSwapStatus = ref.watch(sideswapStatusProvider);
    final valueToReceive = ref.watch(sendTxProvider).amount * ( 1- sideSwapStatus.serverFeePercentPegOut! / 100);
    final btcFormart = ref.watch(settingsProvider).btcFormat;
    final formattedValueToReceive = btcInDenominationFormatted(valueToReceive, btcFormart);
    final sideSwapPeg = ref.watch(sideswapPegProvider);

    return SizedBox(
      width: double.infinity,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 10,
        margin: EdgeInsets.all(dynamicPadding),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: dynamicPadding, top: dynamicPadding / 3),
                child: const Text('Liquid Bitcoin', style: TextStyle(fontSize: 20, color: Colors.white), textAlign: TextAlign.center),
              ),
              if (pegIn) Padding(
                padding: EdgeInsets.only(bottom: dynamicPadding / 2, top: dynamicPadding / 3),
                child:Column(
                  children: [
                    Text("Receive", style: TextStyle(fontSize: titleFontSize / 2, color: Colors.white), textAlign: TextAlign.center),
                    if (double.parse(formattedValueToReceive) <= 0)
                      Text("0", style: TextStyle(fontSize: titleFontSize / 2, color: Colors.white), textAlign: TextAlign.center)
                    else
                      Text(" ~ $formattedValueToReceive", style: TextStyle(fontSize: titleFontSize / 2, color: Colors.white), textAlign: TextAlign.center),
                  ],
                ),
              )
              else
                sideSwapPeg.when(data:
                    (peg) {
                  return TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [DecimalTextInputFormatter(decimalRange: 8), CommaTextInputFormatter()],
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                    onChanged: (value) async {
                      if (value.isEmpty) {
                        ref.read(sendTxProvider.notifier).updateAmountFromInput('0', btcFormart);
                        ref.read(sendTxProvider.notifier).updateAddress(peg.pegAddr!);
                      }
                      ref.read(sendTxProvider.notifier).updateAmountFromInput(value, btcFormart);
                      ref.read(sendTxProvider.notifier).updateAddress(peg.pegAddr!);
                    },
                  );
                },
                  loading: () => Padding(
                    padding: EdgeInsets.only(bottom: dynamicPadding, top: dynamicPadding / 3),
                    child: LoadingAnimationWidget.prograssiveDots(size: titleFontSize, color: Colors.white),
                  ),
                  error: (error, stack) => Padding(
                      padding:EdgeInsets.only(bottom: dynamicPadding, top: dynamicPadding / 3),
                      child: Text(error.toString(), style: TextStyle(color: Colors.white, fontSize:  titleFontSize / 2))
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
  
  
  