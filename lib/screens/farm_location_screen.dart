import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show pi, sin, cos, sqrt, atan2;

class Farmland {
  String name;
  double estimatedAcreage;
  double calculatedAcreage;
  List<Crop> crops;
  List<LatLng> points;
  Color color;

  Farmland({
    required this.name,
    required this.estimatedAcreage,
    required this.calculatedAcreage,
    required this.crops,
    required this.points,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'estimatedAcreage': estimatedAcreage,
      'calculatedAcreage': calculatedAcreage,
      'crops': crops.map((c) => c.toMap()).toList(),
      'points': points.map((p) => {'latitude': p.latitude, 'longitude': p.longitude}).toList(),
      'color': color.value,
    };
  }
}

class Crop {
  String name;
  double averageProduce;
  double averageSellingPrice;
  String problemsFaced;
  double averageExpense;

  Crop({
    required this.name,
    required this.averageProduce,
    required this.averageSellingPrice,
    required this.problemsFaced,
    required this.averageExpense,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'averageProduce': averageProduce,
      'averageSellingPrice': averageSellingPrice,
      'problemsFaced': problemsFaced,
      'averageExpense': averageExpense,
    };
  }
}

class FarmLocationScreen extends StatefulWidget {
  @override
  _FarmLocationScreenState createState() => _FarmLocationScreenState();
}

class _FarmLocationScreenState extends State<FarmLocationScreen> {
  GoogleMapController? _mapController;
  List<LatLng> _selectedLocations = [];
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  bool _isInitialLoad = true;
  double _estimatedAcreage = 0.0;
  List<List<Farmland>> _locationHistory = [];
  int _currentHistoryIndex = -1;
  List<Farmland> _farmlands = [];
  int _farmlandCounter = 1;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _estimatedAcreageController = TextEditingController();
  final _calculatedAcreageController = TextEditingController();
  List<CropFormField> _cropFields = [];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showHelpDialog());
    _addCropField();
  }

  void _requestLocationPermission() async {
    if (await Permission.location.request().isGranted) {
      _getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Location permission is required to use this feature.'),
      ));
    }
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      if (_isInitialLoad && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 18));
        _isInitialLoad = false;
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _addPolygon() {
    setState(() {
      _polygons.clear();
      _polylines.clear();

      if (_selectedLocations.length > 2) {
        _polygons.add(Polygon(
          polygonId: PolygonId('current_polygon'),
          points: _selectedLocations,
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.15),
        ));
      } else if (_selectedLocations.length == 2) {
        _polylines.add(Polyline(
          polylineId: PolylineId('current_polyline'),
          points: _selectedLocations,
          width: 2,
          color: Colors.red,
        ));
      }

      _estimatedAcreage = _calculateAcreage(_selectedLocations);
      _calculatedAcreageController.text = _estimatedAcreage.toStringAsFixed(2);
    });
  }

  void _saveCurrentState() {
    _locationHistory = _locationHistory.sublist(0, _currentHistoryIndex + 1);
    _locationHistory.add(_farmlands.map((f) => Farmland(
      name: f.name,
      estimatedAcreage: f.estimatedAcreage,
      calculatedAcreage: f.calculatedAcreage,
      crops: List<Crop>.from(f.crops),
      points: List<LatLng>.from(f.points),
      color: f.color,
    )).toList());
    _currentHistoryIndex = _locationHistory.length - 1;
  }

  void _undo() {
    if (_selectedLocations.isNotEmpty) {
      setState(() {
        _selectedLocations.removeLast();
        _addPolygon();
        _saveCurrentState();
      });
    }
  }

  void _redo() {
    if (_currentHistoryIndex < _locationHistory.length - 1) {
      setState(() {
        _currentHistoryIndex++;
        _farmlands = _locationHistory[_currentHistoryIndex].map((f) => Farmland(
          name: f.name,
          estimatedAcreage: f.estimatedAcreage,
          calculatedAcreage: f.calculatedAcreage,
          crops: List<Crop>.from(f.crops),
          points: List<LatLng>.from(f.points),
          color: f.color,
        )).toList();
        _selectedLocations = _farmlands.isNotEmpty ? _farmlands.last.points : [];
        _addPolygon();
      });
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('How to Select Farm Land'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Tap on the map to add corner points of your farm.'),
              Text('2. The farm boundary will be drawn as you add points.'),
              Text('3. Use the undo and redo buttons to correct mistakes.'),
              Text('4. Fill in the form below the map with farm details.'),
              Text('5. Press "Save" when you\'re done selecting your farm area and filling the form.'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Got it!'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  double _calculateAcreage(List<LatLng> points) {
    if (points.length < 3) return 0;

    double area = 0;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      area += (points[j].longitude + points[i].longitude) *
          (points[j].latitude - points[i].latitude);
      j = i;
    }

    area = area.abs() * 0.5;
    // Convert square degrees to square meters
    double areaInSquareMeters = area * 111319.9 * 111319.9 * cos(points[0].latitude * pi / 180);
    // Convert square meters to acres
    return areaInSquareMeters * 0.000247105;
  }

  void _addCropField() {
    setState(() {
      _cropFields.add(CropFormField(
        key: GlobalKey<_CropFormFieldState>(),
        onRemove: () {
          setState(() {
            _cropFields.removeLast();
          });
        },
      ));
    });
  }

  List<Crop> getCrops() {
    return _cropFields.map((cropField) {
      final state = cropField.key as GlobalKey<_CropFormFieldState>;
      return state.currentState!.toCrop();
    }).toList();
  }

  void _saveFarmland() async {
    if (_formKey.currentState!.validate() && _selectedLocations.length >= 3) {
      _formKey.currentState!.save();

      final newFarmland = Farmland(
        name: _nameController.text,
        estimatedAcreage: double.parse(_estimatedAcreageController.text),
        calculatedAcreage: double.parse(_calculatedAcreageController.text),
        crops: getCrops(),
        points: _selectedLocations,
        color: Colors.primaries[_farmlands.length % Colors.primaries.length],
      );

      setState(() {
        _farmlands.add(newFarmland);
        _addPolygon();
        _saveCurrentState();
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('farmlands')
              .add(newFarmland.toMap());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Farmland saved successfully')),
          );
        }
      } catch (e) {
        print('Error saving farmland: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving farmland')),
        );
      }

      // Clear form and selected locations
      _nameController.clear();
      _estimatedAcreageController.clear();
      _calculatedAcreageController.clear();
      _cropFields.clear();
      _addCropField();
      setState(() {
        _selectedLocations.clear();
        _polygons.clear();
        _polylines.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select a valid area on the map')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Farm Location'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: GoogleMap(
                mapType: MapType.hybrid,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 18,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 18));
                },
                onTap: (LatLng location) {
                  setState(() {
                    _selectedLocations.add(location);
                    _addPolygon();
                    _saveCurrentState();
                  });
                },
                markers: {
                  if (_currentLocation != null)
                    Marker(
                      markerId: MarkerId('current_location'),
                      position: _currentLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: InfoWindow(title: 'Your Location'),
                    ),
                  ..._selectedLocations.mapIndexed((index, point) => Marker(
                    markerId: MarkerId('point_$index'),
                    position: point,
                    draggable: true,
                    onDragEnd: (LatLng newPosition) {
                      setState(() {
                        _selectedLocations[index] = newPosition;
                        _addPolygon();
                        _saveCurrentState();
                      });
                    },
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: InfoWindow(title: 'Point ${index + 1}'),
                  )),
                },
                polygons: _polygons,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Area: ${_estimatedAcreage.toStringAsFixed(2)} acres',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.undo),
                            label: Text('Undo'),
                            onPressed: _selectedLocations.isNotEmpty ? _undo : null,
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.redo),
                            label: Text('Redo'),
                            onPressed: _currentHistoryIndex < _locationHistory.length - 1 ? _redo : null,
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.clear_all),
                            label: Text('Clear All'),
                            onPressed: () {
                              setState(() {
                                _selectedLocations.clear();
                                _polygons.clear();
                                _polylines.clear();
                                _estimatedAcreage = 0.0;
                                _farmlands.clear();
                                _locationHistory.clear();
                                _currentHistoryIndex = -1;
                                _farmlandCounter = 1;
                                _nameController.clear();
                                _estimatedAcreageController.clear();
                                _calculatedAcreageController.clear();
                                _cropFields.clear();
                                _addCropField();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Farm Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Farm Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a farm name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _estimatedAcreageController,
                          decoration: InputDecoration(
                            labelText: 'Estimated Acreage',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter estimated acreage';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _calculatedAcreageController,
                          decoration: InputDecoration(
                            labelText: 'Acreage According to Map Calculation',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                        SizedBox(height: 24),
                        Text('Crops Grown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ..._cropFields,
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add Another Crop'),
                          onPressed: _addCropField,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveFarmland,
                          child: Text('Save Farmland'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved Farmlands', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      ..._farmlands.map((farmland) => Card(
                        child: ListTile(
                          title: Text(farmland.name),
                          subtitle: Text('${farmland.calculatedAcreage.toStringAsFixed(2)} acres'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editFarmland(farmland),
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to dashboard
                  Navigator.of(context).pop();
                },
                child: Text('Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editFarmland(Farmland farmland) {
    _nameController.text = farmland.name;
    _estimatedAcreageController.text = farmland.estimatedAcreage.toString();
    _calculatedAcreageController.text = farmland.calculatedAcreage.toString();
    _selectedLocations = farmland.points;
    _cropFields.clear();
    for (var crop in farmland.crops) {
      _cropFields.add(CropFormField(
        key: GlobalKey<_CropFormFieldState>(),
        initialCrop: crop,
        onRemove: () {
          setState(() {
            _cropFields.removeLast();
          });
        },
      ));
    }
    _addPolygon();
    setState(() {});
  }
}

class CropFormField extends StatefulWidget {
  final VoidCallback onRemove;
  final Crop? initialCrop;

  CropFormField({Key? key, required this.onRemove, this.initialCrop}) : super(key: key);

  @override
  _CropFormFieldState createState() => _CropFormFieldState();
}

class _CropFormFieldState extends State<CropFormField> {
  final _nameController = TextEditingController();
  final _averageProduceController = TextEditingController();
  final _averageSellingPriceController = TextEditingController();
  final _problemsFacedController = TextEditingController();
  final _averageExpenseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCrop != null) {
      _nameController.text = widget.initialCrop!.name;
      _averageProduceController.text = widget.initialCrop!.averageProduce.toString();
      _averageSellingPriceController.text = widget.initialCrop!.averageSellingPrice.toString();
      _problemsFacedController.text = widget.initialCrop!.problemsFaced;
      _averageExpenseController.text = widget.initialCrop!.averageExpense.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Crop Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a crop name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _averageProduceController,
              decoration: InputDecoration(labelText: 'Average Produce in kg'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter average produce';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _averageSellingPriceController,
              decoration: InputDecoration(labelText: 'Average Selling Price per kg'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter average selling price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _problemsFacedController,
              decoration: InputDecoration(labelText: 'Problems Faced (if any) with growing this Crop'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter problems faced';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _averageExpenseController,
              decoration: InputDecoration(labelText: 'Estimated Total Expense to Grow This Crop'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter average expense';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRemove,
              child: Text('Remove Crop'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Crop toCrop() {
    return Crop(
      name: _nameController.text,
      averageProduce: double.parse(_averageProduceController.text),
      averageSellingPrice: double.parse(_averageSellingPriceController.text),
      problemsFaced: _problemsFacedController.text,
      averageExpense: double.parse(_averageExpenseController.text),
    );
  }
}

extension ListMapIndexed<T> on List<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) sync* {
    for (var index = 0; index < length; index++) {
      yield f(index, this[index]);
    }
  }
}