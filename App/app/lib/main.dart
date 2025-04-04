import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'bluetooth_manager.dart'; // Import the BluetoothManager class

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glucose Monitoring',
      theme: ThemeData(
        primaryColor: Colors.lightBlue[100],
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(color: Colors.lightBlue[200]),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: Colors.blue[300],
        ),
      ),
      home: GlucoseMonitoringPage(),
    );
  }
}

class GlucoseMonitoringPage extends StatefulWidget {
  @override
  _GlucoseMonitoringPageState createState() => _GlucoseMonitoringPageState();
}

class _GlucoseMonitoringPageState extends State<GlucoseMonitoringPage> {
  BluetoothManager _bluetoothManager = BluetoothManager();
  String _status = "Not Connected";
  List<int> _glucoseValues = [];

  // Example data for graph
  final List<FlSpot> glucoseData = [
    FlSpot(0, 5.5), FlSpot(1, 6.1), FlSpot(2, 5.8), FlSpot(3, 6.5),
  ];

  List<String> history = ['6.0 mM - 12:00 PM', '5.8 mM - 1:00 PM', '6.2 mM - 2:00 PM'];

  Future<void> _connectToBluetoothDevice() async {
    setState(() {
      _status = "Connecting...";
    });

    final data = await _bluetoothManager.fetchBluetoothData();
    if (data != null) {
      setState(() {
        _status = "Data Received";
        _glucoseValues = data;
      });
    } else {
      setState(() {
        _status = "Failed to get data.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Glucose Monitoring')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Readings Tab
              Text("Device Readings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Status: $_status", style: TextStyle(fontSize: 16, color: Colors.blue[700])),
              SizedBox(height: 10),
              _glucoseValues.isEmpty
                  ? Text("No Data Yet", style: TextStyle(fontSize: 18, color: Colors.blue[700]))
                  : Column(
                      children: _glucoseValues.map((value) => Text("$value mM", style: TextStyle(fontSize: 16))).toList(),
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _connectToBluetoothDevice,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[300]),
                child: Text("Fetch Glucose Data"),
              ),
              SizedBox(height: 30),

              // Graph Tab
              Text("Glucose Levels Over Time", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Container(
                height: 300, // Add a fixed height to avoid layout issues
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.blue[300]!, width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: glucoseData,
                        isCurved: true,
                        color: Colors.blue[700]!,
                        barWidth: 4,
                        belowBarData: BarAreaData(show: true, color: Colors.blue[300]!.withOpacity(0.3)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // History Tab
              Text("History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SizedBox(
                height: 200,  // Add a fixed height to avoid unbounded height issue
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(history[index], style: TextStyle(color: Colors.blue[700])),
                    );
                  },
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
