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

  final String bio;
  final String location;

  const LocalProfile({
    this.displayName,
    this.bio = '',
    this.location = '',
  });

  static const LocalProfile empty = LocalProfile();

  /// Trimmed display-name override, or null when the real name should be used.
  String? get localName {
    final value = displayName?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  String get trimmedBio => bio.trim();
  String get trimmedLocation => location.trim();

  bool get hasBio => trimmedBio.isNotEmpty;
  bool get hasLocation => trimmedLocation.isNotEmpty;

  /// True when nothing is worth storing, so the store can drop the record.
  bool get isEmpty => localName == null && !hasBio && !hasLocation;

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
        bio: trimmedBio,
        location: trimmedLocation,
      );

  factory LocalProfile.fromJson(Map<String, dynamic> json) => LocalProfile(
        displayName: json['displayName'] as String?,
        bio: json['bio'] as String? ?? '',
        location: json['location'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'bio': bio,
        'location': location,
      };
}
