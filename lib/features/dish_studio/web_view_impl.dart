import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget getPlatform3DViewerWidget({
  required String viewId,
  required String dishId,
  required Map<String, dynamic> customizations,
}) {
  final iframeElement = html.IFrameElement()
    ..src = '3d_viewer/index.html?dishId=$dishId'
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%';

  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) => iframeElement,
  );

  iframeElement.onLoad.listen((_) {
    if (iframeElement.contentWindow != null) {
      iframeElement.contentWindow!.postMessage(
        jsonEncode({
          'type': 'LOAD_DISH',
          'dishId': dishId,
          'customizations': customizations,
        }),
        '*',
      );
    }
  });

  return HtmlElementView(viewType: viewId);
}
