import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../app_localizations.dart';
import '../../constants.dart';
import '../../models/branch.dart';
import '../../services/branch_state.dart';

final BitmapDescriptor _branchPinIcon =
    BitmapDescriptor.fromAssetImage('assets/icons/branch_pin.png');

const Point _initialBukharaCenter =
    Point(latitude: 39.772500, longitude: 64.432500);
const double _initialBukharaZoom = 13.2;

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final BranchState _branchState = BranchState.instance;
  late Branch _activeBranch = _branchState.activeBranch;
  YandexMapController? _mapController;
  bool _hasPromptedForLocation = false;
  bool _isRequestingLocation = false;

  @override
  void initState() {
    super.initState();
    _branchState.addListener(_handleGlobalBranchChange);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybePromptForLocation());
  }

  @override
  void dispose() {
    _branchState.removeListener(_handleGlobalBranchChange);
    super.dispose();
  }

  void _handleGlobalBranchChange() {
    final branch = _branchState.activeBranch;
    if (_activeBranch.id == branch.id) return;
    setState(() => _activeBranch = branch);
    _moveToBranch(branch);
  }

  List<Branch> get _branches => _branchState.branches;

  List<MapObject> get _mapObjects {
    return _branches.map((branch) {
      final isActive = branch == _activeBranch;
      return PlacemarkMapObject(
        mapId: MapObjectId(branch.id),
        point: branch.point,
        consumeTapEvents: true,
        opacity: isActive ? 1.0 : 0.72,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: _branchPinIcon,
            scale: isActive ? 1.15 : 0.95,
          ),
        ),
        onTap: (_, __) => _selectBranch(branch),
      );
    }).toList();
  }

  Future<void> _maybePromptForLocation() async {
    if (!mounted || _branches.isEmpty) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await _useCurrentLocation();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _hasPromptedForLocation = true;
      if (!mounted) return;
      _showLocationSnack(
        AppLocalizations.of(context).locationPermissionDeniedMessage,
      );
      return;
    }

    if (_hasPromptedForLocation) return;
    _hasPromptedForLocation = true;

    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    final allowAccess = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) => _LocationPermissionSheet(strings: strings),
        ) ??
        false;

    if (!mounted || !allowAccess) return;
    await _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (!mounted) return;

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await _useCurrentLocation();
      return;
    }

    _showLocationSnack(
      AppLocalizations.of(context).locationPermissionDeniedMessage,
    );
  }

  Future<void> _useCurrentLocation() async {
    if (!mounted || _isRequestingLocation) return;
    _isRequestingLocation = true;
    try {
      final strings = AppLocalizations.of(context);
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationSnack(strings.locationServicesDisabledMessage);
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userPoint = Point(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final nearest = _nearestBranchTo(userPoint);
      if (nearest != null) {
        _branchState.selectBranch(nearest);
      }
    } catch (error) {
      debugPrint('Failed to determine location: $error');
    } finally {
      _isRequestingLocation = false;
    }
  }

  Branch? _nearestBranchTo(Point userPoint) {
    if (_branches.isEmpty) return null;
    Branch? closest;
    double minDistance = double.infinity;
    for (final branch in _branches) {
      final distance = _distanceMeters(branch.point, userPoint);
      if (distance < minDistance) {
        minDistance = distance;
        closest = branch;
      }
    }
    return closest;
  }

  double _distanceMeters(Point a, Point b) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final aCalc = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(aCalc), math.sqrt(1 - aCalc));
    return earthRadius * c;
  }

  double _degToRad(double value) => value * math.pi / 180.0;

  void _showLocationSnack(String message) {
    if (!mounted || message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _mapController = controller;
    final isDefaultBranchActive =
        _branches.isNotEmpty && _activeBranch.id == _branches.first.id;
    if (isDefaultBranchActive) {
      await _showBukharaOverview();
    } else {
      await _moveToBranch(_activeBranch, animate: false);
    }
  }

  Future<void> _showBukharaOverview() async {
    if (_mapController == null) return;
    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _initialBukharaCenter,
          zoom: _initialBukharaZoom,
        ),
      ),
    );
  }

  Future<void> _moveToBranch(Branch branch, {bool animate = true}) async {
    if (_mapController == null) return;
    final update = CameraUpdate.newCameraPosition(
      CameraPosition(target: branch.point, zoom: 15.2),
    );
    if (animate) {
      await _mapController!.moveCamera(
        update,
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1,
        ),
      );
    } else {
      await _mapController!.moveCamera(update);
    }
  }

  Future<void> _selectBranch(Branch branch) async {
    if (_activeBranch.id == branch.id) return;
    _branchState.selectBranch(branch);
  }

  Future<void> _zoomBy(double delta) async {
    if (_mapController == null) return;
    final cameraPosition = await _mapController!.getCameraPosition();
    final nextZoom = (cameraPosition.zoom + delta).clamp(3.0, 19.0);
    await _mapController!.moveCamera(
      CameraUpdate.zoomTo(nextZoom),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final double listBottomPadding = navAwareBottomPadding(context, extra: 24);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(defaultPadding, 20, defaultPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.locationsTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.changeBranchSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _MapContainer(
                  mapObjects: _mapObjects,
                  onMapCreated: _onMapCreated,
                  onZoomIn: () => _zoomBy(1.0),
                  onZoomOut: () => _zoomBy(-1.0),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.locationsListHeader,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.only(bottom: listBottomPadding),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _branches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    final isActive = branch == _activeBranch;
                    return _BranchCard(
                      branch: branch,
                      l10n: l10n,
                      isActive: isActive,
                      onTap: () => _selectBranch(branch),
                      onDirections: () => _openDirections(branch),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDirections(Branch branch) async {
    final l10n = AppLocalizations.of(context);
    final url = Uri.parse(
      'https://yandex.com/maps/?pt=${branch.point.longitude},${branch.point.latitude}&z=16&l=map',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationsDirectionsError)),
      );
    }
  }
}

class _MapContainer extends StatelessWidget {
  const _MapContainer({
    required this.mapObjects,
    required this.onMapCreated,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final List<MapObject> mapObjects;
  final MapCreatedCallback onMapCreated;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            YandexMap(
              onMapCreated: onMapCreated,
              mapObjects: mapObjects,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              zoomGesturesEnabled: true,
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  _ZoomButton(
                    icon: Icons.add,
                    onPressed: onZoomIn,
                  ),
                  const SizedBox(height: 12),
                  _ZoomButton(
                    icon: Icons.remove,
                    onPressed: onZoomOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPermissionSheet extends StatelessWidget {
  const _LocationPermissionSheet({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.locationPermissionTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.locationPermissionDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: bodyTextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: bodyTextColor,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(strings.locationPermissionDeny),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(strings.locationPermissionAllow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              strings.locationPermissionHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: bodyTextColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 44,
          width: 44,
          child: Icon(icon, color: titleColor),
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.isActive,
    required this.onTap,
    required this.l10n,
    required this.onDirections,
  });

  final Branch branch;
  final bool isActive;
  final VoidCallback onTap;
  final AppStrings l10n;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: kDefaultDuration,
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive
                  ? primaryColor.withValues(alpha: 0.28)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      branch.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isActive ? primaryColor : bodyTextColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                branch.address,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyTextColor,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatusBadge(label: l10n.openNow),
                  const SizedBox(width: 12),
                  Text(
                    l10n.dailySchedule,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: bodyTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDirections,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: Text(
                    l10n.locationsDirectionsButton,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: primaryColor, size: 10),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
