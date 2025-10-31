import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_localizations.dart';
import '../../constants.dart';

final BitmapDescriptor _branchPinIcon =
    BitmapDescriptor.fromAssetImage('assets/icons/branch_pin.png');

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final List<Branch> _branches = _branchData;
  late Branch _activeBranch = _branches.first;
  YandexMapController? _mapController;

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

  Future<void> _onMapCreated(YandexMapController controller) async {
    _mapController = controller;
    await _moveToBranch(_activeBranch, animate: false);
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
    if (_activeBranch == branch) return;
    setState(() => _activeBranch = branch);
    await _moveToBranch(branch);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: SafeArea(
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
                  padding: const EdgeInsets.only(bottom: 24),
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
    final url = Uri.parse(
      'https://yandex.com/maps/?pt=${branch.point.longitude},${branch.point.latitude}&z=16&l=map',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open maps application.')),
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
                  label: const Text(
                    'Directions',
                    style: TextStyle(fontWeight: FontWeight.w600),
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

class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.point,
  });

  final String id;
  final String name;
  final String address;
  final Point point;
}

const List<Branch> _branchData = [
  Branch(
    id: 'sardoba-geofizika',
    name: 'Sardoba (Geofizika)',
    address: 'Geofizika koʻchasi, Bukhara viloyati',
    point: Point(latitude: 39.73954, longitude: 64.496507),
  ),
  Branch(
    id: 'sardoba-gijdivon',
    name: 'Sardoba (Gijdivon)',
    address: 'Gijdivon tumani, Bukhara viloyati',
    point: Point(latitude: 40.102919, longitude: 64.678470),
  ),
  Branch(
    id: 'sardoba-severniy',
    name: 'Sardoba (Severniy)',
    address: 'Severniy mavzesi, Bukhara viloyati',
    point: Point(latitude: 39.747994, longitude: 64.422354),
  ),
  Branch(
    id: 'sardoba-bukhara',
    name: 'Sardoba (Bukhara)',
    address: 'Bukhara shahar, Buxoro viloyati',
    point: Point(latitude: 39.7747, longitude: 64.4286),
  ),
];
