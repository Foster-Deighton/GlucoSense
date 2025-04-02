import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glucose Monitoring',
      theme: ThemeData(primarySwatch: Colors.blue),
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

// Tab 1: Device Readings
class DeviceReadingsTab extends StatefulWidget {
  @override
  _DeviceReadingsTabState createState() => _DeviceReadingsTabState();
}

class _DeviceReadingsTabState extends State<DeviceReadingsTab> {
  String _latestReading = 'No Data';
  String _lastUpdated = 'Never';

  Future<void> _fetchDeviceReading() async {
    try {
      final response = await http.get(Uri.parse('http://YOUR_ESP32_IP/data'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _latestReading = '${data['glucose']} mM';
          _lastUpdated = DateTime.now().toLocal().toString();
        });
      }
    } catch (e) {
      setState(() {
        _latestReading = 'Error fetching data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Latest Glucose Reading: $_latestReading', style: TextStyle(fontSize: 18)),
          Text('Last Updated: $_lastUpdated', style: TextStyle(fontSize: 14, color: Colors.grey)),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _fetchDeviceReading, child: Text('Fetch Latest Reading')),
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
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.blue, width: 2)),
          lineBarsData: [
            LineChartBarData(
              spots: glucoseData,
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
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
          title: Text(history[index]),
        );
      },
    );
  }
}
