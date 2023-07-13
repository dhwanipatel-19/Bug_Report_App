import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bug Report',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const BugReportScreen(),
    );
  }
}

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  int _currentIndex = 0;
  // final TextEditingController _bugNumberController = TextEditingController();
  // final TextEditingController _bugTitleController = TextEditingController();
  // bool _isFixed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Bug report'),
        ),
        body: _buildScreen(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Active',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.done_all),
              label: 'Fixed',
            ),
          ],
        ));
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return const ActiveBugsScreen();
      case 1:
        return const FixedBugsScreen();
      default:
        return Container();
    }
  }

  // void _saveBugReport() {
  //   final bugNumber = _bugNumberController.text;
  //   final bugTitle = _bugTitleController.text;

  //   //create a new bug report documnet in Firestore
  //   FirebaseFirestore.instance.collection('bug_reports').add({
  //     'bugNumber': bugNumber,
  //     'bugTitle': bugTitle,
  //     'isFixed': _isFixed,
  //   }).then((value) {
  //     //clear the input fields after successfull submission
  //     _bugNumberController.clear();
  //     _bugTitleController.clear();
  //     setState(() {
  //       _isFixed = false;
  //     });
  //   }).catchError((error) {
  //     if (kDebugMode) {
  //       print('Error: $error');
  //     }
  //   });
  // }
}

class ActiveBugsScreen extends StatelessWidget {
  const ActiveBugsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const BugReportsList(status: 'active'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BugReportsubmissionScreen(),
              ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FixedBugsScreen extends StatelessWidget {
  const FixedBugsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BugReportsList(status: 'fixed'),
    );
  }
}

class BugReportsList extends StatelessWidget {
  const BugReportsList({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bug_reports')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.data == null || snapshot.data!.size == 0) {
          return Center(child: Text('No $status bug reports.'));
        }

        return ListView.builder(
            itemCount: snapshot.data!.size,
            itemBuilder: (BuildContext context, int index) {
              final bugReport = snapshot.data!.docs[index];
              final bugNumber = bugReport['bugNumber'];
              final bugTitle = bugReport['bugTitle'];
              final isFixed = bugReport['status'] == 'fixed';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text('Bug #$bugNumber'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Title: $bugTitle'),
                      Text('Status: ${isFixed ? 'Fixed' : 'Active'}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(isFixed
                        ? Icons.check_circle
                        : Icons.check_circle_outline),
                    onPressed: () {
                      _updateBugStatus(
                          bugReport.reference, isFixed ? 'active' : 'fixed');
                    },
                  ),
                ),
              );
            });
      },
    );
  }

  Future<void> _updateBugStatus(DocumentReference bugRef, String newStatus) {
    return bugRef
        .update({'status': newStatus})
        .then((value) => print('Bug status updated successfully.'))
        .catchError((error) => print('Failed to update bug status: $error'));
  }
}

class BugReportsubmissionScreen extends StatefulWidget {
  const BugReportsubmissionScreen({super.key});

  @override
  State<BugReportsubmissionScreen> createState() =>
      _BugReportsubmissionScreenState();
}

class _BugReportsubmissionScreenState extends State<BugReportsubmissionScreen> {
  final TextEditingController _bugNumberController = TextEditingController();
  final TextEditingController _bugTitleController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add a bug'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _bugNumberController,
                decoration: const InputDecoration(labelText: 'Bug Number'),
              ),
              TextField(
                controller: _bugTitleController,
                decoration: const InputDecoration(labelText: 'Bug Title'),
              ),
              // const SizedBox(height: 16.0),
              // const Text('Priority:'),
              ElevatedButton(
                onPressed: () {
                  _submitBugReport(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ));
  }

  void _submitBugReport(BuildContext context) {
    final bugNumber = _bugNumberController.text;
    final bugTitle = _bugTitleController.text;
    const status = 'active';
    // String _selectedPriority = 'low'; // Set the initial status to 'active'

    if (bugNumber.isNotEmpty && bugTitle.isNotEmpty) {
      // Save the bug report to Firestore
      FirebaseFirestore.instance.collection('bug_reports').add({
        'bugNumber': bugNumber,
        'bugTitle': bugTitle,
        'status': status,
      }).then((value) {
        // Clear the input fields after successful submission
        _bugNumberController.clear();
        _bugTitleController.clear();

        // Display a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bug report submitted successfully')),
        );
      }).catchError((error) {
        // Handle any errors that occur during the submission
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });
    } else {
      // Display an error message if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  @override
  void dispose() {
    _bugNumberController.dispose();
    _bugTitleController.dispose();

    super.dispose();
  }
}
