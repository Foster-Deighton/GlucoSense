// web/bluetooth.js

async function requestBluetoothDevice() {
    try {
      const device = await navigator.bluetooth.requestDevice({
        acceptAllDevices: true,
        optionalServices: ['battery_service'] // Replace with your service UUID
      });
      
      const server = await device.gatt.connect();
      const service = await server.getPrimaryService('battery_service'); // Replace with your service UUID
      const characteristic = await service.getCharacteristic('battery_level'); // Replace with your characteristic UUID
  
      // Now you can read or listen for notifications from the characteristic
      const value = await characteristic.readValue();
      return Array.from(value.buffer); // Convert value to array
    } catch (error) {
      console.log("Bluetooth error:", error);
      return null;
    }
  }
  