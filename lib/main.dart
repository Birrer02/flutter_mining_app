import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const FlutterMiningApp());
}

class FlutterMiningApp extends StatelessWidget {
  const FlutterMiningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Mining App',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber)),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _miningTimer;
  int _coins = 0;
  bool _isMining = false;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    loadCoins();
    loadInterstitialAd();
  }

  Future<void> loadCoins() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _coins = prefs.getInt('coins') ?? 0;
    });
  }

  void saveCoins() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
  }

  void startMining() {
    if (_isMining) return;

    setState(() {
      _isMining = true;
    });

    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _coins++;
      });
      saveCoins();
    });
  }

  void stopMining() {
    _miningTimer?.cancel();
    setState(() {
      _isMining = false;
    });
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test-Ad von Google
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Ad failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Failed to show ad: $error');
          ad.dispose();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      debugPrint('Ad not ready.');
    }
  }

  void donate() async {
    final String payPalUrl = "https://www.paypal.com/donate/?business=konqurenz@hotmail.com&currency_code=USD&amount=5";
    if (await canLaunchUrl(Uri.parse(payPalUrl))) {
      await launchUrl(Uri.parse(payPalUrl), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not open PayPal');
    }
  }

  @override
  void dispose() {
    _miningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Mining')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Coins: $_coins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isMining ? null : startMining,
              child: const Text('Start Mining'),
            ),
            ElevatedButton(
              onPressed: _isMining ? stopMining : null,
              child: const Text('Stop Mining'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: showInterstitialAd,
              child: const Text('Werbung ansehen'),
            ),
            ElevatedButton(
              onPressed: donate,
              child: const Text('Spenden via PayPal'),
            ),
          ],
        ),
      ),
    );
  }
}
