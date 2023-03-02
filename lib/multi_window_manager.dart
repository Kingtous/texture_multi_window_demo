import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

class MultiWindowManager {
  MultiWindowManager._();

  static MultiWindowManager _manager = MultiWindowManager._();
  static MultiWindowManager get instance => _manager;


  Future<WindowController> createWindow() async {
    final controller = await DesktopMultiWindow.createWindow(jsonEncode({
                    'args1': 'Sub window',
                    'args2': 100,
                    'args3': true,
                    'bussiness': 'bussiness_test',
                  }));
    controller.center();
    controller.show();
    return controller;
  }
}