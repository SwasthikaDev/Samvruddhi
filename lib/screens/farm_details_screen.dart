// lib/screens/farm_details_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FarmDetailsScreen extends StatefulWidget {
  final List<LatLng> farmLocation;
  FarmDetailsScreen({required this.farmLocation});

  @override
  _FarmDetailsScreenState createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _farmName = '';
  double _acres = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Farm Details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Farm Name'),
              validator: (value) => value!.isEmpty ? 'Please enter a farm name' : null,
              onSaved: (value) => _farmName = value!,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Acres'),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Please enter the farm size' : null,
              onSaved: (value) => _acres = double.parse(value!),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  // Save farm details and navigate to next screen
                  Navigator.pushNamed(context, '/crop_info', arguments: {
                    'location': widget.farmLocation,
                    'name': _farmName,
                    'acres': _acres,
                  });
                }
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}