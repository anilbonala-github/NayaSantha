import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';

/// Shared chrome for the four setup steps so progress is always visible.
class _SetupScaffold extends StatelessWidget {
  const _SetupScaffold({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onContinue,
    this.continueLabel = 'Continue',
  });

  final int step; // 1..4
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step $step of 4'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: step / 4,
            minHeight: 3,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
      ),
      body: PageBody(
        maxWidth: 640,
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Gap.sm),
            Text(subtitle,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.xl),
            Expanded(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 592),
              child: FilledButton(
                onPressed: onContinue,
                child: Text(continueLabel),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 06 — Family profile. Household size drives every quantity the planner picks.
class FamilyProfileScreen extends StatelessWidget {
  const FamilyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    return _SetupScaffold(
      step: 1,
      title: 'Who is eating?',
      subtitle:
          'Quantities are sized per person, so an accurate list means less '
          'waste and a smaller bill.',
      onContinue: () => context.go(Routes.address),
      child: Column(
        children: <Widget>[
          ...app.family.map(
            (FamilyMember m) => Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: NsCard(
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surfaceMuted,
                      child: Text(
                        m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(m.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          Text(
                            '${m.ageGroup.label} · ${m.diet.label}',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary),
                          ),
                          if (m.allergies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: StatusChip(
                                label: 'Avoids ${m.allergies.join(", ")}',
                                color: AppColors.danger,
                                icon: Icons.warning_amber_rounded,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => app.removeFamilyMember(m.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showAddMemberSheet(context, app),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add a family member'),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  void _showAddMemberSheet(BuildContext context, AppState app) {
    final TextEditingController name = TextEditingController();
    AgeGroup age = AgeGroup.adult;
    DietType diet = DietType.vegetarian;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (BuildContext c) => StatefulBuilder(
        builder: (BuildContext c, StateSetter setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            Gap.xl,
            Gap.xl,
            Gap.xl,
            MediaQuery.viewInsetsOf(c).bottom + Gap.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Add a family member',
                  style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: Gap.lg),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: Gap.lg),
              DropdownButtonFormField<AgeGroup>(
                value: age,
                decoration: const InputDecoration(labelText: 'Age group'),
                items: AgeGroup.values
                    .map((AgeGroup a) => DropdownMenuItem<AgeGroup>(
                        value: a, child: Text(a.label)))
                    .toList(),
                onChanged: (AgeGroup? v) =>
                    setSheet(() => age = v ?? AgeGroup.adult),
              ),
              const SizedBox(height: Gap.lg),
              DropdownButtonFormField<DietType>(
                value: diet,
                decoration: const InputDecoration(labelText: 'Diet'),
                items: DietType.values
                    .map((DietType d) => DropdownMenuItem<DietType>(
                        value: d, child: Text(d.label)))
                    .toList(),
                onChanged: (DietType? v) =>
                    setSheet(() => diet = v ?? DietType.vegetarian),
              ),
              const SizedBox(height: Gap.xl),
              FilledButton(
                onPressed: () {
                  if (name.text.trim().isEmpty) return;
                  app.addFamilyMember(
                    FamilyMember(
                      id: 'fm_${DateTime.now().millisecondsSinceEpoch}',
                      name: name.text.trim(),
                      ageGroup: age,
                      diet: diet,
                    ),
                  );
                  Navigator.of(c).pop();
                },
                child: const Text('Add member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 07 — Delivery address.
class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    return _SetupScaffold(
      step: 2,
      title: 'Where should we deliver?',
      subtitle: 'We deliver across Hyderabad, in 2-hour slots you choose.',
      onContinue: () => context.go(Routes.dietary),
      child: Column(
        children: <Widget>[
          ...app.addresses.map(
            (Address a) => Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: NsCard(
                borderColor:
                    a.isDefault ? AppColors.primary : AppColors.border,
                onTap: () => app.setDefaultAddress(a.id),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      a.isDefault
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: a.isDefault
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(a.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            a.oneLine,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showAddAddressSheet(context, app),
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: const Text('Add a new address'),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context, AppState app) {
    final TextEditingController label = TextEditingController(text: 'Home');
    final TextEditingController line1 = TextEditingController();
    final TextEditingController line2 = TextEditingController();
    final TextEditingController pin = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (BuildContext c) => Padding(
        padding: EdgeInsets.fromLTRB(
          Gap.xl,
          Gap.xl,
          Gap.xl,
          MediaQuery.viewInsetsOf(c).bottom + Gap.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Add an address', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: label,
              decoration:
                  const InputDecoration(labelText: 'Label (Home, Office)'),
            ),
            const SizedBox(height: Gap.md),
            TextField(
              controller: line1,
              decoration:
                  const InputDecoration(labelText: 'Flat / house number'),
            ),
            const SizedBox(height: Gap.md),
            TextField(
              controller: line2,
              decoration:
                  const InputDecoration(labelText: 'Building, area'),
            ),
            const SizedBox(height: Gap.md),
            TextField(
              controller: pin,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  labelText: 'Pincode', counterText: ''),
            ),
            const SizedBox(height: Gap.lg),
            FilledButton(
              onPressed: () {
                if (line1.text.trim().isEmpty || pin.text.length != 6) return;
                app.addAddress(
                  Address(
                    id: 'ad_${DateTime.now().millisecondsSinceEpoch}',
                    label: label.text.trim(),
                    line1: line1.text.trim(),
                    line2: line2.text.trim(),
                    city: 'Hyderabad',
                    pincode: pin.text.trim(),
                    isDefault: true,
                  ),
                );
                Navigator.of(c).pop();
              },
              child: const Text('Save address'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 08 — Dietary preferences. Allergies here become hard exclusions in the plan.
class DietaryScreen extends StatelessWidget {
  const DietaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final Set<String> allergies = <String>{
      for (final FamilyMember m in app.family) ...m.allergies,
    };
    final Set<String> goals = <String>{
      for (final FamilyMember m in app.family) ...m.healthGoals,
    };

    return _SetupScaffold(
      step: 3,
      title: 'Food preferences',
      subtitle:
          'Allergies are treated as hard rules — flagged items never enter '
          'your plan or basket.',
      onContinue: () => context.go(Routes.kitchen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _FieldLabel('Cuisines you cook most'),
          _ChipWrap(
            options: MockData.cuisineOptions,
            selected: app.cuisines,
            onToggle: app.toggleCuisine,
          ),
          const SizedBox(height: Gap.xl),
          const _FieldLabel('Allergies across the household'),
          _ChipWrap(
            options: MockData.allergyOptions,
            selected: allergies,
            selectedColor: AppColors.danger,
            onToggle: (String a) => _toggleOnFirstMember(app, a, allergy: true),
          ),
          const SizedBox(height: Gap.xl),
          const _FieldLabel('Health goals'),
          _ChipWrap(
            options: MockData.healthGoalOptions,
            selected: goals,
            onToggle: (String g) =>
                _toggleOnFirstMember(app, g, allergy: false),
          ),
          const SizedBox(height: Gap.xl),
          const _FieldLabel('Weekly grocery budget'),
          NsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      money(app.weeklyBudget),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const Text('per week',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                Slider(
                  value: app.weeklyBudget,
                  min: 500,
                  max: 5000,
                  divisions: 45,
                  onChanged: app.setWeeklyBudget,
                ),
                const Text(
                  'The planner keeps the basket under this figure and tells '
                  'you what it changed to get there.',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  void _toggleOnFirstMember(AppState app, String value,
      {required bool allergy}) {
    if (app.family.isEmpty) return;
    final FamilyMember m = app.family.first;
    final List<String> list =
        allergy ? List<String>.from(m.allergies) : List<String>.from(m.healthGoals);
    list.contains(value) ? list.remove(value) : list.add(value);
    if (allergy) {
      m.allergies = list;
    } else {
      m.healthGoals = list;
    }
    app.updateFamilyMember(m);
  }
}

/// 09 — AI kitchen setup. What is already at home so the planner does not
/// re-buy it in week one.
class KitchenSetupScreen extends StatelessWidget {
  const KitchenSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    return _SetupScaffold(
      step: 4,
      title: 'What is already in your kitchen?',
      subtitle:
          'Tick the staples you keep stocked. We will skip them in your first '
          'plan and start tracking when they run low.',
      continueLabel: 'Finish setup',
      onContinue: () {
        app.completeOnboarding();
        context.go(Routes.home);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ChipWrap(
            options: MockData.kitchenStaples,
            selected: app.staples,
            onToggle: app.toggleStaple,
          ),
          const SizedBox(height: Gap.xl),
          NsCard(
            color: AppColors.surfaceMuted,
            borderColor: AppColors.surfaceMuted,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.auto_awesome,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('What happens next',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'We build a 21-meal plan for ${app.family.length} '
                        'people, size every quantity, and keep the total under '
                        '${money(app.weeklyBudget)}. You review it before '
                        'anything is ordered.',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.options,
    required this.selected,
    required this.onToggle,
    this.selectedColor = AppColors.primary,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Gap.sm,
      runSpacing: Gap.sm,
      children: options.map((String o) {
        final bool on = selected.contains(o);
        return FilterChip(
          label: Text(o),
          selected: on,
          showCheckmark: false,
          selectedColor: selectedColor.withValues(alpha: 0.15),
          side: BorderSide(color: on ? selectedColor : AppColors.border),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: on ? selectedColor : AppColors.textPrimary,
          ),
          onSelected: (_) => onToggle(o),
        );
      }).toList(),
    );
  }
}
