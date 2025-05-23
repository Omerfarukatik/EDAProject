import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'image_viewer_screen.dart'; // tam ekran gösterim sayfası

class ImageAnalysisScreen extends StatelessWidget {
  final String parentId;
  final String childId;

  const ImageAnalysisScreen({required this.parentId, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Görsel Analiz Sonuçları")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('imageAnalysis')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final imageUrl = data['image'] ?? '';
              final result = data['result'] ?? 'N/A';
              final confidence = (data['confidence'] ?? 0.0) * 100;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => Icon(Icons.broken_image),
                  ),
                  title: Text("Sınıf: $result"),
                  subtitle: Text("Confidence: ${confidence.toStringAsFixed(1)}%\n"
                      "Tarih: ${timestamp != null ? DateFormat('dd MMM yyyy HH:mm').format(timestamp) : 'Bilinmiyor'}"),
                  trailing: ElevatedButton(
                    child: Icon(Icons.open_in_full),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewerScreen(imageUrl: imageUrl),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
