import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student List',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const StudentListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});
  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<dynamic> students = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          students = data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load data (status ${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  Color getColor(int index) {
    return index % 2 == 0 ? Colors.teal.shade50 : Colors.teal.shade100;
  }

  // Open add form modal
  void openAddForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddStudentForm(
        onAdd: (newStudent) {
          setState(() {
            students.insert(0, newStudent);
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student added (local update only)')),
          );
        },
      ),
    );
  }

  // Open update form modal
  void openUpdateForm(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UpdateStudentForm(
        student: student,
        onUpdate: (updatedStudent) {
          final index =
              students.indexWhere((s) => s['id'] == updatedStudent['id']);
          if (index != -1) {
            setState(() {
              students[index] = updatedStudent;
            });
          }
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Student updated (local update only)')),
          );
        },
      ),
    );
  }

  // Delete student confirmation and action
  void deleteStudent(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      // Dummy API accepts DELETE but no real deletion
      final res = await http
          .delete(Uri.parse('https://jsonplaceholder.typicode.com/users/$id'));

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          students.removeWhere((s) => s['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted (local update only)')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete. Status: ${res.statusCode}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student List',
        ),
        actions: [
          IconButton(
              onPressed: openAddForm,
              icon: const Icon(
                Icons.add,
                color: Colors.blue,
                size: 30,
              )),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)))
              : students.isEmpty
                  ? const Center(child: Text('No students found.'))
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Card(
                          color: getColor(index),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                student['name'][0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              student['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(student['email']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange),
                                  onPressed: () => openUpdateForm(student),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => deleteStudent(student['id']),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StudentDetailScreen(student: student),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

class AddStudentForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;
  const AddStudentForm({super.key, required this.onAdd});

  @override
  State<AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<AddStudentForm> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();
  final companyController = TextEditingController();
  bool isAdding = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isAdding = true;
    });

    final newStudentData = {
      "name": nameController.text,
      "username": usernameController.text,
      "email": emailController.text,
      "phone": phoneController.text,
      "website": websiteController.text,
      "address": addressController.text,
      "company": companyController.text,
    };

    try {
      final res = await http.post(
        Uri.parse('https://jsonplaceholder.typicode.com/users'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode(newStudentData),
      );

      if (res.statusCode == 201) {
        final newStudent = jsonDecode(res.body);
        // Dummy API returns id 11+ for new created user
        widget.onAdd(newStudent);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to add student. Status: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding student: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Student',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.teal),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter email';
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(v)) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                    labelText: 'Phone', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isAdding ? null : addStudent,
                child: isAdding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Add Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpdateStudentForm extends StatefulWidget {
  final Map<String, dynamic> student;
  final void Function(Map<String, dynamic>) onUpdate;
  const UpdateStudentForm(
      {super.key, required this.student, required this.onUpdate});

  @override
  State<UpdateStudentForm> createState() => _UpdateStudentFormState();
}

class _UpdateStudentFormState extends State<UpdateStudentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.student['name']);
    emailController = TextEditingController(text: widget.student['email']);
    phoneController = TextEditingController(text: widget.student['phone']);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isUpdating = true;
    });

    final updatedData = {
      "name": nameController.text,
      "email": emailController.text,
      "phone": phoneController.text,
    };

    final id = widget.student['id'];

    try {
      final res = await http.put(
        Uri.parse('https://jsonplaceholder.typicode.com/users/$id'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode(updatedData),
      );

      if (res.statusCode == 200) {
        final updatedStudent = jsonDecode(res.body);
        updatedStudent['id'] = id; // keep same id
        widget.onUpdate(updatedStudent);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update. Status: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Student',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.teal),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter email';
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(v)) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                    labelText: 'Phone', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isUpdating ? null : updateStudent,
                child: isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentDetailScreen extends StatelessWidget {
  final dynamic student;
  const StudentDetailScreen({super.key, required this.student});

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.teal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = student['address'];
    final company = student['company'];
    return Scaffold(
      appBar: AppBar(title: Text(student['name'] ?? 'Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            buildDetailRow('Name', student['name'] ?? ''),
            buildDetailRow('Username', student['username'] ?? ''),
            buildDetailRow('Email', student['email'] ?? ''),
            buildDetailRow('Phone', student['phone'] ?? ''),
            buildDetailRow('Website', student['website'] ?? ''),
            if (address != null)
              buildDetailRow('Address',
                  '${address['suite']}, ${address['street']}, ${address['city']}, ${address['zipcode']}'),
            if (company != null)
              buildDetailRow('Company', company['name'] ?? ''),
          ],
        ),
      ),
    );
  }
}
