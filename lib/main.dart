import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crudmobx/login_api.dart';
part 'main.g.dart';

class Task {
  late String title;
  Task(this.title);
}

class TaskStore = _TaskStore with _$TaskStore;

abstract class _TaskStore with Store {
  @observable
  ObservableList<Task> tasks = ObservableList<Task>();

  @action
  void addTask(Task task) {
    tasks.add(task);
    saveTasks();
  }

  @action
  void removeTask(Task task) {
    tasks.remove(task);
    saveTasks();
  }

  @action
  void clearTasks() {
    tasks.clear();
    saveTasks();
  }

  @action
  void loadTasks() {
    final prefsFuture = SharedPreferences.getInstance();
    prefsFuture.then(
      (prefs) {
        final List<String>? taskList = prefs.getStringList('tasks');
        if (taskList != null) {
          tasks = taskList.map((title) => Task(title)).toList().asObservable();
        }
      },
    );
  }

  void saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('tasks', tasks.map((task) => task.title).toList());
  }
}

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginPage({super.key});

  _launchURL() async {
    final Uri url = Uri.parse('https://www.google.com');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  static final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');

  _goToCrudPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrudPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.fromRGBO(5, 70, 67, 1),
                Color.fromARGB(255, 42, 197, 145),
              ],
            ),
          ),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Usuário",
                        prefixIcon: Icon(Icons.account_circle_sharp),
                        filled: true,
                        fillColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, preencha seu usuário';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Senha",
                        prefixIcon: Icon(Icons.lock_sharp),
                        filled: true,
                        fillColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, preencha a senha';
                        }
                        if (value.length <= 2) {
                          return 'Por favor, utilize mais de 2 caracteres';
                        }
                        if (value.length > 20) {
                          return 'Por favor, utilize menos de 20 caracteres';
                        }
                        if (validCharacters.hasMatch(value)) {
                          return null;
                        } else {
                          return 'Por favor, não utilize caracteres especiais';
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size.fromRadius(20),
                            shape: const StadiumBorder()),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            String login = _usernameController.text;
                            String password = _passwordController.text;

                            var response =
                                await LoginApi.login(login, password);
                            if (response) {
                              _goToCrudPage(context);
                            }
                          }
                        },
                        child: const Text('Entrar'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 200),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
                      ),
                      onPressed: _launchURL,
                      child: const Text('Política de Privacidade'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CrudPage extends StatelessWidget {
  final TaskStore taskStore = TaskStore();
  final TextEditingController _taskController = TextEditingController();

  CrudPage({super.key});

  @override
  Widget build(BuildContext context) {
    taskStore.loadTasks();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromRGBO(5, 70, 67, 1),
              Color.fromARGB(255, 42, 197, 145),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(40.0),
                child: Observer(
                  builder: (_) => ListView.builder(
                    itemCount: taskStore.tasks.length,
                    itemBuilder: (_, index) {
                      final task = taskStore.tasks[index];
                      return ListTile(
                        title: Text(task.title),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editTask(context, task),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeTask(context, task),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(40.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextFormField(
                autofocus: true,
                onFieldSubmitted: (value) {
                  final newTask = Task(_taskController.text);
                  taskStore.addTask(newTask);
                  _taskController.clear();
                },
                textInputAction: TextInputAction.go,
                controller: _taskController,
                decoration: const InputDecoration(
                  labelText: 'Insira a tarefa',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite a tarefa';
                  }
                  return null;
                },
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 255, 255, 255),
              ),
              onPressed: _launchURL,
              child: const Text('Política de Privacidade'),
            ),
          ],
        ),
      ),
    );
  }

  _launchURL() async {
    final Uri url = Uri.parse('https://www.google.com');
    if (!await launchUrl(url)) {
      throw Exception('Não foi possível acessar: $url');
    }
  }

  void _editTask(BuildContext context, Task task) {
    _taskController.text = task.title;
    BuildContext dialogContext;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        dialogContext = context;
        return AlertDialog(
          title: const Text('Editar Tarefa'),
          content: TextField(
            controller: _taskController,
            decoration: const InputDecoration(labelText: 'Tarefa'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _taskController.clear();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                taskStore.removeTask(task);
                final editedTask = Task(_taskController.text);
                taskStore.addTask(editedTask);
                Navigator.pop(dialogContext);
                _taskController.clear();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _removeTask(BuildContext context, Task task) {
    _taskController.text = task.title;
    BuildContext dialogContext;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        dialogContext = context;
        return AlertDialog(
          title: const Text('Apagar Tarefa?'),
          content: TextField(
            controller: _taskController,
            decoration: const InputDecoration(
                labelText: 'Tem certeza que deseja apagar?'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _taskController.clear();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                taskStore.removeTask(task);
                Navigator.pop(dialogContext);
                _taskController.clear();
              },
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );
  }
}
