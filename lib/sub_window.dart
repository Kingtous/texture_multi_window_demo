import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:texture_rgba_renderer/texture_rgba_renderer.dart';

final textureRgbaRenderer = TextureRgbaRenderer();

class SubWindowTexture extends StatefulWidget {
  const SubWindowTexture({super.key});

  @override
  State<SubWindowTexture> createState() => _SubWindowTextureState();
}

class _SubWindowTextureState extends State<SubWindowTexture> {

  var textureId = -1;
  int _counter = 0;
  WindowController? _windowController;
  int height = 500;
  int width = 500;
  int method = 0;
  Uint8List? data;
  Timer? _timer;
  var key = 0;
  final random = Random();
  int texturePtr = 0;

  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == "texture") {
        setState(() {
          textureId = call.arguments['id'];
          print("set texture Id = ${textureId}");
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(textureId == -1 ? "Please send texture id to this window": "Texture ID: ${textureId}"),
      ),
      body: Stack(
        children: [
          Container(
            child: Texture(textureId: textureId),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: _handleTextureId,
                  child: Text("2. Create And Send the texture id")),
              TextButton(
                  onPressed: () => _start(1),
                  child: Text("3. Start sending rgba data")),
            ],
          )
        ],
      ),
    );
  }

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
            await textureRgbaRenderer.onRgba(key, data!, height, width, 16);
        if (!res) {
          debugPrint("WARN: render failed");
        }
      } else {
        final dataPtr = mockPicturePtr(width, height);
        // Method.2: with native ffi
        Native.instance.onRgba(Pointer.fromAddress(texturePtr).cast<Void>(),
            dataPtr, width * height * 4, width, height, 16);
        malloc.free(dataPtr);
      }
    });
  }

  void _handleTextureId() async {
    textureId = await textureRgbaRenderer.createTexture(1);
    texturePtr = await textureRgbaRenderer.getTexturePtr(1);
    setState(() {});
  }
}