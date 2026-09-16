import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../onboarding/presentation/onboarding_screens.dart';
import '../domain/address_models.dart';
import 'address_providers.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen(
      {super.key, this.editing = false, this.returnRoute = Routes.profile});
  final String returnRoute;
  final bool editing;
  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _form = GlobalKey<FormState>();
  final _line1 = TextEditingController();
  final _apartment = TextEditingController();
  final _pincode = TextEditingController();
  Address? _address;
  bool _busy = false, _checking = false;
  bool? _serviceable;
  String? _error;
  int _checkRevision = 0;

  bool get _hasDraft =>
      _address != null ||
      _line1.text.trim().isNotEmpty ||
      _apartment.text.trim().isNotEmpty ||
      _pincode.text.trim().isNotEmpty;

  @override
  void dispose() {
    _line1.dispose();
    _apartment.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _check(String value) async {
    final revision = ++_checkRevision;
    setState(() {
      _serviceable = null;
      _error = null;
      _checking = value.length == 6;
    });
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return;
    try {
      final result =
          await ref.read(addressRepositoryProvider).checkServiceability(value);
      if (mounted && revision == _checkRevision) {
        setState(() => _serviceable = result);
      }
    } catch (error) {
      if (mounted && revision == _checkRevision) {
        setState(() => _error = setupError(error));
      }
    } finally {
      if (mounted && revision == _checkRevision) {
        setState(() => _checking = false);
      }
    }
  }

  void _clear() {
    ++_checkRevision;
    _line1.clear();
    _apartment.clear();
    _pincode.clear();
    _address = null;
    _serviceable = null;
    _checking = false;
    _form.currentState?.reset();
  }

  void _edit(Address a) {
    setState(() {
      ++_checkRevision;
      _address = a;
      _line1.text = a.line1;
      _apartment.text = a.apartment ?? '';
      _pincode.text = a.pincode;
      _serviceable = a.serviceable;
      _error = null;
      _checking = false;
    });
    Scrollable.ensureVisible(_form.currentContext!,
        duration: const Duration(milliseconds: 200));
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(addressRepositoryProvider);
      final available = await repo.checkServiceability(_pincode.text.trim());
      if (!mounted) return;
      if (!available) {
        setState(() {
          _serviceable = false;
          _error =
              'We do not deliver to this pincode yet. Choose a serviceable address.';
        });
        return;
      }
      final saved = _address == null
          ? await repo.create(
              line1: _line1.text.trim(),
              apartment: _apartment.text.trim(),
              pincode: _pincode.text.trim(),
              isDefault: true)
          : await repo.update(_address!,
              line1: _line1.text.trim(),
              apartment: _apartment.text.trim(),
              pincode: _pincode.text.trim(),
              isDefault: true);
      ref.invalidate(addressesProvider);
      if (!mounted) return;
      setState(_clear);
      if (!saved.serviceable) {
        setState(() => _error =
            'This address is no longer serviceable. Please choose another address.');
      } else if (!widget.editing) {
        context.go(Routes.dietary);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Address saved')));
      }
    } catch (error) {
      ref.invalidate(addressesProvider);
      if (mounted) setState(() => _error = setupError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _select(Address a) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(addressRepositoryProvider).update(a,
          line1: a.line1,
          apartment: a.apartment ?? '',
          pincode: a.pincode,
          isDefault: true);
    } catch (error) {
      if (mounted) setState(() => _error = setupError(error));
    } finally {
      ref.invalidate(addressesProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(Address a) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Remove address?'),
              content: Text(a.oneLine),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Keep address')),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Remove')),
              ],
            ));
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(addressRepositoryProvider).remove(a.id);
      if (mounted && _address?.id == a.id) setState(_clear);
    } catch (error) {
      if (mounted) setState(() => _error = setupError(error));
    } finally {
      ref.invalidate(addressesProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressesProvider);
    final canContinue =
        addresses.asData?.value.any((a) => a.isDefault && a.serviceable) ??
            false;
    return SetupScaffold(
      step: 2,
      editing: widget.editing,
      title: 'Delivery address',
      subtitle:
          'Choose where your weekly groceries should arrive. We check delivery availability before saving.',
      backRoute: widget.editing ? widget.returnRoute : Routes.familyProfile,
      busy: _busy,
      continueLabel: widget.editing ? 'Done' : 'Use saved address',
      onContinue: canContinue && !_hasDraft && !_checking
          ? () =>
              context.go(widget.editing ? widget.returnRoute : Routes.dietary)
          : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        addresses.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Column(children: [
            Text(setupError(e)),
            TextButton(
                onPressed: () => ref.invalidate(addressesProvider),
                child: const Text('Retry addresses')),
          ]),
          data: (list) => Column(children: [
            for (final a in list)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: NsCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          a.label?.isNotEmpty == true
                              ? a.label!
                              : 'Saved address',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: Gap.sm),
                      Text(a.oneLine),
                      const SizedBox(height: Gap.sm),
                      if (a.isDefault)
                        const Text('Selected for delivery',
                            style: TextStyle(color: AppColors.primary)),
                      if (!a.serviceable)
                        const Text('Not serviceable yet',
                            style: TextStyle(color: AppColors.danger)),
                      Wrap(spacing: Gap.sm, children: [
                        if (!a.isDefault && a.serviceable)
                          TextButton(
                              onPressed:
                                  _busy || _hasDraft ? null : () => _select(a),
                              child: const Text('Use this address')),
                        TextButton(
                            onPressed: _busy ? null : () => _edit(a),
                            child: const Text('Edit')),
                        TextButton(
                            onPressed: _busy ? null : () => _remove(a),
                            child: const Text('Remove')),
                      ]),
                    ])),
              ),
          ]),
        ),
        const SizedBox(height: Gap.md),
        Text(_address == null ? 'Add an address' : 'Edit address',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: Gap.md),
        Form(
            key: _form,
            onChanged: () => setState(() {}),
            child: Column(children: [
              TextFormField(
                  controller: _line1,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Flat / house and street'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter your flat / house and street'
                      : null),
              const SizedBox(height: Gap.md),
              TextFormField(
                  controller: _apartment,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Apartment / community (optional)')),
              const SizedBox(height: Gap.md),
              TextFormField(
                  controller: _pincode,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    counterText: '',
                    helperText: _checking
                        ? 'Checking delivery availability…'
                        : _serviceable == null
                            ? null
                            : _serviceable!
                                ? 'We deliver here'
                                : 'Not serviceable yet',
                  ),
                  validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '')
                      ? null
                      : 'Enter a 6-digit pincode',
                  onChanged: _check),
              const SizedBox(height: Gap.lg),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy
                    ? 'Saving…'
                    : widget.editing
                        ? 'Save address'
                        : 'Save address and continue'),
              ),
              if (_hasDraft)
                TextButton(
                  onPressed: _busy ? null : () => setState(_clear),
                  child: const Text('Discard address changes'),
                ),
            ])),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: Gap.md),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.danger))),
        const SizedBox(height: Gap.md),
        const Text('Save new or edited details before continuing.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      ]),
    );
  }
}
