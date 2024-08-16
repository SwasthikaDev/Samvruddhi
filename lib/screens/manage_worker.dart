import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageWorkerPage extends StatefulWidget {
  final Worker worker;

  ManageWorkerPage({required this.worker});

  @override
  _ManageWorkerPageState createState() => _ManageWorkerPageState();
}

class _ManageWorkerPageState extends State<ManageWorkerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _wageRateController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.worker.name;
    _skillsController.text = widget.worker.skills;
    _wageRateController.text = widget.worker.wageRate.toString();
    _mobileController.text = widget.worker.mobile;
  }

  void _updateWorker() {
    if (_nameController.text.isNotEmpty &&
        _skillsController.text.isNotEmpty &&
        _wageRateController.text.isNotEmpty &&
        _mobileController.text.isNotEmpty) {

      FirebaseFirestore.instance.collection('workers').doc(widget.worker.id).update({
        'name': _nameController.text,
        'skills': _skillsController.text,
        'wageRate': double.parse(_wageRateController.text),
        'mobile': _mobileController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Worker details updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.worker.name}'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Worker Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _skillsController,
              decoration: InputDecoration(
                labelText: 'Worker Skills',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _wageRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Wage Rate',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateWorker,
              child: Text('Update Worker'),
            ),
          ],
        ),
      ),
    );
  }
}

class Worker {
  final String id;
  final String name;
  final String skills;
  final String wageType;
  final double wageRate;
  final String mobile;

  Worker({
    required this.id,
    required this.name,
    required this.skills,
    required this.wageType,
    required this.wageRate,
    required this.mobile,
  });
}
