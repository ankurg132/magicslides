class PresentationRequest {
  final String topic;
  final String email;
  final String accessId;
  final String template;
  final int slideCount;
  final String language;
  final bool aiImages;
  final bool imageForEachSlide;
  final bool googleImage;
  final bool googleText;
  final String model;
  final String presentationFor;
  final WatermarkRequest? watermark;

  PresentationRequest({
    required this.topic,
    required this.email,
    required this.accessId,
    required this.template,
    required this.slideCount,
    required this.language,
    required this.aiImages,
    required this.imageForEachSlide,
    required this.googleImage,
    required this.googleText,
    required this.model,
    required this.presentationFor,
    this.watermark,
  });

  Map<String, dynamic> toJson() {
    return {
      "topic": topic,
      "email": email,
      "accessId": accessId,
      "template": template,
      "slideCount": slideCount,
      "language": language,
      "aiImages": aiImages,
      "imageForEachSlide": imageForEachSlide,
      "googleImage": googleImage,
      "googleText": googleText,
      "model": model,
      "presentationFor": presentationFor,
      if (watermark != null) "watermark": watermark!.toJson(),
    };
  }
}

class WatermarkRequest {
  final String width;
  final String height;
  final String brandUrl;
  final String position;

  WatermarkRequest({
    required this.width,
    required this.height,
    required this.brandUrl,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      if (width.isNotEmpty) "width": width,
      if (height.isNotEmpty) "height": height,
      if (brandUrl.isNotEmpty) "brandURL": brandUrl,
      if (position.isNotEmpty) "position": position,
    };
  }
}
