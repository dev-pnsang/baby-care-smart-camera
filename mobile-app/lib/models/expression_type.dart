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
}

