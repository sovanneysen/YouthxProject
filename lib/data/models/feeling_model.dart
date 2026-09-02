class FeelingModel {
  final String id;
  final String label;
  final String emoji;

  const FeelingModel({required this.id, required this.label, required this.emoji});

  String get display => '$emoji $label';
}

/// Static catalog of feelings a user can attach to a post, similar to
/// Facebook/Instagram "feeling" pickers.
class FeelingCatalog {
  FeelingCatalog._();

  static const List<FeelingModel> all = [
    FeelingModel(id: 'happy', label: 'Happy', emoji: '😄'),
    FeelingModel(id: 'grateful', label: 'Grateful', emoji: '🙏'),
    FeelingModel(id: 'motivated', label: 'Motivated', emoji: '💪'),
    FeelingModel(id: 'proud', label: 'Proud', emoji: '🥹'),
    FeelingModel(id: 'excited', label: 'Excited', emoji: '🤩'),
    FeelingModel(id: 'tired', label: 'Tired', emoji: '😴'),
    FeelingModel(id: 'stressed', label: 'Stressed', emoji: '😣'),
    FeelingModel(id: 'reflective', label: 'Reflective', emoji: '🤔'),
    FeelingModel(id: 'loved', label: 'Loved', emoji: '🥰'),
    FeelingModel(id: 'hopeful', label: 'Hopeful', emoji: '🌱'),
  ];
}

/// Static catalog of suggested tags. The create-post screen also allows
/// typing a free-form custom tag.
class TagCatalog {
  TagCatalog._();

  static const List<String> suggested = [
    'Goals',
    'Finance',
    'Community',
    'Reading',
    'Fitness',
    'Mindfulness',
    'Career',
    'Study',
    'Wellness',
    'Milestone',
  ];
}
