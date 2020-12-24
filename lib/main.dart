import 'dart:convert';
import "package:path/path.dart" as Path;
import 'dart:io';
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
  List<String> lines = [];

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
                child: Container(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines
                          .map((e) => Text(
                                '~\$ $e',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ))
                          .toList(),
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
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      )
                    ),
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onEditingComplete: () async {
                      // print('Enteeeeeeeeeeeeer');
                      setState(() {
                        lines.add(controller.text);
                      });
                      final process =
                          await Process.run(controller.text.toLowerCase(), [])
                              .catchError((error) => print(error));
                      final envVarMap = Platform.environment;
                      print(process?.stdout);
                      if (process != null ||
                          envVarMap[controller.text.toUpperCase()] != null)
                        setState(() {
                          lines.add(process?.stdout ??
                              envVarMap[controller.text.toUpperCase()]);
                        });
                      else {
                        List<String> wordsOfTheCommand =
                            controller.text.split(' ');
                        String firstWord = wordsOfTheCommand[0];
                        if (firstWord == 'cat') {
                          var theContentsOfTheFile =
                              await _readAFile(wordsOfTheCommand[1] ?? '');
                          // print('cat heeere');
                          setState(() {
                            lines.add(theContentsOfTheFile);
                          });
                        } else if (firstWord == 'mkfile') {
                          if (wordsOfTheCommand[1].isNotEmpty)
                            _makeFile(wordsOfTheCommand[1]);
                          else
                            setState(() {
                              lines.add(
                                  'Ugh, Don\'t forget to specify the file path!');
                            });
                        } else if (firstWord == 'mkdir') {
                          String path =
                              await _makeDirectory(wordsOfTheCommand[1]);
                          setState(() {
                            lines.add(path);
                          });
                        } else if (firstWord == 'cd') {
                          // lines.add(Directory.current.path);
                          Directory.current = wordsOfTheCommand[1];
                          lines.add(Directory.current.path);
                        } else {
                          lines.add('This command hasn\'t been added yet!');
                        }
                      }
                      controller.clear();
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

  Future<String> _readAFile(String path) async {
    if (path.isEmpty) return 'Ugh, Don\'t forget to specify the file path!';
    var lines = StringBuffer();
    await File(path).readAsString().then((value) => lines.write(value));
    // print('heeeey: $lines');
    return lines.toString();
  }

  Future<void> _makeFile(String path) async {
    File(path).create(recursive: true);
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
}
