/// Profile + household mirroring the backend (Vol2 §6.12).
class Profile {
  const Profile({
    required this.id,
    required this.mobile,
    this.name,
    this.email,
    required this.profileCompletionStatus,
  });

  final String id;
  final String mobile;
  final String? name;
  final String? email;
  final String profileCompletionStatus;

  String get displayName => (name == null || name!.isEmpty) ? 'NayaSantha member' : name!;
  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : 'N';

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        mobile: j['mobile'] as String,
        name: j['name'] as String?,
        email: j['email'] as String?,
        profileCompletionStatus: j['profileCompletionStatus'] as String? ?? 'NEW',
      );
}

class HouseholdMember {
  const HouseholdMember({this.name, this.age, required this.dietaryType, this.allergies});
  final String? name;
  final int? age;
  final String dietaryType;
  final String? allergies;

  factory HouseholdMember.fromJson(Map<String, dynamic> j) => HouseholdMember(
        name: j['name'] as String?,
        age: (j['age'] as num?)?.toInt(),
        dietaryType: j['dietaryType'] as String? ?? 'VEG',
        allergies: j['allergies'] as String?,
      );
}

class Household {
  const Household({
    required this.weeklyBudget,
    required this.defaultPriceConsent,
    this.members = const <HouseholdMember>[],
  });

  final double weeklyBudget;
  final String defaultPriceConsent;
  final List<HouseholdMember> members;

  factory Household.fromJson(Map<String, dynamic> j) => Household(
        weeklyBudget: (j['weeklyBudget'] as num?)?.toDouble() ?? 0,
        defaultPriceConsent: j['defaultPriceConsent'] as String? ?? 'ASK',
        members: (j['members'] as List?)
                ?.map((e) => HouseholdMember.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <HouseholdMember>[],
      );
}
