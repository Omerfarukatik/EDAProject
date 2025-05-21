import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapLocationPage extends StatefulWidget {
  @override
  _MapLocationPageState createState() => _MapLocationPageState();
}

class _MapLocationPageState extends State<MapLocationPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Konum izni verilmedi")));
      return;
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final newLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentLatLng = newLatLng;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Konum (Haritada)")),
      body: _currentLatLng == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLatLng!,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: MarkerId("konum"),
            position: _currentLatLng!,
            infoWindow: InfoWindow(title: "Bulunduğun Konum"),
          ),
        },
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
