import 'package:flutter/material.dart'; // This lets us use all Flutter UI widgets
import 'package:firebase_core/firebase_core.dart'; // This is needed to connect Flutter with Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; // This lets us use Firestore database
import 'package:table_calendar/table_calendar.dart'; // This gives us the calendar widget

// This is the main screen of our app, which can change (StatefulWidget)
class HomePage extends StatefulWidget {
  const HomePage({super.key}); // This is the constructor

  @override
  State<HomePage> createState() => _HomePageState(); // This tells Flutter to use _HomePageState for this screen
}

// This is the part where all the logic and UI of the HomePage happens
class _HomePageState extends State<HomePage> {
  final FirebaseFirestore db =
      FirebaseFirestore
          .instance; //new firestore instance (used to read/write in Firestore)

  final TextEditingController nameController =
      TextEditingController(); //captures textform input (used to get what user types)

  final List<Map<String, dynamic>> tasks =
      []; // This will store all tasks temporarily in the app

  @override
  void initState() {
    super.initState(); // First, run the normal Flutter initialization
    fetchTasks(); // Then call our custom function to load tasks from Firestore
  }

  //Fetches tasks from the firestore and update local task list
  Future<void> fetchTasks() async {
    final snapshot =
        await db
            .collection('tasks')
            .orderBy('timestamp')
            .get(); // Get all tasks from 'tasks' collection, ordered by time

    setState(() {
      // This tells Flutter to refresh the UI
      tasks.clear(); // Remove old tasks
      tasks.addAll(
        // Add all new tasks from Firestore
        snapshot.docs.map(
          (doc) => {
            'id': doc.id, // Get Firestore document ID
            'name': doc.get('name'), // Get the task name
            'completed':
                doc.get('completed') ??
                false, // Get completed status, if not found then use false
          },
        ),
      );
    });
  }

  //Function that adds new tasks to local state & firestore database
  Future<void> addTask() async {
    final taskName =
        nameController.text.trim(); // Get the task name from the text field

    if (taskName.isNotEmpty) {
      // Only proceed if task is not empty
      final newTask = {
        'name': taskName, // Save task name
        'completed': false, // Mark it not completed by default
        'timestamp':
            FieldValue.serverTimestamp(), // Add current time from Firebase server
      };

      //docRef gives us the insertion id of the task from the database
      final docRef = await db
          .collection('tasks')
          .add(newTask); // Save this new task to Firestore

      //Adding tasks locally
      setState(() {
        tasks.add({
          'id': docRef.id,
          ...newTask,
        }); // Add this task to the app’s local list
      });
      nameController.clear(); // Clear the text field
    }
  }

  //Updates the completion status of the task in Firestore & locally
  Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index]; // Get the task at the given index
    await db.collection('tasks').doc(task['id']).update({
      'completed': completed, // Update its 'completed' value in Firestore
    });

    setState(() {
      tasks[index]['completed'] = completed; // Also update the local value
    });
  }

  //Delete the task locally & in the Firestore
  Future<void> removeTasks(int index) async {
    final task = tasks[index]; // Get the task to delete

    await db
        .collection('tasks')
        .doc(task['id'])
        .delete(); // Delete it from Firestore

    setState(() {
      tasks.removeAt(index); // Also remove it from our local list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold is the basic layout structure
      appBar: AppBar(
        // This is the top app bar
        backgroundColor: Colors.blue, // Set its background to blue
        title: Row(
          // Inside app bar, we use a Row
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Space out logo and text evenly
          children: [
            Expanded(
              child: Image.asset('assets/rdplogo.png', height: 80),
            ), // Show the RDP logo
            const Text(
              'Daily Planner', // This is the title of the app
              style: TextStyle(
                fontFamily: 'Caveat', // Use the 'Caveat' font
                fontSize: 32, // Text size
                color: Colors.white, // Text color
              ),
            ),
          ],
        ),
      ),
      body: Column(
        // The main content is inside a column
        children: [
          Expanded(
            // This part will expand to take available space
            child: SingleChildScrollView(
              // Makes everything scrollable
              child: Column(
                // Inside this column:
                children: [
                  TableCalendar(
                    // This is the calendar widget
                    calendarFormat:
                        CalendarFormat.month, // Show full month view
                    focusedDay: DateTime.now(), // Start at today's date
                    firstDay: DateTime(
                      2025,
                    ), // Don't allow selecting dates before this
                    lastDay: DateTime(
                      2026,
                    ), // Don't allow selecting dates after this
                  ),
                  buildTaskList(
                    tasks,
                    removeTasks,
                    updateTask,
                  ), // Show the list of tasks
                ],
              ),
            ),
          ),
          buildAddTaskSection(
            nameController,
            addTask,
          ), // Show the text box and add button
        ],
      ),
      drawer: Drawer(), // Side navigation drawer (currently empty)
    );
  }
}

//Build the section for adding tasks
Widget buildAddTaskSection(nameController, addTask) {
  return Container(
    // Outer box for the input area
    decoration: const BoxDecoration(
      color: Colors.white,
    ), // Set background color to white
    child: Padding(
      // Add padding around it
      padding: const EdgeInsets.all(12.0), // 12 pixels padding
      child: Row(
        // Row with input and button
        children: [
          Expanded(
            // Input takes full space
            child: Container(
              // Container for the TextField
              child: TextField(
                // This is the input field
                maxLength: 32, // Limit to 32 characters
                controller: nameController, // Use the passed controller
                decoration: const InputDecoration(
                  labelText: 'Add Task', // Label inside the box
                  border: OutlineInputBorder(), // Show outline around the box
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: addTask, //Adds tasks when pressed
            child: Text('Add Task'), // Text on the button
          ),
        ],
      ),
    ),
  );
}

//Widget that displays the task item on the UI
Widget buildTaskList(tasks, removeTasks, updateTask) {
  return ListView.builder(
    // Builds a list automatically
    shrinkWrap: true, // List will only take needed height
    physics:
        const NeverScrollableScrollPhysics(), // Disable scroll inside the list
    itemCount: tasks.length, // Number of items in list
    itemBuilder: (context, index) {
      // This function builds each item
      final task = tasks[index]; // Get the task at the current index
      final isEven = index % 2 == 0; // To alternate colors

      return Padding(
        // Padding around each task
        padding: EdgeInsets.all(1.0),
        child: ListTile(
          // ListTile shows one task
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ), // Rounded corners
          tileColor: isEven ? Colors.blue : Colors.green, // Alternate colors
          leading: Icon(
            // Icon on the left
            task['completed']
                ? Icons.check_circle
                : Icons.circle_outlined, // Check or circle icon
          ),
          title: Text(
            // Task name text
            task['name'], // Show the task name
            style: TextStyle(
              decoration:
                  task['completed']
                      ? TextDecoration.lineThrough
                      : null, // Strike-through if completed
              fontSize: 22, // Font size
            ),
          ),
          trailing: Row(
            // Buttons on the right
            mainAxisSize: MainAxisSize.min, // Don't take full width
            children: [
              Checkbox(
                // Checkbox for completion
                value: task['completed'], // Show checked or not
                onChanged:
                    (value) => updateTask(index, value!), // Update when checked
              ),
              IconButton(
                // Delete icon
                icon: Icon(Icons.delete), // Trash icon
                onPressed: () => removeTasks(index), // Delete the task
              ),
            ],
          ),
        ),
      );
    },
  );
}
