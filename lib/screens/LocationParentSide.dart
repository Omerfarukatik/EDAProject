import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationParentSide extends StatefulWidget {
  final String childId;

  const LocationParentSide({Key? key, required this.childId}) : super(key: key);

  @override
  _LocationParentSideState createState() => _LocationParentSideState();
}

class _LocationParentSideState extends State<LocationParentSide> {
  GoogleMapController? _mapController;
  LatLng? _lastKnownLocation;

  @override
  void initState() {
    super.initState();
    _fetchLatestLocation();
  }

  Future<void> _fetchLatestLocation() async {
    final parentId = FirebaseAuth.instance.currentUser?.uid;
    if (parentId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('location')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final lat = doc['latitude'];
        final lng = doc['longitude'];

        setState(() {
          _lastKnownLocation = LatLng(lat, lng);
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
        );
      }
    } catch (e) {
      print("Konum verisi alınamadı: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Çocuğun Konumu")),
      body: _lastKnownLocation == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _lastKnownLocation!,
          zoom: 16,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: {
          Marker(
            markerId: MarkerId("child_location"),
            position: _lastKnownLocation!,
            infoWindow: InfoWindow(title: "Son Konum"),
          ),
        },
      ),
    );
  }
}
