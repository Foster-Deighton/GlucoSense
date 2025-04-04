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
      home: GlucoseTabs(),
    );
  }
}

class GlucoseTabs extends StatefulWidget {
  @override
  _GlucoseTabsState createState() => _GlucoseTabsState();
}

class _GlucoseTabsState extends State<GlucoseTabs> {
  int _selectedIndex = 0;
  final List<Widget> _tabs = [
    DeviceReadingsTab(),
    GraphTab(),
    HistoryTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Glucose Monitoring')),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'Device'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Graph'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class DeviceReadingsTab extends StatefulWidget {
  @override
  _DeviceReadingsTabState createState() => _DeviceReadingsTabState();
}

class _DeviceReadingsTabState extends State<DeviceReadingsTab> {
  BluetoothManager _bluetoothManager = BluetoothManager();
  String _status = "Not Connected";
  List<int> _glucoseValues = [];

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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
        ],
      ),
    );
  }
}

// Tab 2: Graph
class GraphTab extends StatelessWidget {
  final List<FlSpot> glucoseData = [
    FlSpot(0, 5.5), FlSpot(1, 6.1), FlSpot(2, 5.8), FlSpot(3, 6.5),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
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
            )
          ],
        ),
      ),
    );
  }
}

// Tab 3: History
class HistoryTab extends StatefulWidget {
  @override
  _HistoryTabState createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<String> history = ['6.0 mM - 12:00 PM', '5.8 mM - 1:00 PM', '6.2 mM - 2:00 PM'];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(history[index], style: TextStyle(color: Colors.blue[700])),
        );
      },
    );
  }
}
