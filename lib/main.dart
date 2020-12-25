import 'dart:io';

import 'package:fliterm/model/command.dart';
import 'package:fliterm/model/output.dart';
import 'package:fliterm/model/shell_component.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  initialize();
  runApp(MyApp());
}

// To set the home directory according to your machine
void initialize() {
  // String os = Platform.operatingSystem;
  String home = "";
  Map<String, String> envVars = Platform.environment;
  if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  }
  Directory.current = home;
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fliterm',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        backgroundColor: Color(0xFF222222),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController controller = TextEditingController();
  List<ShellComponent> lines = [];
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Container(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines.map((shellComponent) {
                        return buildShellComponent(shellComponent);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  '~\$ ',
                  style: TextStyle(
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    )),
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onEditingComplete: () async {
                      await handleCommandSubmission();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future handleCommandSubmission() async {
    setState(() {
      lines.add(Command(text: controller.text));
    });
    //execute system available commands with no args
    final process = await Process.run(controller.text.toLowerCase(), [])
        .catchError((error) => print(error));
    final envVarMap = Platform.environment;
    if (process != null || envVarMap[controller.text.toUpperCase()] != null) {
      setState(() {
        lines.add(Output(
            text: process?.stdout ?? envVarMap[controller.text.toUpperCase()]));
      });
    } else {
      await maybeExecuteBuiltInCommand();
    }
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    controller.clear();
  }

  Text buildShellText(String componentText) {
    return Text(
      componentText,
      style: TextStyle(
        color: Colors.white,
      ),
    );
  }

  Future maybeExecuteBuiltInCommand() async {
    List<String> wordsOfTheCommand = controller.text.split(' ');
    String firstWord = wordsOfTheCommand[0];
    if (firstWord == 'cat') {
      await cat(wordsOfTheCommand);
    } else if (firstWord == 'touch') {
      touch(wordsOfTheCommand);
    } else if (firstWord == 'mkdir') {
      await mkdir(wordsOfTheCommand);
    } else if (firstWord == 'cd') {
      cd(wordsOfTheCommand);
    } else {
      lines.add(Output(text: 'This command hasn\'t been added yet!'));
    }
  }

  void cd(List<String> wordsOfTheCommand) {
    Directory.current = wordsOfTheCommand[1];
    lines.add(Output(text: Directory.current.path));
  }

  Future mkdir(List<String> wordsOfTheCommand) async {
    String path = await _makeDirectory(wordsOfTheCommand[1]);
    setState(() {
      lines.add(Output(text: path));
    });
  }

  Future<String> _makeDirectory(String folderName) async {
    if (folderName.isEmpty)
      return 'Ugh, Don\'t forget to specify the directory name!';

    final Directory _dir = await getApplicationDocumentsDirectory();
    final Directory _tryCreatingNewFolder =
    Directory('${_dir.path}/$folderName/');
    if (await _tryCreatingNewFolder.exists())
      return _tryCreatingNewFolder.path;
    else {
      final Directory _newFolder =
      await _tryCreatingNewFolder.create(recursive: true);
      return _newFolder.path;
    }
  }

  void touch(List<String> wordsOfTheCommand) {
    if (wordsOfTheCommand[1].isNotEmpty)
      _makeFile(wordsOfTheCommand[1]);
    else
      setState(() {
        lines.add(Output(text: 'Ugh, Don\'t forget to specify the file path!'));
      });
  }

  Future<void> _makeFile(String path) async {
    File(path).create(recursive: true);
  }

  Future cat(List<String> wordsOfTheCommand) async {
    var theContentsOfTheFile = await _readAFile(wordsOfTheCommand[1] ?? '');
    setState(() {
      lines.add(Output(text: theContentsOfTheFile));
    });
  }

  Future<String> _readAFile(String path) async {
    if (path.isEmpty) return 'Ugh, Don\'t forget to specify the file path!';
    var lines = StringBuffer();
    await File(path).readAsString().then((value) => lines.write(value));
    return lines.toString();
  }



  Widget buildShellComponent(ShellComponent shellComponent) {
    if (shellComponent is Command) {
      return Row(
        children: [
          Text(
            "~\$ ",
            style: TextStyle(color: Colors.green),
          ),
          buildShellText(shellComponent.text)
        ],
      );
    }
    return buildShellText((shellComponent as Output).text);
  }
}
