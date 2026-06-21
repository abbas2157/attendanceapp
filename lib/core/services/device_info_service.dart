import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  static Future<String> attendanceDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        return [
          'android',
          info.manufacturer,
          info.model,
          'sdk_${info.version.sdkInt}',
          info.id,
        ].where((value) => value.trim().isNotEmpty).join(' | ');
      }

      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        return [
              'ios',
              info.name,
              info.model,
              info.systemVersion,
              info.identifierForVendor,
            ]
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .join(' | ');
      }
    } catch (_) {
      // Device info is useful audit metadata, but attendance must not fail only
      // because the platform API could not be read.
    }

    return Platform.operatingSystem;
  }
}
