class ImageGenerationRequest {
  final String prompt;
  final String negativePrompt;
  final String size;
  final String outputFormat;
  final int seed;
  final ImagePrompt? imagePrompt;
  final ImageGenerationMode? mode;

  static const List<String> validSizes = [
    '672x1566', // Portrait - Tall
    '768x1366', // Portrait
    '836x1254', // Portrait - Moderate
    '916x1145', // Portrait - Slight
    '1024x1024', // Square
    '1145x916', // Landscape - Slight
    '1254x836', // Landscape - Moderate
    '1366x768', // Landscape
    '1566x672', // Landscape - Wide
  ];

  ImageGenerationRequest({
    required this.prompt,
    this.negativePrompt = '',
    this.size = '1024x1024',
    this.outputFormat = 'png',
    this.seed = 0,
    this.imagePrompt,
    this.mode,
  }) {
    if (!validSizes.contains(size)) {
      throw ArgumentError(
        'Invalid size: $size. Must be one of: ${validSizes.join(", ")}',
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'prompt': prompt,
      'negative_prompt': negativePrompt,
      'size': size,
      'output_format': outputFormat,
      'seed': seed,
    };

    if (imagePrompt != null) {
      data['image_prompt'] = imagePrompt!.toJson();
    }

    if (mode != null) {
      data['prompt'] = '${prompt}, ${mode!.toPromptString()}';
    }

    return data;
  }
}

enum ImageGenerationMode {
  futuristic,
  ghibli,
  anime,
  cyberpunk,
  fantasy,
  realistic,
  cartoon,
  abstract,
  impressionist,
  surreal;

  String toPromptString() {
    switch (this) {
      case ImageGenerationMode.futuristic:
        return 'futuristic style';
      case ImageGenerationMode.ghibli:
        return 'ghibli studio style';
      case ImageGenerationMode.anime:
        return 'anime style';
      case ImageGenerationMode.cyberpunk:
        return 'cyberpunk style';
      case ImageGenerationMode.fantasy:
        return 'fantasy art style';
      case ImageGenerationMode.realistic:
        return 'realistic photo style';
      case ImageGenerationMode.cartoon:
        return 'cartoon style';
      case ImageGenerationMode.abstract:
        return 'abstract art style';
      case ImageGenerationMode.impressionist:
        return 'impressionistic art style';
      case ImageGenerationMode.surreal:
        return 'surreal art style';
    }
  }
}

class ImagePrompt {
  final String image;
  final double strength;

  ImagePrompt({required this.image, this.strength = 0.8});

  Map<String, dynamic> toJson() => {'image': image, 'strength': strength};
}

class ImageGenerationResponse {
  final String? image;
  final ImageGenerationError? error;

  ImageGenerationResponse({this.image, this.error});

  factory ImageGenerationResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return ImageGenerationResponse(
        error: ImageGenerationError.fromJson(json['error']),
      );
    }
    return ImageGenerationResponse(image: json['image'] as String?);
  }

  bool get isSuccess => image != null;
  bool get isError => error != null;
}

class ImageGenerationError {
  final String code;
  final String message;
  final int status;

  ImageGenerationError({
    required this.code,
    required this.message,
    required this.status,
  });

  factory ImageGenerationError.fromJson(Map<String, dynamic> json) {
    return ImageGenerationError(
      code: json['code'] as String,
      message: json['message'] as String,
      status: json['status'] as int,
    );
  }

  bool get isModeration => message.contains('RAI prompt moderation');
  String get userFriendlyMessage {
    if (isModeration) {
      return 'Your prompt contains content that cannot be processed. Please modify your prompt to comply with content guidelines.';
    }
    return message;
  }
}
