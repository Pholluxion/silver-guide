import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class ImageStreamConverter {
  final StreamController<Image> _imageController = StreamController<Image>();

  Stream<Image> get imageStream => _imageController.stream;

  ImageStreamConverter(Stream<dynamic> inputStream) {
    final transformer = StreamTransformer<dynamic, Image>.fromHandlers(
      handleData: (dynamic data, EventSink<Image> sink) async {
        final Image img = await _convertBytesToImage(data);

        sink.add(img);
      },
      handleError: (error, stackTrace, sink) {
        sink.addError(error);
      },
      handleDone: (sink) {
        sink.close();
      },
    );

    inputStream.transform(transformer).pipe(_imageController);
  }

  Future<Image> _convertBytesToImage(dynamic bytes) async {
    final Completer<Image> completer = Completer();
    try {
      final Image image = Image.memory(
        Uint8List.fromList(bytes),
        fit: BoxFit.cover,
      );
      completer.complete(image);
    } catch (error) {
      completer.completeError(error);
    }

    return Image.memory(
      Uint8List.fromList(bytes),
      fit: BoxFit.fill,
    );
  }
}
