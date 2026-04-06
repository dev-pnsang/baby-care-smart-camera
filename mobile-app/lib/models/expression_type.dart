enum ExpressionType {
  happy,
  sad,
  surprised,
  sleepy,
  playful,
  calm,
}

extension ExpressionTypeExtension on ExpressionType {
  String get emoji {
    switch (this) {
      case ExpressionType.happy:
        return '😄';
      case ExpressionType.sad:
        return '😢';
      case ExpressionType.surprised:
        return '😮';
      case ExpressionType.sleepy:
        return '😉';
      case ExpressionType.playful:
        return '😘';
      case ExpressionType.calm:
        return '❤️';
    }
  }
  
  String get name {
    switch (this) {
      case ExpressionType.happy:
        return 'Vui vẻ';
      case ExpressionType.sad:
        return 'Buồn';
      case ExpressionType.surprised:
        return 'Ngạc nhiên';
      case ExpressionType.sleepy:
        return 'Buồn ngủ';
      case ExpressionType.playful:
        return 'Vui đùa';
      case ExpressionType.calm:
        return 'Bình tĩnh';
    }
  }

  /// English id for hardware / `notifyHardware` (distinct from [name] labels).
  String get hardwareChannel {
    switch (this) {
      case ExpressionType.happy:
        return 'happy';
      case ExpressionType.sad:
        return 'sad';
      case ExpressionType.surprised:
        return 'surprised';
      case ExpressionType.sleepy:
        return 'sleepy';
      case ExpressionType.playful:
        return 'playful';
      case ExpressionType.calm:
        return 'calm';
    }
  }
}

