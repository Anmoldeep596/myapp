import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  
  //crate an empty list of maps which represents our tasks
  final List<Map<String, dynamic>> tasks = [];

  //create variables that  captures the input of a text input
  final TextEditingController taskController = TextEditingController();



  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
       backgroundColor: Colors.blue,
       title: Row(children: [

       ],)
      ),
    );
  }
}
