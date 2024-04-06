import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forex_currency_conversion/forex_currency_conversion.dart';

class BalanceModel extends StateNotifier<Balance>{
  BalanceModel(super.state);

  void updateBtcBalance(int newBtcBalance) {
    state = state.copyWith(btcBalance: newBtcBalance);
  }
}

class Balance {
  late final int btcBalance;
  final int liquidBalance;
  final int usdBalance;
  final int cadBalance;
  final int eurBalance;
  final int brlBalance;

  Balance({
    required this.btcBalance,
    required this.liquidBalance,
    required this.usdBalance,
    required this.cadBalance,
    required this.eurBalance,
    required this.brlBalance,
  });

  Balance copyWith({
    int? btcBalance,
    int? liquidBalance,
    int? usdBalance,
    int? cadBalance,
    int? eurBalance,
    int? brlBalance,
  }) {
    return Balance(
      btcBalance: btcBalance ?? this.btcBalance,
      liquidBalance: liquidBalance ?? this.liquidBalance,
      usdBalance: usdBalance ?? this.usdBalance,
      cadBalance: cadBalance ?? this.cadBalance,
      eurBalance: eurBalance ?? this.eurBalance,
      brlBalance: brlBalance ?? this.brlBalance,
    );
  }


  double liquidBalanceInDenomination(String denomination) {
    switch (denomination) {
      case 'sats':
        return liquidBalance.toDouble();
      case 'BTC':
        return liquidBalance.toDouble() / 100000000;
      case 'mBTC':
        return liquidBalance.toDouble() / 100000;
      case 'bits':
        return liquidBalance.toDouble() / 1000000;
      default:
        return 0;
    }
  }

  double btcBalanceInDenomination(String denomination) {
    switch (denomination) {
      case 'sats':
        return btcBalance.toDouble();
      case 'BTC':
        return btcBalance.toDouble() / 100000000;
      case 'mBTC':
        return btcBalance.toDouble() / 100000;
      case 'bits':
        return btcBalance.toDouble() / 1000000;
      default:
        return 0;
    }
  }

  double totalBtcBalance() {
    return btcBalance.toDouble() + liquidBalance.toDouble();
  }

  double totalBtcBalanceInDenomination(String denomination) {
    switch (denomination) {
      case 'sats':
        return totalBtcBalance();
      case 'BTC':
        return totalBtcBalance() / 100000000;
      case 'mBTC':
        return totalBtcBalance() / 100000;
      case 'bits':
        return totalBtcBalance() / 1000000;
      default:
        return 0;
    }
  }

  Future<Percentage> percentageOfEachCurrency() async {
    final total = await totalBalanceInCurrency('BTC');
    return Percentage(
      eurPercentage: await getConvertedBalance('EUR', 'BTC', eurBalance.toDouble()) / total,
      brlPercentage: await getConvertedBalance('BRL', 'BTC', brlBalance.toDouble()) / total,
      usdPercentage: await getConvertedBalance('USD', 'BTC', usdBalance.toDouble()) / total,
      cadPercentage: await getConvertedBalance('CAD', 'BTC', cadBalance.toDouble()) / total,
      liquidPercentage: (liquidBalance / 100000000).toDouble() / total,
      btcPercentage: (btcBalance / 100000000).toDouble() / total,
      total: total,
    );
  }

  Future<double> totalBalanceInDenomination(String? denomination) async {
    switch (denomination) {
      case 'BTC':
        return await totalBalanceInCurrency('BTC');
      case 'sats':
        return await totalBalanceInCurrency('BTC') * 100000000;
      case 'mBTC':
        return await totalBalanceInCurrency('BTC') * 100000;
      case 'bits':
        return await totalBalanceInCurrency('BTC') * 1000000;
      default:
        return 0;
    }
  }

  Future<double> currentBitcoinPriceInCurrency(String currency) {
    return getConvertedBalance('BTC', currency, 1);
  }

  Future<double> totalBalanceInCurrency(String currency) async {
    double total = 0;
    double totalInBtc = totalBtcBalanceInDenomination('BTC');

    switch (currency) {
      case 'BTC':
        total += totalInBtc;
        total += await getConvertedBalance('BRL', 'BTC', brlBalance.toDouble());
        total += await getConvertedBalance('CAD', 'BTC', cadBalance.toDouble());
        total += await getConvertedBalance('EUR', 'BTC', eurBalance.toDouble());
        total += await getConvertedBalance('USD', 'BTC', usdBalance.toDouble());
        break;
      case 'USD':
        total += usdBalance.toDouble();
        total += await getConvertedBalance('BRL', 'USD', brlBalance.toDouble());
        total += await getConvertedBalance('CAD', 'USD', cadBalance.toDouble());
        total += await getConvertedBalance('EUR', 'USD', eurBalance.toDouble());
        total += await getConvertedBalance('BTC', 'USD', totalInBtc);
        break;
      case 'CAD':
        total += cadBalance.toDouble();
        total += await getConvertedBalance('BRL', 'CAD', brlBalance.toDouble());
        total += await getConvertedBalance('EUR', 'CAD', eurBalance.toDouble());
        total += await getConvertedBalance('USD', 'CAD', usdBalance.toDouble());
        total += await getConvertedBalance('BTC', 'CAD', totalInBtc);
        break;
      case 'EUR':
        total += eurBalance.toDouble();
        total += await getConvertedBalance('BRL', 'EUR', brlBalance.toDouble());
        total += await getConvertedBalance('CAD', 'EUR', cadBalance.toDouble());
        total += await getConvertedBalance('USD', 'EUR', usdBalance.toDouble());
        total += await getConvertedBalance('BTC', 'EUR', totalInBtc);
        break;
      case 'BRL':
        total += brlBalance.toDouble();
        total += await getConvertedBalance('CAD', 'BRL', cadBalance.toDouble());
        total += await getConvertedBalance('EUR', 'BRL', eurBalance.toDouble());
        total += await getConvertedBalance('USD', 'BRL', usdBalance.toDouble());
        total += await getConvertedBalance('BTC', 'BRL', totalInBtc);
        break;
    }
    return total;
  }
  Future<double> getConvertedBalance(String sourceCurrency, String destinationCurrency, double sourceAmount) async {
    if (sourceCurrency == destinationCurrency) {
      return sourceAmount;
    }

    if (sourceAmount == 0) {
      return 0;
    }


    final fx = Forex();
    final result = await fx.getCurrencyConverted(sourceCurrency: sourceCurrency, destinationCurrency: destinationCurrency, sourceAmount: sourceAmount);
    final error = fx.getErrorNotifier.value;

    if (error != null){
      throw 'No internet connection';
    }
    return result;
  }



}

class Percentage {
  final double btcPercentage;
  final double liquidPercentage;
  final double usdPercentage;
  final double cadPercentage;
  final double eurPercentage;
  final double brlPercentage;
  final double total;

  Percentage({
    required this.btcPercentage,
    required this.liquidPercentage,
    required this.usdPercentage,
    required this.cadPercentage,
    required this.eurPercentage,
    required this.brlPercentage,
    required this.total,
  });
}