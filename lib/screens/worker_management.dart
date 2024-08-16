import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'manage_worker.dart';  // Import the manage worker page

class WorkerManagementScreen extends StatefulWidget {
  @override
  _WorkerManagementScreenState createState() => _WorkerManagementScreenState();
}

class _WorkerManagementScreenState extends State<WorkerManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Management'),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddWorkerDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('workers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoWorkersContent();
          }

          List<Worker> workers = snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Worker(
              id: doc.id,
              name: data['name'],
              skills: data['skills'],
              wageType: data['wageType'],
              wageRate: data['wageRate'],
              mobile: data['mobile'],
            );
          }).toList();

          return _buildWorkerList(workers);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkerDialog(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
        tooltip: 'Add Worker',
      ),
    );
  }

  Widget _buildNoWorkersContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/location-gif.json', height: 200),
          SizedBox(height: 20),
          Text(
            'No Workers Added Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Add workers to manage and keep track of them.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList(List<Worker> workers) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: workers.length,
        itemBuilder: (context, index) {
          Worker worker = workers[index];
          return Dismissible(
            key: Key(worker.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              FirebaseFirestore.instance.collection('workers').doc(worker.id).delete();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${worker.name} dismissed')),
              );
            },
            background: Container(
              color: Colors.red,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
            child: Card(
              elevation: 6,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(worker.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(
                  'Skills: ${worker.skills}\nWage Type: ${worker.wageType}\nWage Rate: ₹${worker.wageRate.toStringAsFixed(2)}\nMobile: ${worker.mobile}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                trailing: Icon(Icons.edit, color: Colors.green),
                onTap: () => _showManageWorkerPage(context, worker),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddWorkerDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String _workerName = '';
    String _workerSkills = '';
    String _wageType = 'Daily Wage';
    double _wageRate = 0.0;
    String _workerMobile = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Worker'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Worker Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter worker name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _workerName = value!;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Worker Skills',
                      prefixIcon: Icon(Icons.build),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter worker skills';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _workerSkills = value!;
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _wageType,
                    decoration: InputDecoration(
                      labelText: 'Wage Type',
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 10), // Add some padding to the left
                          Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 18, // Adjust the size as needed
                              color: Colors.grey[600], // Adjust the color as needed
                            ),
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                    items: ['Daily Wage', 'Monthly Wage'].map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _wageType = value!;
                      });
                    },
                    onSaved: (value) {
                      _wageType = value!;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Wage Rate',
                      prefixIcon: Icon(Icons.monetization_on),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter wage rate';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _wageRate = double.parse(value!);
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter mobile number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _workerMobile = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  FirebaseFirestore.instance.collection('workers').add({
                    'name': _workerName,
                    'skills': _workerSkills,
                    'wageType': _wageType,
                    'wageRate': _wageRate,
                    'mobile': _workerMobile,
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Add Worker'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showManageWorkerPage(BuildContext context, Worker worker) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageWorkerPage(worker: worker),
      ),
    );
  }
}
