import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SentimentParentSide extends StatefulWidget {
  final String parentId;
  final String childId;

  const SentimentParentSide({
    required this.parentId,
    required this.childId,
  });

  @override
  _SentimentParentSideState createState() => _SentimentParentSideState();
}

class _SentimentParentSideState extends State<SentimentParentSide> {
  String _analysisResult = "";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _analyzeSentiments();
  }

  Future<void> _analyzeSentiments() async {
    setState(() {
      _loading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("parents")
          .doc(widget.parentId)
          .collection("children")
          .doc(widget.childId)
          .collection("sentiment")
          .orderBy("timestamp", descending: true)
          .limit(10) // son 10 analiz
          .get();

      final List logs = snapshot.docs.map((doc) {
        return doc["text"] ?? "";
      }).toList();

      final combinedText = logs.join(" ");

      final result = await _sendToChatGPT(combinedText);

      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      setState(() {
        _analysisResult = "Hata oluştu: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<String> _sendToChatGPT(String input) async {
    const apiKey = "api_key"; // OpenAI API anahtarınızı buraya ekleyin
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
            "Sen sana verilen klavye girdilerinden çocuğun ruhsal durumunu analiz eden bir asistansın."
                " Eğer çocuğun ruhsal durumu ile ilgili sakıncalı bir durum tespit edersen açıkla ve bunu kısa tutmaya çalış,"
                "ebeveyni bilgilendirmek amacıyla açıkla ve açıklamanın içinde klavye girdilerinden sakıncalı olanlari paylaş."
          },
          {
            "role": "user",
            "content": input,
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
      appBar: AppBar(title: Text("Duygu Analizi (Ebeveyn)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Text(
            _analysisResult,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
