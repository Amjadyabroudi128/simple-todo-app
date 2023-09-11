

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  // text fields' controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final CollectionReference project =
  FirebaseFirestore.instance.collection('project');

  // This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a project if no documentSnapshot is passed
  // If documentSnapshot != null then update an existing product

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['name'];
      _hoursController.text = documentSnapshot['hours'].toString();
    }
    await  showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                // prevent the soft keyboard from covering text fields
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name of project'),
                ),
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  controller: _hoursController,
                  decoration: const InputDecoration(
                    labelText: 'hours it takes ',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? name = _nameController.text;
                    final double? hours =
                    double.tryParse(_hoursController.text);
                    if (name != null && hours != null) {
                      if (action == 'create') {
                        // add a new project to Firestore
                      await  FirebaseFirestore.instance.collection('project').add(
                            {
                              "name": name,
                              "hours" : hours
                            });
                      }

                      if (action == 'update') {
                        // Update the project
                        await FirebaseFirestore.instance.collection('project')
                            .doc(documentSnapshot!.id).update({"name": name, "hours" : hours});
                      }

                      // Clear the text fields
                      clearText();

                      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
                        content: Text(action == 'create' ? 'You have successfully created a project':'You have successfully edited a project' ),
                      ));
                      // Hide the bottom sheet
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          );

        }
        );

  }

  void clearText() {
    _nameController.clear();
    _hoursController.clear();

  }
  Future<void> _showMyDialog(Id) async {

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text('you are about to delete a project ?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('are you sure? ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20.0,
                  ),),

              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('yes',
                style: TextStyle(fontSize: 20),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('project').doc(Id).delete();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('You have successfully deleted a project'),

                ));
                Navigator.pop(context);
              },

            ),
            TextButton(
              child: const Text('cancel',
                style: TextStyle(fontSize: 20),
              ),
              onPressed: ()  {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Deleteing a project by id
  Future<void> _deleteProduct(Id) async {
    // await FirebaseFirestore.instance.collection('project').doc(Id).delete();
    await _showMyDialog(Id);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('testing app '),
      ),
      // Using StreamBuilder to display all products from Firestore in real-time
      body: StreamBuilder(
        stream: project.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];
                return Card(
                  color: Colors.lightBlue,
                  shadowColor: Colors.lightBlueAccent,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  margin: const EdgeInsets.all(19),
                  child: ListTile(
                    title: Text(documentSnapshot['name'],

                    ),
                    subtitle: Text(documentSnapshot['hours'].toString(),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Expanded(
                        child: Row(
                          children: [
                            // Press this button to edit a single product
                            IconButton(
                                icon:  Icon(Icons.mode_edit_sharp),
                                onPressed: () =>
                                    _createOrUpdate(documentSnapshot)),
                            // This icon button is used to delete a single product
                            IconButton(
                                icon:  Icon(Icons.delete_forever_rounded),
                                onPressed: () =>
                                    _deleteProduct(documentSnapshot.id)),

                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      // Add new product
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
