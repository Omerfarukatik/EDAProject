import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeModal {
  static void show(BuildContext context) {
    String code = _generateRandomCode();
    int durationInSeconds = 30;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return _QrCodeContent(code: code, duration: durationInSeconds);
      },
    );
  }

  static String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }
}

class _QrCodeContent extends StatefulWidget {
  final String code;
  final int duration;

  const _QrCodeContent({required this.code, required this.duration});

  @override
  State<_QrCodeContent> createState() => _QrCodeContentState();
}

class _QrCodeContentState extends State<_QrCodeContent> {
  late int remainingTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.duration;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 1) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Eşleştirme Kodu (QR)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          SizedBox(height: 12),
          QrImageView(
            data: widget.code,
            version: QrVersions.auto,
            size: 180.0,
          ),
          SizedBox(height: 10),
          Text(
            widget.code,
            style: TextStyle(
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Geçerlilik süre: $remainingTime saniye",
            style: TextStyle(color: Colors.redAccent),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
