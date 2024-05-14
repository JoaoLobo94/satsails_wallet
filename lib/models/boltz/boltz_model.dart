import 'package:hive/hive.dart';
import 'package:boltz_dart/boltz_dart.dart';

part 'boltz_model.g.dart';

@HiveType(typeId: 12)
class ExtendedKeyPair {
  @HiveField(0)
  final KeyPair keyPair;

  // Unnamed constructor
  ExtendedKeyPair(this.keyPair);

  ExtendedKeyPair.raw({
    required String secretKey,
    required String publicKey,
  }) : keyPair = KeyPair.raw(
    secretKey: secretKey,
    publicKey: publicKey,
  );
}

@HiveType(typeId: 13)
class ExtendedPreImage {
  @HiveField(0)
  final PreImage preImage;

  // Unnamed constructor
  ExtendedPreImage(this.preImage);

  ExtendedPreImage.raw({
    required String value,
    required String sha256,
    required String hash160,
  }) : preImage = PreImage.raw(
    value: value,
    sha256: sha256,
    hash160: hash160,
  );
}

@HiveType(typeId: 14)
class ExtendedLBtcSwapScriptV2Str {
  @HiveField(0)
  final LBtcSwapScriptV2Str swapScript;

  // Unnamed constructor
  ExtendedLBtcSwapScriptV2Str(this.swapScript);

  ExtendedLBtcSwapScriptV2Str.raw({
    required SwapType swapType,
    String? fundingAddrs,
    required String hashlock,
    required String receiverPubkey,
    required int locktime,
    required String senderPubkey,
    required String blindingKey,
  }) : swapScript = LBtcSwapScriptV2Str.raw(
    swapType: swapType,
    fundingAddrs: fundingAddrs,
    hashlock: hashlock,
    receiverPubkey: receiverPubkey,
    locktime: locktime,
    senderPubkey: senderPubkey,
    blindingKey: blindingKey,
  );
}

@HiveType(typeId: 15)
class BoltzReceive {
  @HiveField(0)
  final LbtcLnV2Swap swap;
  @HiveField(1)
  final ExtendedKeyPair keys;
  @HiveField(2)
  final ExtendedPreImage preimage;
  @HiveField(3)
  final ExtendedLBtcSwapScriptV2Str swapScript;

  // Remove the unnamed constructor
  // BoltzReceive(this.swap, this.keys, this.preimage, this.swapScript);

  BoltzReceive({
    required String id,
    required SwapType kind,
    required Chain network,
    required this.keys,
    required this.preimage,
    required this.swapScript,
    required String invoice,
    required int outAmount,
    required String scriptAddress,
    required String blindingKey,
    required String electrumUrl,
    required String boltzUrl,
  }) : swap = LbtcLnV2Swap(
    id: id,
    kind: kind,
    network: network,
    keys: keys.keyPair,
    preimage: preimage.preImage,
    swapScript: swapScript.swapScript,
    invoice: invoice,
    outAmount: outAmount,
    scriptAddress: scriptAddress,
    blindingKey: blindingKey,
    electrumUrl: electrumUrl,
    boltzUrl: boltzUrl,
  );

  static Future<BoltzReceive> createBoltzReceive({
    required AllFees fees,
    required String mnemonic,
    required String address,
    required int amount,
    required int index,
  }) async {
    if (fees.lbtcLimits.minimal > amount){
      throw 'Amount is below the minimal limit';
    }
    if (fees.lbtcLimits.maximal < amount){
      throw 'Amount is above the maximal limit';
    }
    final result = await LbtcLnV2Swap.newReverse(
        mnemonic: mnemonic,
        index: index,
        outAddress: address,
        outAmount: amount,
        network: Chain.liquid,
        electrumUrl: 'blockstream.info:995',
        boltzUrl: 'https://api.boltz.exchange/v2'
    );

    final extendedPreImage = ExtendedPreImage.raw(
      value: result.preimage.value,
      sha256: result.preimage.sha256,
      hash160: result.preimage.hash160,
    );

    final extendedKeyPair = ExtendedKeyPair.raw(
      secretKey: result.keys.secretKey,
      publicKey: result.keys.publicKey,
    );

    final extendedLBtcSwapScriptV2Str = ExtendedLBtcSwapScriptV2Str.raw(
      swapType: result.swapScript.swapType,
      fundingAddrs: result.swapScript.fundingAddrs,
      hashlock: result.swapScript.hashlock,
      receiverPubkey: result.swapScript.receiverPubkey,
      locktime: result.swapScript.locktime,
      senderPubkey: result.swapScript.senderPubkey,
      blindingKey: result.swapScript.blindingKey,
    );

    return BoltzReceive(
      id: result.id,
      kind: result.kind,
      network: result.network,
      keys: extendedKeyPair,
      preimage: extendedPreImage,
      swapScript: extendedLBtcSwapScriptV2Str,
      invoice: result.invoice,
      outAmount: result.outAmount,
      scriptAddress: result.scriptAddress,
      blindingKey: result.blindingKey,
      electrumUrl: result.electrumUrl,
      boltzUrl: result.boltzUrl,
    );
  }

  Future<bool> claimBoltzTransaction({
    required String receiveAddress,
    required AllFees fees,
  }) async {
    try{
      final claimToInvoice = await LbtcLnV2Swap.newInstance(
        id: swap.id,
        kind: swap.kind,
        network: swap.network,
        keys: swap.keys,
        preimage: swap.preimage,
        swapScript: swap.swapScript,
        invoice: swap.invoice,
        outAmount: swap.outAmount,
        outAddress: receiveAddress,
        blindingKey: swap.blindingKey,
        electrumUrl: swap.electrumUrl,
        boltzUrl: swap.boltzUrl,
      );
      await claimToInvoice.claim(outAddress: receiveAddress, absFee: fees.lbtcReverse.claimFeesEstimate, tryCooperate: true);
      return true;
    } catch (e) {
      return false;
    }
  }
}