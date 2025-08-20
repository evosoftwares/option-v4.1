import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapStyleService {
  const MapStyleService._();

  // Minimal styles to reduce clutter and respect theme brightness
  static const String _lightStyle =
      '[{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]}]';

  static const String _darkStyle =
      '[{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},{"elementType":"geometry","stylers":[{"saturation":-100},{"lightness":-20}]}]';

  static String styleFor(Brightness brightness) {
    return brightness == Brightness.dark ? _darkStyle : _lightStyle;
  }

  static Future<void> applyForContext(
    GoogleMapController controller,
    BuildContext context,
  ) async {
    final brightness = Theme.of(context).brightness;
    final style = styleFor(brightness);
    try {
      await controller.setMapStyle(style);
    } catch (_) {
      // Ignore style application errors to avoid disrupting map initialization
    }
  }
}