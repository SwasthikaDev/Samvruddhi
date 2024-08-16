// lib/screens/worker_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class WorkerInfoScreen extends StatefulWidget {
  final Map<String, dynamic> farmData;
  WorkerInfoScreen({required this.farmData});

  @override
  _WorkerInfoScreenState createState() => _WorkerInfoScreenState();
}

class _WorkerInfoScreenState extends State<WorkerInfoScreen> {
  List<Map<String, dynamic>> _workers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Worker Information')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _workers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_workers[index]['name']),
                  subtitle: Text('Wage: \₹${_workers[index]['wage']}/day'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _workers.removeAt(index);
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
                _showAddWorkerDialog();
              },
              child: Text('Add Worker'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _workers.isNotEmpty
                  ? () async {
                final databaseService = Provider.of<DatabaseService>(context, listen: false);
                final completeData = {
                  ...widget.farmData,
                  'workers': _workers,
                };
                try {
                  await databaseService.saveFarmData(completeData);
                  Navigator.pushReplacementNamed(context, '/dashboard', arguments: completeData);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving farm data: $e')),
                  );
                }
              }
                  : null,
              child: Text('Finish'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWorkerDialog() {
    String workerName = '';
    double workerWage = 0;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Worker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Worker Name'),
                onChanged: (value) => workerName = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Daily Wage (\$)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => workerWage = double.tryParse(value) ?? 0,
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
                if (workerName.isNotEmpty && workerWage > 0) {
                  setState(() {
                    _workers.add({'name': workerName, 'wage': workerWage});
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