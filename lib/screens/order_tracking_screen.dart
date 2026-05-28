import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';
import '../../core/constants/firestore_constants.dart';
import '../../widgets/custom_button.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final String _googleApiKey = 'AIzaSyDecEs4ql9moIyK9JoLAXsmnCJUAOEhdCA'; // Using Android API Key from firebase_options
  LatLng? _lastRiderLatLng;

  Future<void> _callRider(String phone) async {
    // Clean the number — remove spaces, dashes, brackets
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer for $phone')),
        );
      }
    }
  }

  Future<void> _messageRider(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Try WhatsApp first (common in Pakistan)
    final whatsappUri = Uri.parse('https://wa.me/92${cleaned.replaceFirst(RegExp(r'^0'), '')}');
    final smsUri = Uri(scheme: 'sms', path: cleaned);

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp or SMS')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarkers(GeoPoint riderLoc, OrderModel order) async {
    final riderLatLng = LatLng(riderLoc.latitude, riderLoc.longitude);
    
    // Check if rider moved significantly before fetching new polyline
    bool shouldUpdatePolyline = _lastRiderLatLng == null;
    if (_lastRiderLatLng != null) {
      // Very simple distance check or just update every time for now
      shouldUpdatePolyline = true; 
    }
    _lastRiderLatLng = riderLatLng;

    final riderMarker = Marker(
      markerId: const MarkerId('rider'),
      position: riderLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: const InfoWindow(title: 'Delivery Rider'),
    );

    final destMarker = order.deliveryLat != null && order.deliveryLng != null
        ? Marker(
            markerId: const MarkerId('destination'),
            position: LatLng(order.deliveryLat!, order.deliveryLng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Delivery Location'),
          )
        : null;

    setState(() {
      _markers.clear();
      _markers.add(riderMarker);
      if (destMarker != null) _markers.add(destMarker);
    });

    if (shouldUpdatePolyline && order.deliveryLat != null && order.deliveryLng != null) {
      _getRoutePolyline(riderLatLng, LatLng(order.deliveryLat!, order.deliveryLng!));
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(riderLatLng),
    );
  }

  bool _isFetchingPolyline = false;

  Future<void> _getRoutePolyline(LatLng start, LatLng end) async {
    if (_isFetchingPolyline) return;
    _isFetchingPolyline = true;

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$_googleApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final points = data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);
          
          if (mounted) {
            setState(() {
              _polylines.clear();
              _polylines.add(Polyline(
                polylineId: const PolylineId('route'),
                points: decodedPoints,
                color: AppColors.primary,
                width: 5,
              ));
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching polyline: $e');
    } finally {
      _isFetchingPolyline = false;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(FirestoreConstants.orders)
              .doc(widget.orderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Order not found", style: TextStyle(color: Colors.white)));
            }

            final order = OrderModel.fromMap({
              'id': snapshot.data!.id,
              ...snapshot.data!.data()!,
            });
            final status = order.status;
            final orderNumber = order.id.length > 5 ? order.id.substring(0, 5).toUpperCase() : order.id.toUpperCase();

            // Dynamic estimated arrival based on status
            String estimatedTime = "--:--";
            String timeSuffix = "";
            String remainingMsg = "Calculating...";

            if (order.estimatedDeliveryTime != null) {
              estimatedTime = DateFormat('h:mm').format(order.estimatedDeliveryTime!);
              timeSuffix = DateFormat('a').format(order.estimatedDeliveryTime!);
              
              final now = DateTime.now();
              final diff = order.estimatedDeliveryTime!.difference(now).inMinutes;
              if (diff > 0) {
                remainingMsg = "$diff mins remaining";
              } else if (diff > -5) {
                remainingMsg = "Arriving any moment";
              } else {
                remainingMsg = "A bit delayed";
              }
            }

            if (status == FirestoreConstants.statusDelivered) {
              remainingMsg = "Arrived";
              estimatedTime = "Done";
              timeSuffix = "";
            } else if (status == FirestoreConstants.statusOnTheWay) {
              if (order.estimatedDeliveryTime == null) remainingMsg = "5-10 mins remaining";
            } else if (status == FirestoreConstants.statusPending) {
              remainingMsg = "Waiting for confirmation";
            } else if (status == FirestoreConstants.statusCancelled) {
              remainingMsg = "Order Cancelled";
              estimatedTime = "N/A";
              timeSuffix = "";
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "ORDER #$orderNumber",
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: AppColors.subtle),
                                ),
                                const Text(
                                  "Live Tracking",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]),
                              child: const Text(
                                "HELP",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Map with Live Rider Location
                      if (order.riderId != null)
                        StreamBuilder<Map<String, dynamic>?>(
                          stream: FirestoreService().getRiderById(order.riderId!),
                          builder: (context, riderSnapshot) {
                            GeoPoint? riderLoc;
                            if (riderSnapshot.hasData && riderSnapshot.data != null) {
                              riderLoc = riderSnapshot.data!['currentLocation'] as GeoPoint?;
                              // Small delay to avoid setState during build
                              if (riderLoc != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _updateMarkers(riderLoc!, order);
                                });
                              }
                            }
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.border, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: riderLoc != null 
                                      ? LatLng(riderLoc.latitude, riderLoc.longitude)
                                      : (order.deliveryLat != null ? LatLng(order.deliveryLat!, order.deliveryLng!) : const LatLng(30.0444, 72.3444)),
                                    zoom: 15,
                                  ),
                                  markers: _markers,
                                  polylines: _polylines,
                                  onMapCreated: (controller) => _mapController = controller,
                                  zoomControlsEnabled: false,
                                  mapToolbarEnabled: false,
                                  myLocationButtonEnabled: false,
                                  compassEnabled: false,
                                ),
                              ),
                            );
                          }
                        )
                      else
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          height: 250,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border, width: 2),
                            image: const DecorationImage(
                              image: NetworkImage(
                                  "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800"),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black45, BlendMode.darken),
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_searching, color: AppColors.primary, size: 48),
                                SizedBox(height: 12),
                                Text("Waiting for Rider Assignment", 
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Estimated Arrival Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8))
                            ]),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ESTIMATED ARRIVAL",
                                  style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.subtle, letterSpacing: 1),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(estimatedTime,
                                        style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(timeSuffix,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold, color: AppColors.subtle)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: status == FirestoreConstants.statusDelivered ? Colors.blue : Colors.green,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(remainingMsg,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary))
                                  ],
                                )
                              ],
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(18)),
                              child: const Icon(Icons.schedule,
                                  size: 32, color: AppColors.primary),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Order Journey
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OrderStatusStepper(order: order),
                      ),
                      const SizedBox(height: 24),
                      // Rider Info Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: AppColors.card2,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8))
                            ]),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                  Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundImage: NetworkImage(
                                          order.riderPhoto ?? "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100"),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: order.riderId != null ? Colors.green : Colors.grey,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.card2, width: 2),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "YOUR DELIVERY HERO",
                                        style: TextStyle(
                                            color: AppColors.subtle,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.riderName ?? "Assigning Rider...",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      if (order.riderId != null)
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color:
                                                    AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.2))),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star,
                                                    size: 14, color: AppColors.primary),
                                                const SizedBox(width: 4),
                                                Text("${order.riderRating ?? '4.5'}",
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text("Verified Rider",
                                              style: TextStyle(
                                                  color: AppColors.subtle,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500))
                                        ],
                                      )
                                      else
                                      const Text("Finding the best route for you",
                                          style: TextStyle(
                                              color: AppColors.subtle,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500))
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: "Call Rider",
                                    onPressed: () {
                                      if (order.riderPhone != null && order.riderPhone!.isNotEmpty) {
                                        _callRider(order.riderPhone!);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Rider phone number not available yet')),
                                        );
                                      }
                                    },
                                    height: 50,
                                    borderRadius: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomButton(
                                    text: "Message",
                                    onPressed: () {
                                      if (order.riderPhone != null && order.riderPhone!.isNotEmpty) {
                                        _messageRider(order.riderPhone!);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Rider contact not available yet')),
                                        );
                                      }
                                    },
                                    height: 50,
                                    borderRadius: 16,
                                    isOutlined: true,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
                // Bottom Navigation Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32)),
                      border: const Border(top: BorderSide(color: AppColors.border)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, -10))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _navItem(context, Icons.home_rounded, "Home", false, primary,
                            onTap: () {
                          Navigator.pushNamedAndRemoveUntil(context, RouteNames.home, (route) => false);
                        }),
                        _navItem(context, Icons.receipt_long_rounded, "Orders", true,
                            primary, onTap: () {
                          Navigator.pushNamed(context, RouteNames.myOrders);
                        }),
                        _navItem(context, Icons.local_offer_rounded, "Offers", false,
                            primary, onTap: () {}),
                        _navItem(context, Icons.person_rounded, "Profile", false, primary,
                            onTap: () {
                          Navigator.pushNamed(context, RouteNames.profile);
                        }),
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool isActive, Color primary, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? primary : AppColors.muted, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isActive ? primary : AppColors.muted))
        ],
      ),
    );
  }
}

class OrderStatusStepper extends StatelessWidget {
  final OrderModel order;
  const OrderStatusStepper({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final riderName = order.riderName ?? "The rider";

    if (status == FirestoreConstants.statusCancelled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Journey",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          _progressStep(
            icon: Icons.cancel,
            title: "Order Cancelled",
            subtitle: "This order was cancelled",
            primary: Colors.red,
            isCompleted: true,
            isLast: true,
            isActive: true,
          ),
        ],
      );
    }

    // ✅ Status steps as requested
    final steps = [
      'Pending',
      'Confirmed',
      'Preparing',
      'On the Way',
      'Delivered',
    ];

    final currentStep = steps.indexWhere(
      (s) => s.toLowerCase() == status.toLowerCase(),
    );

    // Handle "On the way" vs "On the Way" case sensitivity and missing intermediate states
    int activeIndex = currentStep;
    if (activeIndex == -1) {
       // Fallback for constants like "On the way"
       if (status.toLowerCase().contains('way')) {
         activeIndex = 3;
       } else if (status == FirestoreConstants.statusPending) {
         activeIndex = 0;
       } else if (status == FirestoreConstants.statusPreparing) {
         activeIndex = 2;
       } else if (status == FirestoreConstants.statusDelivered) {
         activeIndex = 4;
       } else {
         activeIndex = 0;
       }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Order Journey",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Current status: $status',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.subtle,
          ),
        ),
        const SizedBox(height: 24),
        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isDone = i <= activeIndex;
          final isCurrent = i == activeIndex;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.primary : AppColors.card2,
                      border: isDone ? null : Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      color: isDone ? Colors.white : AppColors.muted,
                      size: 16,
                    ),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: isDone ? AppColors.primary : AppColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isDone ? Colors.white : AppColors.muted,
                      ),
                    ),
                    if (isCurrent)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          i == 2 ? "Kitchen is working magic" : 
                          i == 3 ? "$riderName is on the way!" : 
                          i == 4 ? "Enjoy your pizza!" : "Processing your order",
                          style: const TextStyle(fontSize: 11, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _progressStep(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color primary,
      bool isActive = false,
      bool isCompleted = true,
      bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? primary : AppColors.card2,
                shape: BoxShape.circle,
                border: isCompleted ? null : Border.all(color: AppColors.border),
                boxShadow: isCompleted ? [
                  BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Icon(icon,
                  color: isCompleted ? Colors.white : AppColors.muted, size: isActive ? 20 : 16),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? primary.withValues(alpha: 0.5) : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive ? primary : (isCompleted ? Colors.white : AppColors.muted),
                      fontSize: isActive ? 15 : 14)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: isActive ? primary.withValues(alpha: 0.8) : AppColors.subtle)),
              const SizedBox(height: 20)
            ],
          ),
        ),
      ],
    );
  }
}



