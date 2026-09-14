/// How the app reaches the FabriCare API on a physical Android phone.
///
/// - `usb` — phone plugged into PC via USB; run once per session:
///   `adb reverse tcp:5000 tcp:5000`
/// - `wifi` — phone and PC on the same Wi‑Fi; set [wifiHost] to your PC IPv4
///   from `ipconfig` (Wi‑Fi adapter).
/// - `null` — Android emulator only (uses 10.0.2.2).
enum DevApiConnectionMode { usb, wifi }

const DevApiConnectionMode kDevApiConnectionMode = DevApiConnectionMode.usb;
const String kDevApiWifiHost = '192.168.1.48';

String? get kDevApiHostOverride {
  switch (kDevApiConnectionMode) {
    case DevApiConnectionMode.usb:
      return '127.0.0.1';
    case DevApiConnectionMode.wifi:
      return kDevApiWifiHost;
  }
}
