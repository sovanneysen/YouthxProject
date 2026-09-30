/// Profile fields that are stored on the device only.
///
/// The backend `User` resource has no verified profile update endpoint, so a
/// bio, a location, and an optional display-name override cannot be sent to
/// the server. They are namespaced per authenticated user id by
/// `LocalProfileStore`, which keeps one account's values from surfacing under
/// another account.
class LocalProfile {
  /// Optional local override for the account name. Null or blank means "keep
  /// showing the real `fullName` from the auth session".
  final String? displayName;

  /// Optional local device path to the selected profile image.
  final String? imagePath;

  final String bio;
  final String location;
  final String username;
  final String pronouns;
  final String links;
  final String gender;

  const LocalProfile({
    this.displayName,
    this.imagePath,
    this.bio = '',
    this.location = '',
    this.username = '',
    this.pronouns = '',
    this.links = '',
    this.gender = '',
  });

  static const LocalProfile empty = LocalProfile();

  /// Trimmed display-name override, or null when the real name should be used.
  String? get localName {
    final value = displayName?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  String get trimmedBio => bio.trim();
  String get trimmedLocation => location.trim();
  String get trimmedUsername => username.trim();
  String get trimmedPronouns => pronouns.trim();
  String get trimmedLinks => links.trim();
  String get trimmedGender => gender.trim();

  bool get hasBio => trimmedBio.isNotEmpty;
  bool get hasLocation => trimmedLocation.isNotEmpty;
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// True when nothing is worth storing, so the store can drop the record.
  bool get isEmpty => localName == null && !hasBio && !hasLocation && !hasImage &&
      trimmedUsername.isEmpty && trimmedPronouns.isEmpty && trimmedLinks.isEmpty && trimmedGender.isEmpty;

  /// Name to render: the local override when set, otherwise [fallback] from
  /// the authenticated session. Returns '' when neither is available, so the
  /// view can decide on its own placeholder instead of a fake name.
  String resolveName(String fallback) {
    final local = localName;
    if (local != null) return local;
    return fallback.trim();
  }

  /// Drops whitespace-only input so it is never stored as a real value.
  LocalProfile normalized() => LocalProfile(
        displayName: localName,
        imagePath: imagePath,
        bio: trimmedBio,
        location: trimmedLocation,
        username: trimmedUsername,
        pronouns: trimmedPronouns,
        links: trimmedLinks,
        gender: trimmedGender,
      );

  factory LocalProfile.fromJson(Map<String, dynamic> json) => LocalProfile(
        displayName: json['displayName'] as String?,
        imagePath: json['imagePath'] as String?,
        bio: json['bio'] as String? ?? '',
        location: json['location'] as String? ?? '',
        username: json['username'] as String? ?? '',
        pronouns: json['pronouns'] as String? ?? '',
        links: json['links'] as String? ?? '',
        gender: json['gender'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'imagePath': imagePath,
        'bio': bio,
        'location': location,
        'username': username,
        'pronouns': pronouns,
        'links': links,
        'gender': gender,
      };
}
