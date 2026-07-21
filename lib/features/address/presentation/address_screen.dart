import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/address_models.dart';
import 'address_providers.dart';

/// Delivery addresses (Vol2 §7): list + add with live pincode serviceability
/// against the Hyderabad pilot.
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _line1 = TextEditingController();
  final _apartment = TextEditingController();
  final _pincode = TextEditingController();
  bool? _serviceable; // null = unknown
  bool _saving = false;

  @override
  void dispose() {
    _line1.dispose();
    _apartment.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _onPincode(String v) async {
    if (v.length != 6) {
      setState(() => _serviceable = null);
      return;
    }
    try {
      final ok = await ref.read(addressRepositoryProvider).checkServiceability(v);
      if (mounted) setState(() => _serviceable = ok);
    } on ApiFailure catch (_) {/* ignore */}
  }

  Future<void> _save() async {
    if (_line1.text.trim().isEmpty || _pincode.text.trim().length != 6) return;
    setState(() => _saving = true);
    try {
      await ref.read(addressRepositoryProvider).create(
            line1: _line1.text.trim(),
            apartment: _apartment.text.trim().isEmpty ? null : _apartment.text.trim(),
            pincode: _pincode.text.trim(),
            isDefault: true,
          );
      ref.invalidate(addressesProvider);
      _line1.clear();
      _apartment.clear();
      _pincode.clear();
      setState(() => _serviceable = null);
    } on ApiFailure catch (f) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.userMessage)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery address')),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 700,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            const SizedBox(height: Gap.lg),
            addressesAsync.maybeWhen(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : Column(children: list.map(_addressTile).toList()),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: Gap.md),
            const Text('Add an address', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: Gap.sm),
            TextField(controller: _line1,
                decoration: const InputDecoration(labelText: 'Flat / house & street')),
            const SizedBox(height: Gap.sm),
            TextField(controller: _apartment,
                decoration: const InputDecoration(labelText: 'Apartment / community (optional)')),
            const SizedBox(height: Gap.sm),
            TextField(
              controller: _pincode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Pincode',
                counterText: '',
                suffixIcon: _serviceable == null
                    ? null
                    : Icon(_serviceable! ? Icons.check_circle : Icons.cancel,
                        color: _serviceable! ? AppColors.success : AppColors.carrot),
                helperText: _serviceable == null
                    ? null
                    : (_serviceable! ? 'We deliver here 🎉' : "We don't deliver to this area yet"),
                helperStyle: TextStyle(
                    color: _serviceable == true ? AppColors.success : AppColors.carrot),
              ),
              onChanged: _onPincode,
            ),
            const SizedBox(height: Gap.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save address'),
              ),
            ),
            const SizedBox(height: Gap.sm),
            Center(
              child: TextButton(
                onPressed: () => context.go(Routes.dietary),
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: Gap.section),
          ]),
        ),
      ),
    );
  }

  Widget _addressTile(Address a) {
    return NsCard(
      child: Row(children: <Widget>[
        Icon(a.serviceable ? Icons.location_on : Icons.location_off,
            color: a.serviceable ? AppColors.forest : AppColors.carrot),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: <Widget>[
              Text(a.label ?? 'Address', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (a.isDefault) ...<Widget>[
                const SizedBox(width: Gap.sm),
                const StatusChip(label: 'Default', color: AppColors.primary),
              ],
            ]),
            Text(a.oneLine,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (!a.serviceable)
              const Text('Not serviceable yet',
                  style: TextStyle(fontSize: 12, color: AppColors.carrot)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
          onPressed: () async {
            await ref.read(addressRepositoryProvider).remove(a.id);
            ref.invalidate(addressesProvider);
          },
        ),
      ]),
    );
  }
}
