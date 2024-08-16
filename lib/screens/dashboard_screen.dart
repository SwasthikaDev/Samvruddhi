import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/worker_management.dart';
import '../screens/chat_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show pi, cos;

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late GoogleMapController _mapController;
  Set<Polygon> _farmPolygons = {};

  // Mock data
  final Map<String, dynamic> mockFarmlands = {
    'farm1': {
      'name': 'Venur',
      'calculatedAcreage': 15.5,
      'crops': [
        {'name': 'Arecanut', 'averageProduce': 2000},
        {'name': 'Rambutan', 'averageProduce': 3000},
      ],
    },
    'farm2': {
      'name': 'Gardadi',
      'calculatedAcreage': 22.3,
      'crops': [
        {'name': 'Arecanut', 'averageProduce': 1500},
        {'name': 'Banana', 'averageProduce': 1800},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            SizedBox(width: 10),
            Text(
              'Samvruddhi',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.black),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: _buildDashboardContent(context, mockFarmlands),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen()),
          );
        },
        child: Icon(Icons.flash_on, color: Colors.white),
        backgroundColor: Colors.yellow[700],
        tooltip: 'Get Advisory from Vriddhi AI',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.dashboard, color: Colors.green),
              onPressed: () {
                // Dashboard is already active
              },
            ),
            IconButton(
              icon: Icon(Icons.eco, color: Colors.black),
              onPressed: () {
                // Navigate to Crops
              },
            ),
            SizedBox(width: 40), // Space for FAB
            IconButton(
              icon: Icon(Icons.analytics, color: Colors.black),
              onPressed: () {
                // Navigate to Price Analysis
              },
            ),
            IconButton(
              icon: Icon(Icons.group, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WorkerManagementScreen()),
                );
              },
            ),
          ],
        ),
        color: Colors.white,
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic> farmlands) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeatherWidget(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Farmlands',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Farm'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/farm_location');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: farmlands.length,
              itemBuilder: (context, index) {
                String farmId = farmlands.keys.elementAt(index);
                Map<String, dynamic> farmland = farmlands[farmId];
                return _buildFarmlandCard(farmId, farmland);
              },
            ),
            SizedBox(height: 20),
            Text(
              'Farm Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            _buildFarmOverview(farmlands),
            SizedBox(height: 20),
            Text(
              'Crop Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            _buildCropDistributionChart(),
            SizedBox(height: 20),
            Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Weather',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                '28°C',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Partly Cloudy',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          Icon(Icons.wb_sunny, size: 64, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildFarmlandCard(String farmId, Map<String, dynamic> farmland) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(farmland['name'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Area: ${farmland['calculatedAcreage'].toStringAsFixed(2)} acres'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crops:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...(farmland['crops'] as List<dynamic>).map((crop) {
                  return ListTile(
                    title: Text(crop['name']),
                    subtitle: Text('Avg. Produce: ${crop['averageProduce']} kg'),
                    leading: Icon(Icons.grass, color: Colors.green),
                  );
                }).toList(),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to detailed farm view
                  },
                  child: Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmOverview(Map<String, dynamic> farmlands) {
    double totalArea = farmlands.values.fold(0.0, (sum, farmland) => sum + farmland['calculatedAcreage']);
    int totalCrops = farmlands.values.fold(0, (sum, farmland) => sum + (farmland['crops'] as List).length);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewItem(Icons.landscape, 'Total Farms', '${farmlands.length}'),
            _buildOverviewItem(Icons.crop, 'Total Area', '${totalArea.toStringAsFixed(2)} acres'),
            _buildOverviewItem(Icons.eco, 'Total Crops', '$totalCrops'),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 16)),
          Spacer(),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCropDistributionChart() {
    return Container(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              color: Colors.green,
              value: 35,
              title: 'Arecanut',
              radius: 50,
              titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: Colors.yellow,
              value: 40,
              title: 'Pepper',
              radius: 60,
              titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: Colors.blue,
              value: 25,
              title: 'Soy',
              radius: 40,
              titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
          sectionsSpace: 0,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    List<Map<String, dynamic>> activities = [
      {'activity': 'Added new crop: Areca', 'icon': Icons.add_circle, 'color': Colors.green},
      {'activity': 'Updated worker schedule', 'icon': Icons.schedule, 'color': Colors.blue},
      {'activity': 'Received AI advisory on pest control', 'icon': Icons.bug_report, 'color': Colors.red},
    ];

    return Card(
      elevation: 4,
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(activities[index]['icon'], color: activities[index]['color']),
            title: Text(activities[index]['activity']),
          );
        },
      ),
    );
  }
}