import 'dart:html' as html;
import 'dart:typed_data';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('faceapi')
external dynamic get faceApi;

@JS('faceapi.loadModels')
external Future<void> loadModels();

@JS('faceapi.detectSingleFace')
external Future<dynamic> detectSingleFace(dynamic input);

@JS('faceapi.getFaceDescriptor')
external Future<List<num>> getFaceDescriptor(dynamic detection);

@JS('faceapi.drawFaceDetections')
external void drawFaceDetections(dynamic canvas, dynamic detections);

class FaceApiUtils {
  static Future<void> initialize() async {
    await promiseToFuture(loadModels());
  }

  static Future<List<double>?> getFaceDescriptorFromImage(html.ImageElement image) async {
    try {
      final detection = await promiseToFuture(detectSingleFace(image));
      if (detection == null) return null;
      
      final descriptor = await promiseToFuture(getFaceDescriptor(detection));
      return descriptor.map((e) => e.toDouble()).toList();
    } catch (e) {
      print('Error in face detection: $e');
      return null;
    }
  }

  static Future<List<double>?> getFaceDescriptorFromVideo(html.VideoElement video) async {
    try {
      final detection = await promiseToFuture(detectSingleFace(video));
      if (detection == null) return null;
      
      final descriptor = await promiseToFuture(getFaceDescriptor(detection));
      return descriptor.map((e) => e.toDouble()).toList();
    } catch (e) {
      print('Error in face detection: $e');
      return null;
    }
  }
}