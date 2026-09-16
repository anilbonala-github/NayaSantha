import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../pantry/presentation/pantry_providers.dart';
import '../../profile/domain/profile_models.dart';
import '../../profile/presentation/profile_providers.dart';

const dietLabels = <String, String>{
  'VEG': 'Vegetarian',
  'NON_VEG': 'Non-vegetarian',
  'EGGETARIAN': 'Eggetarian',
  'VEGAN': 'Vegan',
};
const allergyOptions = <String>[
  'Peanut',
  'Milk',
  'Gluten',
  'Soy',
  'Egg',
  'Tree nuts',
  'Shellfish',
];

String setupError(Object error) => error is ApiFailure
    ? error.userMessage
    : 'Could not save your changes. Please try again.';

/// The footer takes only its content height, leaving room for the form.
/// Shared by all setup steps, including the reusable address editor.
class SetupScaffold extends StatelessWidget {
  const SetupScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onContinue,
    required this.backRoute,
    this.continueLabel = 'Continue',
    this.busy = false,
    this.editing = false,
  });
  final int step;
  final String title, subtitle, backRoute, continueLabel;
  final Widget child;
  final VoidCallback? onContinue;
  final bool busy, editing;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: busy ? null : () => context.go(backRoute),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(editing ? title : 'Step $step of 4'),
          bottom: editing
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: step / 4,
                    minHeight: 3,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                  ),
                ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: PageBody(
            maxWidth: 640,
            padding: const EdgeInsets.all(Gap.xl),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: Gap.sm),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: Gap.xl),
              child,
            ]),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 592),
                child: FilledButton(
                  onPressed: busy ? null : onContinue,
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(continueLabel),
                ),
              ),
            ),
          ),
        ),
      );
}

class FamilyProfileScreen extends ConsumerStatefulWidget {
  const FamilyProfileScreen({super.key, this.editing = false});
  final bool editing;
  @override
  ConsumerState<FamilyProfileScreen> createState() =>
      _FamilyProfileScreenState();
}

class _FamilyProfileScreenState extends ConsumerState<FamilyProfileScreen> {
  bool _busy = false;

  Future<void> _edit([HouseholdMember? member]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MemberDialog(member: member),
    );
    if (saved == true) ref.invalidate(householdProvider);
  }

  Future<void> _remove(HouseholdMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove household member?'),
        content: Text(
            'Remove ${member.name?.isNotEmpty == true ? member.name : 'this person'} from future weekly plans?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep member')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).removeMember(member.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(setupError(error))));
      }
    } finally {
      ref.invalidate(householdProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider);
    final members = household.asData?.value.members ?? <HouseholdMember>[];
    return SetupScaffold(
      step: 1,
      title: 'Your household',
      editing: widget.editing,
      subtitle:
          'Add everyone you shop for, including yourself. Names and ages are optional. Changes are saved as you go.',
      backRoute: Routes.profile,
      busy: _busy,
      continueLabel: widget.editing ? 'Done' : 'Continue to delivery address',
      onContinue: household.hasValue && members.isNotEmpty
          ? () => context.go(widget.editing ? Routes.profile : Routes.address)
          : null,
      child: household.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Column(children: [
          Text(setupError(e)),
          TextButton(
              onPressed: () => ref.invalidate(householdProvider),
              child: const Text('Retry')),
        ]),
        data: (h) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (h.members.isEmpty)
            const NsCard(
              child: Text(
                  'Start by adding yourself. We use the people and preferences you enter to suggest suitable quantities.'),
            ),
          for (var i = 0; i < h.members.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: NsCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        h.members[i].name?.isNotEmpty == true
                            ? h.members[i].name!
                            : 'Person ${i + 1}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        '${dietLabels[h.members[i].dietaryType] ?? h.members[i].dietaryType}'
                        '${h.members[i].age == null ? '' : ' · Age ${h.members[i].age}'}'),
                    if (h.members[i].allergies?.isNotEmpty == true)
                      Padding(
                          padding: const EdgeInsets.only(top: Gap.sm),
                          child: Text('Allergies: ${h.members[i].allergies}',
                              style: const TextStyle(color: AppColors.danger))),
                    Wrap(spacing: Gap.sm, children: [
                      TextButton.icon(
                        onPressed: _busy ? null : () => _edit(h.members[i]),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                      TextButton.icon(
                        onPressed: _busy || h.members.length <= 1
                            ? null
                            : () => _remove(h.members[i]),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                      ),
                    ]),
                  ])),
            ),
          const SizedBox(height: Gap.md),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _edit(),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(
                h.members.isEmpty ? 'Add yourself' : 'Add household member'),
          ),
          const SizedBox(height: Gap.sm),
          const Text(
              'Keep at least one person in your household. You can edit these details later from Account.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _MemberDialog extends ConsumerStatefulWidget {
  const _MemberDialog({this.member});
  final HouseholdMember? member;
  @override
  ConsumerState<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends ConsumerState<_MemberDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.member?.name ?? '');
  late final _age =
      TextEditingController(text: widget.member?.age?.toString() ?? '');
  late String _diet = widget.member?.dietaryType ?? 'VEG';
  late final Set<String> _allergies = (widget.member?.allergies ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();
  late final _other = TextEditingController(
      text: _allergies.where((a) => !allergyOptions.contains(a)).join(', '));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _other.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final allergies = <String>{
      ..._allergies.where(allergyOptions.contains),
      ..._other.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
    }.join(', ');
    try {
      final repo = ref.read(profileRepositoryProvider);
      if (widget.member == null) {
        await repo.addMember(
            name: _name.text.trim(),
            age: int.tryParse(_age.text),
            dietaryType: _diet,
            allergies: allergies);
      } else {
        await repo.updateMember(
            id: widget.member!.id,
            version: widget.member!.version,
            name: _name.text.trim(),
            age: int.tryParse(_age.text),
            dietaryType: _diet,
            allergies: allergies);
      }
      ref.invalidate(householdProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      ref.invalidate(householdProvider);
      if (mounted) {
        setState(() {
          _saving = false;
          _error = setupError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: AlertDialog(
          insetPadding: const EdgeInsets.all(Gap.lg),
          scrollable: true,
          title: Text(widget.member == null
              ? 'Add household member'
              : 'Edit household member'),
          content: SizedBox(
              width: 440,
              child: Form(
                key: _form,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                          controller: _name,
                          enabled: !_saving,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Name (optional)')),
                      const SizedBox(height: Gap.sm),
                      TextFormField(
                          controller: _age,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                              labelText: 'Age (optional)'),
                          validator: (v) => v != null &&
                                  v.isNotEmpty &&
                                  (int.tryParse(v) == null ||
                                      int.parse(v) > 120)
                              ? 'Enter an age between 0 and 120'
                              : null),
                      const SizedBox(height: Gap.md),
                      DropdownButtonFormField<String>(
                        initialValue: _diet,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Diet'),
                        items: dietLabels.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged:
                            _saving ? null : (v) => setState(() => _diet = v!),
                      ),
                      const SizedBox(height: Gap.lg),
                      const Text('Allergies (optional)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: Gap.sm),
                      Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: allergyOptions
                              .map((a) => FilterChip(
                                    label: Text(a),
                                    selected: _allergies.contains(a),
                                    onSelected: _saving
                                        ? null
                                        : (on) => setState(() {
                                              on
                                                  ? _allergies.add(a)
                                                  : _allergies.remove(a);
                                            }),
                                  ))
                              .toList()),
                      const SizedBox(height: Gap.md),
                      TextFormField(
                          controller: _other,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                              labelText: 'Other allergies',
                              hintText: 'Separate with commas')),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: Gap.md),
                          child: Text(_error!,
                              style: const TextStyle(color: AppColors.danger)),
                        ),
                    ]),
              )),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save member'),
            ),
          ],
        ),
      );
}

/// Budget changes are independent of the old price-consent system.
/// Fixed weekly selling prices are implemented in the next pricing milestone.
class DietaryScreen extends ConsumerStatefulWidget {
  const DietaryScreen({super.key, this.editing = false});
  final bool editing;
  @override
  ConsumerState<DietaryScreen> createState() => _DietaryScreenState();
}

class _DietaryScreenState extends ConsumerState<DietaryScreen> {
  final _form = GlobalKey<FormState>();
  final _budget = TextEditingController();
  bool _seeded = false, _busy = false;
  int? _version;
  String? _error;

  @override
  void dispose() {
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateHousehold(
          weeklyBudget: double.parse(_budget.text.trim()), version: _version);
      ref.invalidate(householdProvider);
      if (mounted) context.go(widget.editing ? Routes.profile : Routes.kitchen);
    } catch (error) {
      if (mounted) setState(() => _error = setupError(error));
      if (error is ApiFailure && error.isVersionConflict) {
        ref.invalidate(householdProvider);
        try {
          final latest = await ref.read(householdProvider.future);
          if (mounted) _version = latest.version;
        } catch (_) {
          // Keep the entered value and show the original save error.
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider);
    final h = household.asData?.value;
    if (!_seeded && h != null) {
      _seeded = true;
      _version = h.version;
      _budget.text = h.weeklyBudget > 0
          ? h.weeklyBudget.toStringAsFixed(h.weeklyBudget % 1 == 0 ? 0 : 2)
          : '';
    }
    return SetupScaffold(
      step: 3,
      title: 'Your weekly budget',
      editing: widget.editing,
      subtitle:
          'Choose a comfortable grocery budget. You can change it any time.',
      backRoute: widget.editing ? Routes.profile : Routes.address,
      continueLabel: widget.editing ? 'Save budget' : 'Save and continue',
      busy: _busy,
      onContinue: h == null ? null : _save,
      child: household.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Column(children: [
          Text(setupError(e)),
          TextButton(
              onPressed: () => ref.invalidate(householdProvider),
              child: const Text('Retry')),
        ]),
        data: (_) => Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _budget,
                  enabled: !_busy,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Weekly grocery budget',
                      prefixText: '₹ ',
                      suffixText: '/ week'),
                  validator: (v) {
                    final value = double.tryParse(v?.trim() ?? '');
                    return value == null ||
                            !value.isFinite ||
                            value <= 0 ||
                            value > 1000000
                        ? 'Enter a budget between ₹1 and ₹10,00,000'
                        : null;
                  },
                ),
                const SizedBox(height: Gap.md),
                Wrap(
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    children: [1000, 1500, 2000, 3000]
                        .map((v) => ActionChip(
                            label: Text(money(v)),
                            onPressed: _busy
                                ? null
                                : () => setState(() => _budget.text = '$v')))
                        .toList()),
                const SizedBox(height: Gap.lg),
                const NsCard(
                    child: Text(
                        'Your budget guides the weekly plan. Review the items and checkout total before placing an order.')),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: Gap.md),
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.danger))),
              ],
            )),
      ),
    );
  }
}

class KitchenSetupScreen extends ConsumerStatefulWidget {
  const KitchenSetupScreen({super.key});
  @override
  ConsumerState<KitchenSetupScreen> createState() => _KitchenSetupScreenState();
}

class _KitchenSetupScreenState extends ConsumerState<KitchenSetupScreen> {
  bool _busy = false;
  String? _error;
  Future<void> _finish() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).completeOnboarding();
      ref.invalidate(profileProvider);
      ref.invalidate(householdProvider);
      if (mounted) context.go(Routes.home);
    } catch (error) {
      if (mounted) setState(() => _error = setupError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);
    return SetupScaffold(
      step: 4,
      title: 'Your kitchen, at your pace',
      subtitle:
          'Pantry setup is optional. Finish now and add what you have from Pantry whenever you are ready.',
      backRoute: Routes.dietary,
      continueLabel: 'Finish setup',
      onContinue: _finish,
      busy: _busy,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const NsCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.kitchen_outlined, color: AppColors.primary, size: 32),
          SizedBox(height: Gap.md),
          Text('Avoid buying what you already have',
              style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: Gap.sm),
          Text(
              'Add the actual quantities of rice, dal, oil and other staples to Pantry. Your weekly plan can then take these into account.'),
        ])),
        const SizedBox(height: Gap.lg),
        pantry.maybeWhen(
          data: (items) => items.isEmpty
              ? const Text(
                  'No pantry items added yet. You can still finish setup.')
              : Text(
                  '${items.length} pantry item${items.length == 1 ? '' : 's'} already saved. Your stock will be kept.'),
          orElse: () => const Text('Your existing pantry stays unchanged.'),
        ),
        const SizedBox(height: Gap.lg),
        const Text(
            'Next: browse this week’s groceries or create a plan for your household.',
            style: TextStyle(color: AppColors.textSecondary)),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: Gap.md),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.danger))),
      ]),
    );
  }
}
