class LeitnerBox {
  String id;
  String name;
  int colorValue;
  LeitnerBox({required this.id, required this.name, required this.colorValue});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': colorValue};
  factory LeitnerBox.fromJson(Map<String, dynamic> j) => LeitnerBox(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Box',
        colorValue: (j['color'] as num?)?.toInt() ?? 0xFF6C63FF,
      );
}

class FlashCard {
  String id;
  String front;
  String back;
  String tags;
  int boxIndex;
  DateTime dueAt;
  bool favorite;
  int reviews;
  int lapses;
  String difficulty;
  String? frontImage;
  String? backImage;

  FlashCard({
    required this.id,
    required this.front,
    required this.back,
    this.tags = '',
    this.boxIndex = 0,
    DateTime? dueAt,
    this.favorite = false,
    this.reviews = 0,
    this.lapses = 0,
    this.difficulty = 'medium',
    this.frontImage,
    this.backImage,
  }) : dueAt = dueAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'front': front,
        'back': back,
        'tags': tags,
        'box': boxIndex,
        'due': dueAt.toIso8601String(),
        'favorite': favorite,
        'reviews': reviews,
        'lapses': lapses,
        'difficulty': difficulty,
        'frontImage': frontImage,
        'backImage': backImage,
      };

  factory FlashCard.fromJson(Map<String, dynamic> j) => FlashCard(
        id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        front: j['front'] as String? ?? '',
        back: j['back'] as String? ?? '',
        tags: j['tags'] as String? ?? '',
        boxIndex: (j['box'] as num?)?.toInt() ?? 0,
        dueAt: DateTime.tryParse(j['due'] as String? ?? '') ?? DateTime.now(),
        favorite: j['favorite'] as bool? ?? false,
        reviews: (j['reviews'] as num?)?.toInt() ?? 0,
        lapses: (j['lapses'] as num?)?.toInt() ?? 0,
        difficulty: ['hard', 'medium', 'easy'].contains(j['difficulty']) ? j['difficulty'] as String : 'auto',
        frontImage: j['frontImage'] as String?,
        backImage: j['backImage'] as String?,
      );
}

class Deck {
  String id;
  String name;
  String description;
  String colorHex;
  List<FlashCard> cards;
  List<LeitnerBox> boxes;
  Deck({required this.id, required this.name, this.description = '', this.colorHex = '6C63FF', List<FlashCard>? cards, List<LeitnerBox>? boxes})
      : cards = cards ?? [],
        boxes = boxes ?? defaultBoxes();

  static List<LeitnerBox> defaultBoxes() => [
        LeitnerBox(id: 'b1', name: 'خانه ۱', colorValue: 0xFF7C6CFF),
        LeitnerBox(id: 'b2', name: 'خانه ۲', colorValue: 0xFF4C8DFF),
        LeitnerBox(id: 'b3', name: 'خانه ۳', colorValue: 0xFF26A69A),
        LeitnerBox(id: 'b4', name: 'خانه ۴', colorValue: 0xFFFFA726),
        LeitnerBox(id: 'b5', name: 'خانه ۵', colorValue: 0xFFEF5350),
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'color': colorHex,
        'cards': cards.map((e) => e.toJson()).toList(),
        'boxes': boxes.map((e) => e.toJson()).toList(),
      };

  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
        id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: j['name'] as String? ?? 'دسته بدون نام',
        description: j['description'] as String? ?? '',
        colorHex: j['color'] as String? ?? '6C63FF',
        cards: ((j['cards'] as List?) ?? []).map((e) => FlashCard.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        boxes: ((j['boxes'] as List?) ?? []).map((e) => LeitnerBox.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
}


class QuizQuestion {
  String id;
  String prompt;
  List<String> options;
  int correctIndex;
  String explanation;

  QuizQuestion({
    required this.id,
    required this.prompt,
    required List<String> options,
    required this.correctIndex,
    this.explanation = '',
  })  : options = List<String>.from(options),
        correctIndex = options.isEmpty ? 0 : correctIndex.clamp(0, options.length - 1).toInt();

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final raw = json['options'];
    final options = raw is List ? raw.map((value) => value.toString()).toList() : <String>[];
    final requestedIndex = (json['correctIndex'] as num?)?.toInt() ?? 0;
    return QuizQuestion(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      prompt: json['prompt'] as String? ?? '',
      options: options,
      correctIndex: options.isEmpty ? 0 : requestedIndex.clamp(0, options.length - 1).toInt(),
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class QuizDefinition {
  String id;
  String title;
  String description;
  List<QuizQuestion> questions;
  DateTime updatedAt;

  QuizDefinition({
    required this.id,
    required this.title,
    this.description = '',
    List<QuizQuestion>? questions,
    DateTime? updatedAt,
  })  : questions = questions ?? <QuizQuestion>[],
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'updatedAt': updatedAt.toIso8601String(),
        'questions': questions.map((question) => question.toJson()).toList(),
      };

  factory QuizDefinition.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    return QuizDefinition(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      questions: rawQuestions is List
          ? rawQuestions.whereType<Map>().map((question) => QuizQuestion.fromJson(Map<String, dynamic>.from(question))).toList()
          : <QuizQuestion>[],
    );
  }

  QuizDefinition copyWith({String? id, String? title, String? description, List<QuizQuestion>? questions, DateTime? updatedAt}) =>
      QuizDefinition(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        questions: questions ?? this.questions,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
