import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class SubWindowTexture extends StatefulWidget {
  const SubWindowTexture({super.key});

  @override
  State<SubWindowTexture> createState() => _SubWindowTextureState();
}

class _SubWindowTextureState extends State<SubWindowTexture> {

  var textureId = -1;

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
      body: Container(
        child: Texture(textureId: textureId),
      ),
    );
  }
}