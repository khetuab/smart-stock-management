import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/google_maps_parser.dart';
import 'ethiopia_map_widget.dart';

/// "Set exact location" helper for the admin branch form.
///
/// Three ways to get a precise pin into the latitude / longitude fields:
///   1. Open Google Maps → drop a pin → Share → Copy link → "Paste link"
///   2. Paste (or type) a Google Maps link / "lat, lng" in the box
///   3. "My location" — uses the phone's GPS (stand inside the shop)
///
/// Whatever is found is validated against the real Ethiopia border and
/// written into [latCtrl] / [lngCtrl]. A "Verify" button reopens the saved
/// point in Google Maps so the admin can double-check it.
class MapsLocationPicker extends StatefulWidget {
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;

  /// Used only to pre-fill the Google Maps search ("Bole Branch Addis Ababa").
  final TextEditingController nameCtrl;
  final TextEditingController cityCtrl;

  const MapsLocationPicker({
    super.key,
    required this.latCtrl,
    required this.lngCtrl,
    required this.nameCtrl,
    required this.cityCtrl,
  });

  @override
  State<MapsLocationPicker> createState() => _MapsLocationPickerState();
}

class _MapsLocationPickerState extends State<MapsLocationPicker> {
  final TextEditingController _linkCtrl = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  double? get _lat => double.tryParse(widget.latCtrl.text.trim());
  double? get _lng => double.tryParse(widget.lngCtrl.text.trim());

  void _setMsg(String m, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = m;
      _isError = error;
    });
  }

  /// Validates and writes the point into the form fields.
  bool _apply(double lat, double lng) {
    if (!EthiopiaProjection.isInsideEthiopia(lat, lng)) {
      _setMsg(
        'That point is outside Ethiopia. Check the link and try again.'.tr,
        error: true,
      );
      return false;
    }
    widget.latCtrl.text = lat.toStringAsFixed(6);
    widget.lngCtrl.text = lng.toStringAsFixed(6);
    _setMsg('${'Exact location set'.tr}: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}');
    return true;
  }

  Future<void> _openMaps() async {
    final lat = _lat, lng = _lng;
    String query;
    if (lat != null && lng != null) {
      query = '$lat,$lng';
    } else {
      final parts = [widget.nameCtrl.text.trim(), widget.cityCtrl.text.trim()]
          .where((e) => e.isNotEmpty)
          .toList();
      query = parts.isEmpty ? 'Ethiopia' : '${parts.join(' ')} Ethiopia';
    }
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _setMsg('Could not open Google Maps.'.tr, error: true);
    } catch (_) {
      _setMsg('Could not open Google Maps.'.tr, error: true);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      _setMsg('Clipboard is empty. Copy a Google Maps link first.'.tr, error: true);
      return;
    }
    _linkCtrl.text = text;
    await _resolve(text);
  }

  Future<void> _resolve([String? raw]) async {
    final text = (raw ?? _linkCtrl.text).trim();
    if (text.isEmpty) {
      await _paste();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final coords = await GoogleMapsParser.resolve(text);
    if (!mounted) return;
    setState(() => _busy = false);

    if (coords == null) {
      _setMsg(
        'Could not read a location from that. In Google Maps, long-press the spot, '
            'copy the coordinates shown at the top (e.g. 9.0305, 38.7449) and paste them here.'
            .tr,
        error: true,
      );
      return;
    }
    _apply(coords.lat, coords.lng);
  }

  Future<void> _useMyLocation() async {
    setState(() => _busy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setMsg('Turn on location (GPS) on your phone first.'.tr, error: true);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _setMsg('Location permission is denied. Allow it in phone settings.'.tr, error: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (_apply(pos.latitude, pos.longitude)) {
        _setMsg(
          '${'Exact location set from GPS'.tr} (±${pos.accuracy.round()} m): '
              '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
        );
      }
    } catch (_) {
      _setMsg('Could not get your location. Try again near a window or outside.'.tr, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final lat = _lat, lng = _lng;
    if (lat == null || lng == null) return;
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$lat,$lng'});
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _setMsg('Could not open Google Maps.'.tr, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MejlisPalette.emerald.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MejlisPalette.gold.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pin_drop_rounded, size: 20, color: MejlisPalette.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Exact location (Google Maps)'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Open Google Maps, find the shop, long-press to drop a pin, tap Share → Copy link, '
                'then come back and tap Paste link.'
                .tr,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PickButton(icon: Icons.map_rounded, label: 'Open Google Maps'.tr, onTap: _busy ? null : _openMaps),
              _PickButton(icon: Icons.content_paste_rounded, label: 'Paste link'.tr, onTap: _busy ? null : _paste),
              _PickButton(icon: Icons.my_location_rounded, label: 'My location'.tr, onTap: _busy ? null : _useMyLocation),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _linkCtrl,
            minLines: 1,
            maxLines: 2,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _resolve(),
            decoration: InputDecoration(
              labelText: 'Google Maps link or coordinates'.tr,
              hintText: 'https://maps.app.goo.gl/…   or   9.0305, 38.7449',
              prefixIcon: const Icon(Icons.link_rounded, size: 19),
              suffixIcon: _busy
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : IconButton(
                tooltip: 'Get location'.tr,
                icon: Icon(Icons.check_circle_rounded, color: MejlisPalette.emerald),
                onPressed: () => _resolve(),
              ),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                  size: 16,
                  color: _isError ? scheme.error : MejlisPalette.emerald,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isError ? scheme.error : MejlisPalette.emerald,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // "Verify" appears whenever the lat/lng fields hold a valid point.
          AnimatedBuilder(
            animation: Listenable.merge([widget.latCtrl, widget.lngCtrl]),
            builder: (context, _) {
              if (_lat == null || _lng == null) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _verify,
                  icon: const Icon(Icons.travel_explore_rounded, size: 18),
                  label: Text('Verify this point in Google Maps'.tr),
                  style: TextButton.styleFrom(
                    foregroundColor: MejlisPalette.goldDark,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: MejlisPalette.emerald,
        side: BorderSide(color: MejlisPalette.emerald.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}