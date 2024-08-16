// lib/screens/crop_info_screen.dart
import 'package:flutter/material.dart';

class CropInfoScreen extends StatefulWidget {
  final Map<String, dynamic> farmData;
  CropInfoScreen({required this.farmData});

  @override
  _CropInfoScreenState createState() => _CropInfoScreenState();
}

class _CropInfoScreenState extends State<CropInfoScreen> {
  List<Map<String, dynamic>> _crops = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crop Information')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _crops.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_crops[index]['name']),
                  subtitle: Text('Area: ${_crops[index]['area']} acres'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _crops.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _showAddCropDialog();
              },
              child: Text('Add Crop'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _crops.isNotEmpty
                  ? () {
                Navigator.pushNamed(context, '/worker_info', arguments: {
                  ...widget.farmData,
                  'crops': _crops,
                });
              }
                  : null,
              child: Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCropDialog() {
    String cropName = '';
    double cropArea = 0;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Crop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Crop Name'),
                onChanged: (value) => cropName = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Area (acres)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => cropArea = double.tryParse(value) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (cropName.isNotEmpty && cropArea > 0) {
                  setState(() {
                    _crops.add({'name': cropName, 'area': cropArea});
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}