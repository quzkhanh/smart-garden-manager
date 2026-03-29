
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoData {
  final String id;
  final String name;
  final String platform;

  DeviceInfoData({
    required this.id,
    required this.name,
    required this.platform,
  });
}

class DeviceInfoUtil {
  static Future<DeviceInfoData> getDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('saved_device_id');
    
    String deviceName = 'Unknown Device';
    String platform = 'unknown';

    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webBrowserInfo = await deviceInfo.webBrowserInfo;
        deviceName = 'Trình duyệt Web (${webBrowserInfo.browserName.name})';
        platform = 'web';
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final androidInfo = await deviceInfo.androidInfo;
            // Build ID + Model + Serial (if available)
            final stableId = 'and-${androidInfo.id}-${androidInfo.model}';
            deviceId = stableId;
            deviceName = '${androidInfo.manufacturer.toUpperCase()} ${androidInfo.model}';
            platform = 'mobile';
            break;
          case TargetPlatform.iOS:
            final iosInfo = await deviceInfo.iosInfo;
            deviceId = iosInfo.identifierForVendor ?? deviceId;
            deviceName = iosInfo.name;
            platform = iosInfo.model.toLowerCase().contains("ipad")
                ? 'tablet'
                : 'mobile';
            break;
          case TargetPlatform.windows:
            final windowsInfo = await deviceInfo.windowsInfo;
            deviceId = 'win-${windowsInfo.computerName}';
            deviceName = windowsInfo.computerName;
            platform = 'web';
            break;
          case TargetPlatform.macOS:
            final macOsInfo = await deviceInfo.macOsInfo;
            deviceId = 'mac-${macOsInfo.computerName}';
            deviceName = macOsInfo.computerName;
            platform = 'web';
            break;
          case TargetPlatform.linux:
            final linuxInfo = await deviceInfo.linuxInfo;
            deviceId = 'lin-${linuxInfo.id}';
            deviceName = linuxInfo.name;
            platform = 'web';
            break;
          default:
            break;
        }
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    // Fallback if no stable ID was found and no saved ID exists
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('saved_device_id', deviceId);
    } else {
      // Sync it to prefs just in case we need it later
      await prefs.setString('saved_device_id', deviceId);
    }

    return DeviceInfoData(
      id: deviceId,
      name: deviceName,
      platform: platform,
    );
  }
}
