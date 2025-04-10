import 'package:flutter/material.dart'; // Flutter's material UI components
import 'package:firebase_core/firebase_core.dart'; // Required for Firebase initialization
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore for database operations
import 'package:table_calendar/table_calendar.dart'; // Calendar widget to display dates

// HomePage widget, which is a StatefulWidget since it will change based on user input
class HomePage extends StatefulWidget {
  const HomePage({super.key}); // Constructor

  @override
  State<HomePage> createState() => _HomePageState(); // Creates the mutable state for HomePage
}

// This class contains the logic and UI for the HomePage screen
class _HomePageState extends State<HomePage> {
  // Firestore instance used to interact with the Firebase database
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // TextEditingController used to capture and control the user's input for task name
  final TextEditingController nameController = TextEditingController();

  // List that stores the task data locally as a list of maps (id, name, completed)
  final List<Map<String, dynamic>> tasks = [];

  // initState is called once when the widget is inserted in the widget tree
  @override
  void initState() {
    super.initState(); // Call the parent initState method
    fetchTasks(); // Load tasks from Firestore into local list
  }

  // Future function that retrieves tasks from Firestore and updates the local task list
  Future<void> fetchTasks() async {
    // Fetch all documents from 'tasks' collection, ordered by timestamp
    final snapshot = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      // Clear the current task list before adding new items
      tasks.clear();

      // Convert each document into a map and add to local list
      tasks.addAll(
        snapshot.docs.map(
          (doc) => {
            'id': doc.id, // Document ID used for update/delete
            'name': doc.get('name'), // Task name
            'completed': doc.get('completed') ?? false, // Task status; default false
          },
        ),
      );
    });
  }

  // Future function that adds a new task to both Firestore and local task list
  Future<void> addTask() async {
    // Get the text entered by the user and remove extra spaces
    final taskName = nameController.text.trim();

    // Only proceed if the input is not empty
    if (taskName.isNotEmpty) {
      // Create a new task map with name, completed status, and timestamp
      final newTask = {
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(), // Timestamp generated by server
      };

      // Add the task to Firestore and store its document reference
      final docRef = await db.collection('tasks').add(newTask);

      // Update local task list with the new task
      setState(() {
        tasks.add({'id': docRef.id, ...newTask}); // Spread to include all newTask fields
      });

      // Clear the text input field
      nameController.clear();
    }
  }

  // Future function that updates a task's completion status in Firestore and locally
  Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index]; // Get the selected task using index

    // Update the 'completed' field in Firestore
    await db.collection('tasks').doc(task['id']).update({
      'completed': completed,
    });

    // Update the same task in the local task list
    setState(() {
      tasks[index]['completed'] = completed;
    });
  }

  // Future function that removes a task from both Firestore and the local task list
  Future<void> removeTasks(int index) async {
    final task = tasks[index]; // Get the task to be deleted

    // Delete task from Firestore using document ID
    await db.collection('tasks').doc(task['id']).delete();

    // Remove task from local list to update UI
    setState(() {
      tasks.removeAt(index);
    });
  }

  // Builds the complete UI of the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // Top bar of the app
        backgroundColor: Colors.blue,
        title: Row( // Layout title and logo in a row
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Displays the RDP logo
            Expanded(child: Image.asset('assets/rdplogo.png', height: 80)),

            // App title text
            const Text(
              'Daily Planner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column( // Main content of the screen
        children: [
          Expanded( // Allows this part to take full vertical space
            child: SingleChildScrollView( // Makes its child scrollable
              child: Column(
                children: [
                  TableCalendar( // Calendar widget showing months
                    calendarFormat: CalendarFormat.month,
                    focusedDay: DateTime.now(), // Highlight today's date
                    firstDay: DateTime(2025), // Earliest allowed date
                    lastDay: DateTime(2026), // Latest allowed date
                  ),

                  // Build the list of tasks from the local list
                  buildTaskList(tasks, removeTasks, updateTask),
                ],
              ),
            ),
          ),

          // Build the input section for adding tasks
          buildAddTaskSection(nameController, addTask),
        ],
      ),
      drawer: Drawer(), // Side navigation menu (currently empty)
    );
  }
}

// Function that builds the input section to add new tasks
Widget buildAddTaskSection(nameController, addTask) {
  return Container(
    decoration: const BoxDecoration(color: Colors.white),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Text input field where users enter their task
          Expanded(
            child: Container(
              child: TextField(
                maxLength: 32, // Limit the text to 32 characters
                controller: nameController, // Controls the input
                decoration: const InputDecoration(
                  labelText: 'Add Task', // Label inside the input box
                  border: OutlineInputBorder(), // Border for styling
                ),
              ),
            ),
          ),
          // Button to add the task
          ElevatedButton(
            onPressed: addTask, //Adds tasks when pressed
            // onPressed calls the addTask function when clicked
            child: Text('Add Task'),
          ),
        ],
      ),
    ),
  );
}

// Function that builds the list of task widgets using ListView.builder
Widget buildTaskList(tasks, removeTasks, updateTask) {
  return ListView.builder(
    shrinkWrap: true, // List should only take up as much space as needed
    physics: const NeverScrollableScrollPhysics(), // Disable inner scrolling
    itemCount: tasks.length, // Total number of tasks to display
    itemBuilder: (context, index) {
      final task = tasks[index]; // Get task at current index
      final isEven = index % 2 == 0; // Used to alternate background color

      return Padding(
        padding: EdgeInsets.all(1.0), // Small padding around task item
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Rounded edges
          tileColor: isEven ? Colors.blue : Colors.green, // Alternate color per row

          // Icon to show whether task is completed or not
          leading: Icon(
            task['completed'] ? Icons.check_circle : Icons.circle_outlined,
          ),

          // Display the task name
          title: Text(
            task['name'],
            style: TextStyle(
              decoration: task['completed'] ? TextDecoration.lineThrough : null, // Strike-through if done
              fontSize: 22,
            ),
          ),

          // Right side of the tile - checkbox and delete button
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkbox to toggle task completed status
              Checkbox(
                value: task['completed'],
                // onChanged calls updateTask when checkbox is clicked
                onChanged: (value) => updateTask(index, value!),
              ),

              // Button to delete a task
              IconButton(
                icon: Icon(Icons.delete),
                // onPressed calls removeTasks to delete task
                onPressed: () => removeTasks(index),
              ),
            ],
          ),
        ),
      );
    },
  );
}
