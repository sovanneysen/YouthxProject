import '../../data/models/user_model.dart';

class MockSocialData {
  static final List<UserModel> followers = [
    UserModel(id: 'mock_1', name: 'Emma Wilson', avatarUrl: null),
    UserModel(id: 'mock_2', name: 'Liam Smith', avatarUrl: null),
  ];

  static final List<UserModel> following = [
    UserModel(id: 'mock_3', name: 'Noah Davis', avatarUrl: null),
  ];
}
