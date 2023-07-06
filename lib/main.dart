import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
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
  final TextEditingController _bugNumberController = TextEditingController();
  final TextEditingController _bugTitleController = TextEditingController();
  bool _isFixed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bug report'),
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
            SwitchListTile(
              title: const Text('Is Fixed'),
              value: _isFixed,
              onChanged: (value) {
                setState(() {
                  _isFixed = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                _saveBugReport();
              },
              child: const Text('Save report'),
            ),
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bug-reports')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.data!.size == 0) {
                  return const Text('No bug reports saved yet.');
                }

                return ListView.builder(
                    itemCount: snapshot.data!.size,
                    itemBuilder: (BuildContext context, int index) {
                      final bugReport = snapshot.data!.docs[index];
                      final bugNumber = bugReport['bugNumber'];
                      final bugTitle = bugReport['bugTitle'];
                      final isFixed = bugReport['isFixed'];

                      return ListTile(
                        title: Text("Bug #$bugNumber"),
                        subtitle: Text('Title: $bugTitle'),
                        trailing: isFixed
                            ? const Icon(Icons.check)
                            : const Icon(Icons.close),
                      );
                    });
              },
            ))
          ],
        ),
      ),
    );
  }

  void _saveBugReport() {
    final bugNumber = _bugNumberController.text;
    final bugTitle = _bugTitleController.text;

    //create a new bug report documnet in Firestore
    FirebaseFirestore.instance.collection('bug_reports').add({
      'bugNumber': bugNumber,
      'bugTitle': bugTitle,
      'isFixed': _isFixed,
    }).then((value) {
      //clear the input fields after successfull submission
      _bugNumberController.clear();
      _bugTitleController.clear();
      setState(() {
        _isFixed = false;
      });
    }).catchError((error) {});
  }
}
