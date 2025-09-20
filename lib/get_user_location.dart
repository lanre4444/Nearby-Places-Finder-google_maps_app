import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GetUserLocation extends StatefulWidget {
  @override
  State<GetUserLocation> createState() => _GetUserLocationState();
}

class _GetUserLocationState extends State<GetUserLocation> {
  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.305689982537974, 5.62190239407558),
    zoom: 14,
  );

  final List<Marker> _markers = [];
  Position? currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _addStaticMarkers();
    _goToUserLocation(); // ✅ auto-fetch on startup
    _listenToLocationStream(); // ✅ auto-update as user moves
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // cleanup
    super.dispose();
  }

  void _addStaticMarkers() {
    _markers.addAll([
      Marker(
        markerId: MarkerId('home'),
        position: LatLng(6.305689982537974, 5.62190239407558),
        infoWindow: InfoWindow(title: 'My Home', snippet: 'Static marker'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: MarkerId('restaurant'),
        position: LatLng(6.314890650499346, 5.626920461087703),
        infoWindow: InfoWindow(
            title: 'Home & Away Restaurant', snippet: 'Food & drinks'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: MarkerId('pharmacy'),
        position: LatLng(6.30590007579693, 5.624863015443535),
        infoWindow: InfoWindow(title: 'Coka Pharmacy', snippet: 'Healthcare'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: MarkerId('hotel'),
        position: LatLng(6.3001484569918444, 5.628686001769539),
        infoWindow: InfoWindow(title: 'Homevile Plus Hotel', snippet: 'Hotel'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: MarkerId('police'),
        position: LatLng(6.3059409075406085, 5.624205538529725),
        infoWindow:
            InfoWindow(title: 'Etete Police Station', snippet: 'Security'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: MarkerId('uba'),
        position: LatLng(6.306328882090709, 5.630388732460986),
        infoWindow: InfoWindow(title: 'UBA', snippet: 'Bank'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: MarkerId('access_atm'),
        position: LatLng(6.312241031819957, 5.630556602007592),
        infoWindow: InfoWindow(title: 'Access Bank ATM', snippet: 'Bank ATM'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ]);
  }

  Future<void> _goToUserLocation() async {
    try {
      final position = await _getUserLocation();
      _updateUserMarker(position, moveCamera: true);
    } catch (e) {
      print('Error: $e');
    }
  }

  void _listenToLocationStream() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update only after 10m movement
      ),
    ).listen((position) {
      _updateUserMarker(position,
          moveCamera: false); // don’t move camera each time
    });
  }

  void _updateUserMarker(Position position, {bool moveCamera = false}) async {
    currentPosition = position;

    final marker = Marker(
      markerId: MarkerId('user_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure), // ✅ blue marker
      infoWindow: InfoWindow(title: 'You are here'),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'user_location');
      _markers.add(marker);
    });

    if (moveCamera) {
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    }
  }

  Future<Position> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services are disabled.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _openGoogleMaps(LatLng destination) async {
    final Uri uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              mapType: MapType.normal,
              markers: Set<Marker>.of(_markers),
              onMapCreated: (controller) => _controller.complete(controller),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _markers.length,
              itemBuilder: (context, index) {
                final marker = _markers[index];
                final title = marker.infoWindow.title ?? '';
                final snippet = marker.infoWindow.snippet ?? '';

                return ListTile(
                  title: Text(title),
                  subtitle: Text(snippet),
                  trailing: Icon(Icons.expand_more),
                  onTap: () async {
                    final controller = await _controller.future;
                    controller
                        .animateCamera(CameraUpdate.newLatLng(marker.position));

                    double? distanceKm;
                    if (currentPosition != null) {
                      distanceKm = Geolocator.distanceBetween(
                            currentPosition!.latitude,
                            currentPosition!.longitude,
                            marker.position.latitude,
                            marker.position.longitude,
                          ) /
                          1000;
                    }

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.15,
                        minChildSize: 0.1,
                        maxChildSize: 0.5,
                        builder: (context, scrollController) => Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: ListView(
                            controller: scrollController,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              Text(title,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              if (snippet.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(snippet),
                                ),
                              if (distanceKm != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Distance: ${distanceKm.toStringAsFixed(2)} km',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Center(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.directions),
                                  label: Text("Open in Google Maps"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _openGoogleMaps(marker.position);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.my_location),
        onPressed: _goToUserLocation, // ✅ refresh button
      ),
    );
  }
}
