import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DuyguAnalizEkrani extends StatefulWidget {
  @override
  _DuyguAnalizEkraniState createState() => _DuyguAnalizEkraniState();
}

class _DuyguAnalizEkraniState extends State<DuyguAnalizEkrani> {
  static const platform = MethodChannel("keyboard_monitor_channel");

  String _keyboardLog = "";
  String _gptYaniti = "Henüz analiz yapılmadı.";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleKeyboardInput);
  }

  Future<void> _handleKeyboardInput(MethodCall call) async {
    if (call.method == "onTextCaptured") {
      setState(() {
        _keyboardLog += call.arguments.toString();
      });
    }
  }

  Future<void> _analizEt() async {
    setState(() {
      _loading = true;
      _gptYaniti = "Analiz yapılıyor...";
    });

    final yanit = await _sendToChatGPT(_keyboardLog);

    setState(() {
      _loading = false;
      _gptYaniti = yanit;
    });
  }

  Future<String> _sendToChatGPT(String metin) async {
    const apiKey = ""; // API KEY'İNİ BURAYA EKLE
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content":
            "Sen bir güvenlik asistanısın. Sana verilen metinden çocuğun ruhsal durumunu analiz et ve riskli bir durum varsa ebeveyni bilgilendir kısaca."
          },
          {
            "role": "user",
            "content": metin,
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonBody['choices'][0]['message']['content'];
    } else {
      return "API Hatası: ${response.statusCode}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Duygu Analizi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Toplanan Klavye Verisi:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(child: Text(_keyboardLog.isEmpty ? "Henüz veri yok." : _keyboardLog)),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _keyboardLog.isEmpty ? null : _analizEt,
                child: Text("ChatGPT ile Analiz Et"),
              ),
            ),
            const SizedBox(height: 20),
            Text("Asistanın Yorumları:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _loading
                ? Center(child: CircularProgressIndicator())
                : Container(
              padding: EdgeInsets.all(12),
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(child: Text(_gptYaniti)),
            ),
          ],
        ),
      ),
    );
  }
}
