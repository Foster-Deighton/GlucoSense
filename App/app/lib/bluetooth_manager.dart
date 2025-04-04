import 'dart:js' as js;

class BluetoothManager {
  // Call the JavaScript function to request Bluetooth device
  Future<List<int>?> fetchBluetoothData() async {
    try {
      // Calling the JS function from the web/bluetooth.js file
      final result = await js.context.callMethod('requestBluetoothDevice');
      return List<int>.from(result);
    } catch (e) {
      print('Error fetching Bluetooth data: $e');
      return null;
    }
  }
}
