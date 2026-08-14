import 'package:flutter/material.dart';

void main() {
  runApp(const CourseSystemApp());
}

class CourseSystemApp extends StatelessWidget {
  const CourseSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Course System CRUD',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const CourseHomePage(),
    );
  }
}

class Course {
  Course({
    required this.id,
    required this.title,
    required this.teacher,
    required this.durationInWeeks,
  });

  final int id;
  String title;
  String teacher;
  int durationInWeeks;
}

class CourseHomePage extends StatefulWidget {
  const CourseHomePage({super.key});

  @override
  State<CourseHomePage> createState() => _CourseHomePageState();
}

class _CourseHomePageState extends State<CourseHomePage> {
  final List<Course> _courses = [
    Course(
      id: 1,
      title: 'Flutter Basics',
      teacher: 'Anita Sharma',
      durationInWeeks: 4,
    ),
    Course(
      id: 2,
      title: 'Dart for Beginners',
      teacher: 'Rahul Mehta',
      durationInWeeks: 3,
    ),
  ];

  int _nextId = 3;

  void _createCourse(String title, String teacher, int durationInWeeks) {
    setState(() {
      _courses.add(
        Course(
          id: _nextId,
          title: title,
          teacher: teacher,
          durationInWeeks: durationInWeeks,
        ),
      );
      _nextId++;
    });
  }

  void _updateCourse(
    Course course,
    String title,
    String teacher,
    int durationInWeeks,
  ) {
    setState(() {
      course.title = title;
      course.teacher = teacher;
      course.durationInWeeks = durationInWeeks;
    });
  }

  void _deleteCourse(Course course) {
    setState(() {
      _courses.remove(course);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${course.title} deleted')),
    );
  }

  Future<void> _openCourseForm({Course? course}) async {
    final titleController = TextEditingController(text: course?.title ?? '');
    final teacherController = TextEditingController(text: course?.teacher ?? '');
    final durationController = TextEditingController(
      text: course?.durationInWeeks.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(course == null ? 'Add Course' : 'Edit Course'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Course title'),
                    validator: (value) => _requiredText(value, 'course title'),
                  ),
                  TextFormField(
                    controller: teacherController,
                    decoration: const InputDecoration(labelText: 'Teacher name'),
                    validator: (value) => _requiredText(value, 'teacher name'),
                  ),
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration in weeks',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateDuration,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final duration = int.parse(durationController.text.trim());

                if (course == null) {
                  _createCourse(
                    titleController.text.trim(),
                    teacherController.text.trim(),
                    duration,
                  );
                } else {
                  _updateCourse(
                    course,
                    titleController.text.trim(),
                    teacherController.text.trim(),
                    duration,
                  );
                }

                Navigator.pop(context);
              },
              child: Text(course == null ? 'Create' : 'Update'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    teacherController.dispose();
    durationController.dispose();
  }

  String? _requiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a $fieldName';
    }
    return null;
  }

  String? _validateDuration(String? value) {
    final duration = int.tryParse(value?.trim() ?? '');
    if (duration == null || duration <= 0) {
      return 'Please enter a number greater than 0';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course System'),
        centerTitle: true,
      ),
      body: _courses.isEmpty
          ? const Center(
              child: Text('No courses yet. Tap + to create your first course.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(course.id.toString())),
                    title: Text(course.title),
                    subtitle: Text(
                      'Teacher: ${course.teacher}\nDuration: ${course.durationInWeeks} weeks',
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openCourseForm(course: course),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCourse(course),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCourseForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
      ),
    );
  }
}
