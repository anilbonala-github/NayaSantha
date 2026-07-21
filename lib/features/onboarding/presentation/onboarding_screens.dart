import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../pantry/presentation/pantry_providers.dart';
import '../../profile/presentation/profile_providers.dart';

/// Backend-wired onboarding (Vol2 §6.12). Each step persists to the API and the
/// final step marks profileCompletionStatus=COMPLETE so setup is never repeated.

const List<String> _dietTypes = <String>['VEG', 'NON_VEG', 'EGGETARIAN', 'VEGAN'];
const Map<String, String> _dietLabels = <String, String>{
  'VEG': 'Vegetarian',
  'NON_VEG': 'Non-vegetarian',
  'EGGETARIAN': 'Eggetarian',
  'VEGAN': 'Vegan',
};

const List<String> _allergyOptions = <String>[
  'Peanut', 'Milk', 'Gluten', 'Soy', 'Egg', 'Tree nuts', 'Shellfish',
];

const List<String> _kitchenStaples = <String>[
  'Rice', 'Wheat flour', 'Toor dal', 'Cooking oil', 'Salt', 'Sugar',
  'Tea', 'Coffee', 'Onion', 'Potato', 'Milk', 'Ghee',
];

// --- shared chrome ----------------------------------------------------------
class _SetupScaffold extends StatelessWidget {
  const _SetupScaffold({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.busy = false,
  });

  final int step;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool busy;

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: Gap.sm),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: Gap.xl),
          Expanded(child: SingleChildScrollView(child: child)),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 592),
              child: FilledButton(
                onPressed: busy ? null : onContinue,
                child: busy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(continueLabel),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Step 1: Family ---------------------------------------------------------
class _NewMember {
  _NewMember({this.name = '', this.age});
  String name;
  int? age;
  String dietaryType = 'VEG';
  String allergies = '';
}

class FamilyProfileScreen extends ConsumerStatefulWidget {
  const FamilyProfileScreen({super.key});
  @override
  ConsumerState<FamilyProfileScreen> createState() => _FamilyProfileScreenState();
}

class _FamilyProfileScreenState extends ConsumerState<FamilyProfileScreen> {
  final List<_NewMember> _members = <_NewMember>[];
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      // Nothing added? seed a single adult so the planner has a household size.
      final toSave = _members.isEmpty ? <_NewMember>[_NewMember(name: 'Adult', age: 30)] : _members;
      for (final m in toSave) {
        await repo.addMember(
          name: m.name.trim().isEmpty ? null : m.name.trim(),
          age: m.age,
          dietaryType: m.dietaryType,
          allergies: m.allergies.trim().isEmpty ? null : m.allergies.trim(),
        );
      }
      ref.invalidate(householdProvider);
      if (mounted) context.go(Routes.address);
    } on ApiFailure catch (f) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.userMessage), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SetupScaffold(
      step: 1,
      title: 'Who is eating?',
      subtitle: 'Quantities are sized per person, and allergies become hard rules the planner never breaks.',
      busy: _busy,
      onContinue: _continue,
      child: Column(children: <Widget>[
        for (int i = 0; i < _members.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.md),
            child: NsCard(child: Row(children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surfaceMuted,
                child: Text(_members[i].name.isEmpty ? '?' : _members[i].name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.forest, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: Gap.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(_members[i].name.isEmpty ? 'Member ${i + 1}' : _members[i].name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${_dietLabels[_members[i].dietaryType]}'
                    '${_members[i].age != null ? ' · age ${_members[i].age}' : ''}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                if (_members[i].allergies.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: StatusChip(
                        label: 'Avoids ${_members[i].allergies}',
                        color: AppColors.danger,
                        icon: Icons.warning_amber_rounded),
                  ),
              ])),
              IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _members.removeAt(i))),
            ])),
          ),
        OutlinedButton.icon(
          onPressed: _showAddSheet,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add a family member'),
        ),
        const SizedBox(height: Gap.md),
        const Text('You can continue with just yourself — add others any time from Profile.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        const SizedBox(height: Gap.xl),
      ]),
    );
  }

  void _showAddSheet() {
    final m = _NewMember();
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
      builder: (c) => StatefulBuilder(builder: (c, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, MediaQuery.viewInsetsOf(c).bottom + Gap.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text('Add a family member', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: Gap.lg),
          TextField(controller: nameCtrl, textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name (optional)')),
          const SizedBox(height: Gap.md),
          TextField(controller: ageCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age (optional)')),
          const SizedBox(height: Gap.md),
          DropdownButtonFormField<String>(
            initialValue: m.dietaryType,
            decoration: const InputDecoration(labelText: 'Diet'),
            items: _dietTypes.map((d) => DropdownMenuItem<String>(value: d, child: Text(_dietLabels[d]!))).toList(),
            onChanged: (v) => setSheet(() => m.dietaryType = v ?? 'VEG'),
          ),
          const SizedBox(height: Gap.md),
          _AllergyPicker(initial: m.allergies, onChanged: (v) => m.allergies = v),
          const SizedBox(height: Gap.xl),
          FilledButton(
            onPressed: () {
              m.name = nameCtrl.text;
              m.age = int.tryParse(ageCtrl.text.trim());
              setState(() => _members.add(m));
              Navigator.of(c).pop();
            },
            child: const Text('Add member'),
          ),
        ]),
      )),
    );
  }
}

/// Multi-select allergy chips that emit a comma-joined string.
class _AllergyPicker extends StatefulWidget {
  const _AllergyPicker({required this.initial, required this.onChanged});
  final String initial;
  final ValueChanged<String> onChanged;
  @override
  State<_AllergyPicker> createState() => _AllergyPickerState();
}

class _AllergyPickerState extends State<_AllergyPicker> {
  late final Set<String> _sel = widget.initial.isEmpty
      ? <String>{}
      : widget.initial.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Text('Allergies (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: Gap.sm),
      Wrap(spacing: Gap.sm, runSpacing: Gap.sm, children: _allergyOptions.map((a) {
        final on = _sel.contains(a);
        return FilterChip(
          label: Text(a),
          selected: on,
          showCheckmark: false,
          selectedColor: AppColors.danger.withValues(alpha: 0.15),
          side: BorderSide(color: on ? AppColors.danger : AppColors.border),
          onSelected: (_) => setState(() {
            on ? _sel.remove(a) : _sel.add(a);
            widget.onChanged(_sel.join(', '));
          }),
        );
      }).toList()),
    ]);
  }
}

// --- Step 3: Budget & price handling ----------------------------------------
class DietaryScreen extends ConsumerStatefulWidget {
  const DietaryScreen({super.key});
  @override
  ConsumerState<DietaryScreen> createState() => _DietaryScreenState();
}

class _DietaryScreenState extends ConsumerState<DietaryScreen> {
  double _budget = 1500;
  String _consent = 'AUTO_WITHIN_MAX';
  bool _busy = false;
  bool _seeded = false;

  static const Map<String, ({String title, String desc})> _consents = <String, ({String title, String desc})>{
    'AUTO_WITHIN_MAX': (title: 'Auto within my max', desc: 'Charge the final amount automatically as long as it stays under my guaranteed maximum.'),
    'ASK': (title: 'Ask me first', desc: 'Send an approval request if anything material changes.'),
    'NO_SUBSTITUTION': (title: 'No substitutions', desc: 'Keep exact items; ask me when the total would exceed my maximum.'),
  };

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateHousehold(
            weeklyBudget: _budget,
            defaultPriceConsent: _consent,
          );
      ref.invalidate(householdProvider);
      if (mounted) context.go(Routes.kitchen);
    } on ApiFailure catch (f) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.userMessage), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefill the budget from the household once loaded.
    final household = ref.watch(householdProvider);
    household.whenData((h) {
      if (!_seeded && h.weeklyBudget > 0) {
        _seeded = true;
        _budget = h.weeklyBudget.clamp(500, 5000).toDouble();
      }
    });

    return _SetupScaffold(
      step: 3,
      title: 'Budget & price handling',
      subtitle: 'The planner keeps every basket under your budget, and this decides how we handle Sunday price changes.',
      busy: _busy,
      onContinue: _continue,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text('Weekly grocery budget', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: Gap.md),
        NsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            Text(money(_budget), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const Text('per week', style: TextStyle(color: AppColors.textSecondary)),
          ]),
          Slider(
            value: _budget, min: 500, max: 5000, divisions: 45,
            label: money(_budget),
            onChanged: (v) => setState(() => _budget = v),
          ),
        ])),
        const SizedBox(height: Gap.xl),
        const Text('When Sunday prices change', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: Gap.md),
        for (final entry in _consents.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: NsCard(
              borderColor: _consent == entry.key ? AppColors.primary : AppColors.border,
              onTap: () => setState(() => _consent = entry.key),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Icon(_consent == entry.key ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20, color: _consent == entry.key ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: Gap.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(entry.value.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(entry.value.desc,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
                ])),
              ]),
            ),
          ),
        const SizedBox(height: Gap.xl),
      ]),
    );
  }
}

// --- Step 4: Kitchen staples -> pantry --------------------------------------
class KitchenSetupScreen extends ConsumerStatefulWidget {
  const KitchenSetupScreen({super.key});
  @override
  ConsumerState<KitchenSetupScreen> createState() => _KitchenSetupScreenState();
}

class _KitchenSetupScreenState extends ConsumerState<KitchenSetupScreen> {
  final Set<String> _have = <String>{};
  bool _busy = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      final pantry = ref.read(pantryRepositoryProvider);
      for (final s in _have) {
        await pantry.add(name: s, quantity: 1);
      }
      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.completeOnboarding();
      ref.invalidate(profileProvider);
      ref.invalidate(householdProvider);
      ref.invalidate(pantryProvider);
      if (mounted) context.go(Routes.home);
    } on ApiFailure catch (f) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.userMessage), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SetupScaffold(
      step: 4,
      title: 'What is already in your kitchen?',
      subtitle: 'Tick the staples you keep stocked — we skip them in your first plan and start tracking when they run low.',
      continueLabel: 'Finish setup',
      busy: _busy,
      onContinue: _finish,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Wrap(spacing: Gap.sm, runSpacing: Gap.sm, children: _kitchenStaples.map((s) {
          final on = _have.contains(s);
          return FilterChip(
            label: Text(s),
            selected: on,
            showCheckmark: false,
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            side: BorderSide(color: on ? AppColors.primary : AppColors.border),
            onSelected: (_) => setState(() => on ? _have.remove(s) : _have.add(s)),
          );
        }).toList()),
        const SizedBox(height: Gap.xl),
        const NsCard(
          color: AppColors.surfaceMuted,
          borderColor: AppColors.surfaceMuted,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
            SizedBox(width: Gap.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text('What happens next', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('We build your first AI weekly plan sized to your household and budget. '
                  'You review the estimate and guaranteed maximum before anything is ordered.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45)),
            ])),
          ]),
        ),
        const SizedBox(height: Gap.xl),
      ]),
    );
  }
}
