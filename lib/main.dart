import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:texture_multi_window_demo/multi_window_manager.dart';
import 'package:texture_multi_window_demo/sub_window.dart';
import 'package:texture_rgba_renderer/texture_rgba_renderer.dart';
import 'package:ffi/ffi.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.isNotEmpty && args.first == "multi_window") {
    final windowId = args[1];
    WindowController.fromWindowId(int.parse(windowId)).showTitleBar(true);
    runApp(const MySubApp());
  } else {
    runApp(const MyApp());
  }
}

final textureRgbaRenderer = TextureRgbaRenderer();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Main Window',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MySubApp extends StatelessWidget {
  const MySubApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sub Window',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const SubWindowTexture(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  WindowController? _windowController;
  int textureId = -1;
  int height = 500;
  int width = 500;
  int method = 0;
  Uint8List? data;
  Timer? _timer;
  var key = 0;
  int texturePtr = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  void initState() {
    Future.microtask(() async {
      textureId = await textureRgbaRenderer.createTexture(0);
      texturePtr = await textureRgbaRenderer.getTexturePtr(0);
      setState(() {
          
      });
      
    });
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(onPressed: _handleOpenNewWindow, child: Text("1. Open New Window")),
            TextButton(onPressed: _handleSendTextureId, child: Text("2. Create And Send the texture id")),
            TextButton(onPressed: () => _start(1), child: Text("3. Start sending rgba data")),
            Container(
              width: 100,
              height: 100,
              child: Texture(textureId: textureId),)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _handleOpenNewWindow() async  {
    _windowController = await MultiWindowManager.instance.createWindow();
  }

  @override
  void dispose() {
    textureRgbaRenderer.closeTexture(0);
    super.dispose();
  }

  void _handleSendTextureId() async {
    if (_windowController == null) {
      return;
    }
    await DesktopMultiWindow.invokeMethod(_windowController!.windowId, "texture", {
      "id": textureId
    });
  }

  final random = Random();

  Uint8List mockPicture(int width, int height) {
    final pic = List.generate(width * height * 4, (index) {
      return random.nextInt(255);
    });
    return Uint8List.fromList(pic);
  }

  Pointer<Uint8> mockPicturePtr(int width, int height) {
    final pic = List.generate(width * height * 4, (index) {
      return random.nextInt(255);
    });
    final picAddr = malloc.allocate(pic.length).cast<Uint8>();
    final list = picAddr.asTypedList(pic.length);
    list.setRange(0, pic.length, pic);
    return picAddr;
  }


  void _start(int methodId) {
    debugPrint("start mockPic");
    method = methodId;
    _timer?.cancel();
    // 60 fps
    _timer =
        Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), (timer) async {
      if (methodId == 0) {
        // Method.1: with MethodChannel
        data = mockPicture(width, height);
        final res =
            await textureRgbaRenderer.onRgba(key, data!, height, width);
        if (!res) {
          debugPrint("WARN: render failed");
        }
      } else {
        final dataPtr = mockPicturePtr(width, height);
        // Method.2: with native ffi
        Native.instance.onRgba(Pointer.fromAddress(texturePtr).cast<Void>(),
            dataPtr, width, height);
        malloc.free(dataPtr);
      }
    });
  }
}
