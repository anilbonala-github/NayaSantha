import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_failure.dart';
import '../auth/presentation/auth_controller.dart';
import '../basket/presentation/basket_providers.dart';
import '../catalogue/presentation/catalogue_providers.dart';
import '../catalogue/presentation/product_widgets.dart';
import '../catalogue/domain/catalogue_models.dart';

String adminError(Object e) => e is ApiFailure
    ? e.userMessage
    : e is DioException
        ? ApiFailure.fromDio(e).userMessage
        : 'Could not complete the request. Please try again.';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _mobile = TextEditingController(), _otp = TextEditingController();
  bool _sent = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _mobile.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_mobile.text)) {
      setState(() => _error = 'Enter a valid 10-digit mobile number.');
      return;
    }
    if (_sent && !RegExp(r'^\d{6}$').hasMatch(_otp.text)) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(apiClientProvider);
      if (!_sent) {
        final verified = await ref.read(authRepositoryProvider)
            .signInWithSms(_mobile.text, staff: true);
        if (verified != null) {
          ref.invalidate(basketProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(productsProvider);
          if (mounted) context.go('/admin');
          return;
        }
        await client.post('/auth/admin/otp/request',
            auth: false, body: {'mobile': _mobile.text});
        if (mounted) setState(() => _sent = true);
      } else {
        final data = await client.post('/auth/admin/otp/verify',
            auth: false, body: {'mobile': _mobile.text, 'code': _otp.text});
        await ref
            .read(tokenStoreProvider)
            .save(access: data['accessToken'], refresh: data['refreshToken']);
        ref.invalidate(basketProvider);
        ref.invalidate(categoriesProvider);
        ref.invalidate(productsProvider);
        if (mounted) context.go('/admin');
      }
    } catch (e) {
      if (mounted) setState(() => _error = adminError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('NayaSantha staff'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/categories'))),
      body: SingleChildScrollView(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(Icons.storefront_outlined, size: 48),
                            const SizedBox(height: 24),
                            const Text('Manage your store',
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            const Text(
                                'Sign in with the mobile number authorised by your owner.'),
                            const SizedBox(height: 24),
                            TextField(
                                controller: _mobile,
                                enabled: !_sent && !_busy,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10)
                                ],
                                decoration: const InputDecoration(
                                    labelText: 'Mobile number',
                                    prefixText: '+91 ')),
                            if (_sent) ...[
                              const SizedBox(height: 16),
                              TextField(
                                  controller: _otp,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6)
                                  ],
                                  decoration: const InputDecoration(
                                      labelText: 'Verification code'))
                            ],
                            if (_error != null)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(_error!,
                                      style:
                                          const TextStyle(color: Colors.red))),
                            const SizedBox(height: 20),
                            FilledButton(
                                onPressed: _busy ? null : _submit,
                                child: Text(_busy
                                    ? 'Please wait…'
                                    : _sent
                                        ? 'Verify and sign in'
                                        : 'Send verification code')),
                            if (_sent)
                              TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() {
                                            _sent = false;
                                            _otp.clear();
                                            _error = null;
                                          }),
                                  child: const Text(
                                      'Change number or resend code')),
                          ]))))));
}

class CatalogueAdminScreen extends ConsumerStatefulWidget {
  const CatalogueAdminScreen({super.key});
  @override
  ConsumerState<CatalogueAdminScreen> createState() =>
      _CatalogueAdminScreenState();
}

class _CatalogueAdminScreenState extends ConsumerState<CatalogueAdminScreen> {
  bool _busy = true;
  String? _error, _role;
  int _page = 0, _pages = 1;
  List<Map<String, dynamic>> _products = [], _categories = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final me = await api.get('/admin/me');
      final cats = await api.get('/admin/categories') as List;
      final page = await api.get('/admin/products', query: {'page': _page});
      if (mounted)
        setState(() {
          _role = me['role'];
          _categories = cats.cast<Map<String, dynamic>>();
          _products = (page['items'] as List).cast<Map<String, dynamic>>();
          _pages = page['totalPages'];
        });
    } catch (e) {
      if (mounted) setState(() => _error = adminError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _invalidateShop() {
    ref.invalidate(categoriesProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(productProvider);
  }

  Future<void> _product([Map<String, dynamic>? row]) async {
    final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ProductEditor(categories: _categories, row: row));
    if (saved == true) {
      _invalidateShop();
      await _load();
    }
  }

  Future<void> _category() async {
    final name = TextEditingController(), slug = TextEditingController();
    String? error;
    bool busy = false;
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: const Text('New category'),
                    content: SizedBox(
                        width: 400,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(
                              controller: name,
                              decoration: const InputDecoration(
                                  labelText: 'Category name')),
                          const SizedBox(height: 16),
                          TextField(
                              controller: slug,
                              decoration: const InputDecoration(
                                  labelText: 'URL name, e.g. vegetables')),
                          if (error != null)
                            Text(error!,
                                style: const TextStyle(color: Colors.red)),
                        ])),
                    actions: [
                      TextButton(
                          onPressed:
                              busy ? null : () => Navigator.pop(dialogContext),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  update(() => busy = true);
                                  try {
                                    await ref
                                        .read(apiClientProvider)
                                        .post('/admin/categories', body: {
                                      'name': name.text.trim(),
                                      'slug': slug.text.trim(),
                                      'sortOrder': _categories.length
                                    });
                                    if (dialogContext.mounted)
                                      Navigator.pop(dialogContext);
                                    _invalidateShop();
                                    await _load();
                                  } catch (e) {
                                    update(() => error = adminError(e));
                                  } finally {
                                    if (context.mounted)
                                      update(() => busy = false);
                                  }
                                },
                          child: const Text('Save category')),
                    ])));
    name.dispose();
    slug.dispose();
  }

  Future<void> _staff() async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const StaffDialog());
  }

  Future<void> _weeklyPrices() async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const WeeklyPricesDialog());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Store catalogue'), actions: [
        TextButton(
            onPressed: () => context.go('/categories'),
            child: const Text('Open shop')),
        IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.invalidate(basketProvider);
              if (context.mounted) context.go('/admin/login');
            },
            icon: const Icon(Icons.logout)),
      ]),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _load, child: const Text('Retry')),
                        TextButton(
                            onPressed: () => context.go('/admin/login'),
                            child: const Text('Staff sign in'))
                      ])))
              : SingleChildScrollView(
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text('Catalogue management',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'Manage photos, pack sizes and availability. Only published products appear in the shop.'),
                                    const SizedBox(height: 20),
                                    Wrap(spacing: 12, runSpacing: 8, children: [
                                      OutlinedButton(
                                          onPressed: _weeklyPrices,
                                          child: const Text('Weekly prices')),
                                      FilledButton.icon(
                                          onPressed: _categories.isEmpty
                                              ? null
                                              : () => _product(),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add product')),
                                      OutlinedButton(
                                          onPressed: _category,
                                          child: const Text('Add category')),
                                      if (_role == 'OWNER')
                                        OutlinedButton(
                                            onPressed: _staff,
                                            child: const Text('Manage staff')),
                                      IconButton(
                                          tooltip: 'Refresh catalogue',
                                          onPressed: _load,
                                          icon: const Icon(Icons.refresh))
                                    ]),
                                    const SizedBox(height: 20),
                                    if (_products.isEmpty)
                                      const Text(
                                          'Create a category, then add your first product.'),
                                    ..._products.map((row) {
                                      final p = row['product']
                                          as Map<String, dynamic>;
                                      return Card(
                                          child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Wrap(
                                                  alignment: WrapAlignment
                                                      .spaceBetween,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  spacing: 20,
                                                  runSpacing: 12,
                                                  children: [
                                                    SizedBox(
                                                        width: 280,
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(p['name'],
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          17)),
                                                              Text(
                                                                  '${p['sku']} · ${p['unit']}'),
                                                              Text(
                                                                  '${p['publicationStatus']} · ${p['available'] == true ? 'Available' : 'Out of stock'}'),
                                                              Text(row['sellingPrice'] ==
                                                                      null
                                                                  ? 'No current price'
                                                                  : '₹${row['sellingPrice']}')
                                                            ])),
                                                    Wrap(spacing: 8, children: [
                                                      OutlinedButton(
                                                          onPressed: () =>
                                                              _product(row),
                                                          child: const Text(
                                                              'Edit / preview')),
                                                    ]),
                                                  ])));
                                    }),
                                    if (_pages > 1)
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                                onPressed: _page > 0
                                                    ? () {
                                                        _page--;
                                                        _load();
                                                      }
                                                    : null,
                                                icon: const Icon(
                                                    Icons.chevron_left)),
                                            Text(
                                                'Page ${_page + 1} of $_pages'),
                                            IconButton(
                                                onPressed: _page + 1 < _pages
                                                    ? () {
                                                        _page++;
                                                        _load();
                                                      }
                                                    : null,
                                                icon: const Icon(
                                                    Icons.chevron_right))
                                          ]),
                                  ]))))));
}

class ProductEditor extends ConsumerStatefulWidget {
  const ProductEditor({super.key, required this.categories, this.row});
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? row;
  @override
  ConsumerState<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditor> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  String? _category, _image, _error;
  String _status = 'DRAFT';
  bool _available = true, _busy = false;
  Map<String, dynamic>? get p => widget.row?['product'];
  bool get _priced => widget.row?['sellingPrice'] != null;
  @override
  void initState() {
    super.initState();
    for (final k in [
      'sku',
      'name',
      'unit',
      'description',
      'origin',
      'initialPrice',
      'mrp'
    ]) {
      _fields[k] = TextEditingController(text: p?[k]?.toString() ?? '');
    }
    _category = p?['categoryId'] ?? widget.categories.firstOrNull?['id'];
    _image = p?['imageUrl'];
    _status = p?['publicationStatus'] ?? 'DRAFT';
    _available = p?['available'] ?? true;
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _upload() async {
    try {
      final file = await openFile(acceptedTypeGroups: [
        const XTypeGroup(
            label: 'Product photos',
            extensions: ['jpg', 'jpeg', 'png'],
            uniformTypeIdentifiers: ['public.jpeg', 'public.png'])
      ]);
      if (file == null || !mounted) return;
      if (await file.length() > 1000000)
        throw const ApiFailure(
            errorCode: 'VALIDATION_ERROR',
            userMessage: 'Choose a JPEG or PNG smaller than 1 MB.');
      setState(() => _busy = true);
      final result = await ref.read(apiClientProvider).post('/admin/images',
          body: {'base64': base64Encode(await file.readAsBytes())});
      if (mounted) setState(() => _image = result['url']);
    } catch (e) {
      if (mounted) setState(() => _error = adminError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        for (final k in ['sku', 'name', 'unit', 'description', 'origin'])
          k: _fields[k]!.text.trim(),
        'categoryId': _category,
        'imageUrl': _image,
        'publicationStatus': _status,
        'available': _available,
        if (p != null) 'version': p!['version'],
        if (!_priced && _fields['initialPrice']!.text.isNotEmpty)
          'initialPrice': double.parse(_fields['initialPrice']!.text),
        if (!_priced && _fields['mrp']!.text.isNotEmpty)
          'mrp': double.parse(_fields['mrp']!.text)
      };
      final api = ref.read(apiClientProvider);
      if (p == null) {
        await api.post('/admin/products', body: body);
      } else {
        await api.put('/admin/products/${p!['id']}', body: body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = adminError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String k, String label,
          {bool required = false, int lines = 1, bool money = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextFormField(
              controller: _fields[k],
              enabled: !_busy,
              maxLines: lines,
              decoration: InputDecoration(labelText: label),
              keyboardType: money
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              validator: (v) {
                if (required && (v == null || v.trim().isEmpty))
                  return 'Required';
                if (money &&
                    v != null &&
                    v.isNotEmpty &&
                    (double.tryParse(v) == null || double.parse(v) <= 0))
                  return 'Enter a positive amount';
                return null;
              }));
  Product get _preview => Product(
      id: p?['id'] ?? 'preview',
      name: _fields['name']!.text,
      categoryId: _category ?? '',
      unit: _fields['unit']!.text,
      imageUrl: _image,
      description: _fields['description']!.text,
      origin: _fields['origin']!.text,
      sellingPrice: _priced
          ? (widget.row!['sellingPrice'] as num).toDouble()
          : double.tryParse(_fields['initialPrice']!.text));
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(p == null ? 'Add product' : 'Edit product'),
          content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                  child: Form(
                      key: _form,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _field('name', 'Product name', required: true),
                            _field('sku', 'Unique SKU (one per pack size)',
                                required: true),
                            DropdownButtonFormField<String>(
                                value: _category,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Category'),
                                items: widget.categories
                                    .map((c) => DropdownMenuItem<String>(
                                        value: c['id'], child: Text(c['name'])))
                                    .toList(),
                                onChanged: _busy
                                    ? null
                                    : (v) => setState(() => _category = v)),
                            const SizedBox(height: 14),
                            _field('unit', 'Pack size, e.g. 500 g',
                                required: true),
                            _field(
                                'description', 'Description and storage advice',
                                lines: 4),
                            _field('origin', 'Origin (optional)'),
                            ProductPhoto(product: _preview, height: 150),
                            TextButton.icon(
                                onPressed: _busy ? null : _upload,
                                icon: const Icon(Icons.upload),
                                label: const Text(
                                    'Upload JPEG / PNG (up to 1 MB)')),
                            if (!_priced) ...[
                              _field('initialPrice', 'Initial selling price ₹',
                                  money: true,
                                  required: _status == 'PUBLISHED'),
                              _field('mrp', 'MRP ₹ (optional)', money: true)
                            ] else
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                      'Current selling price is fixed. Schedule next week’s price from the catalogue.')),
                            DropdownButtonFormField<String>(
                                value: _status,
                                decoration: const InputDecoration(
                                    labelText: 'Publication status'),
                                items: ['DRAFT', 'PUBLISHED', 'ARCHIVED']
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: _busy
                                    ? null
                                    : (s) => setState(() => _status = s!)),
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Available to order'),
                                value: _available,
                                onChanged: _busy
                                    ? null
                                    : (v) => setState(() => _available = v)),
                            if (_error != null)
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                          ])))),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
                onPressed: _busy
                    ? null
                    : () => showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                                title: Text(_preview.name),
                                content: SingleChildScrollView(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      ProductPhoto(product: _preview),
                                      Text(_preview.unit),
                                      Text(_preview.sellingPrice == null
                                          ? 'Price unavailable'
                                          : '₹${_preview.sellingPrice!.toStringAsFixed(2)}'),
                                      Text(_preview.description ?? '')
                                    ])),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text('Close preview'))
                                ])),
                child: const Text('Preview')),
            FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Saving…' : 'Save product'))
          ]);
}

class StaffDialog extends ConsumerStatefulWidget {
  const StaffDialog({super.key});
  @override
  ConsumerState<StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends ConsumerState<StaffDialog> {
  final _mobile = TextEditingController();
  String _role = 'CATALOGUE_MANAGER';
  String? _error;
  bool _busy = false;
  List<dynamic> _staff = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows =
          await ref.read(apiClientProvider).get('/admin/staff') as List;
      if (mounted) setState(() => _staff = rows);
    } catch (e) {
      if (mounted) setState(() => _error = adminError(e));
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).put('/admin/staff',
          body: {'mobile': _mobile.text.trim(), 'role': _role});
      _mobile.clear();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = adminError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Staff access'),
          content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'Assign a role to an authorised mobile number. Customer removes staff access. Staff must sign in again after a role change.'),
                const SizedBox(height: 16),
                ..._staff.map((s) => ListTile(
                    title: Text(s['mobile']), subtitle: Text(s['role']))),
                TextField(
                    controller: _mobile,
                    decoration:
                        const InputDecoration(labelText: 'Staff mobile number'),
                    keyboardType: TextInputType.phone),
                DropdownButtonFormField<String>(
                    value: _role,
                    items: ['CATALOGUE_MANAGER', 'CUSTOMER']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged:
                        _busy ? null : (v) => setState(() => _role = v!)),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
              ]))),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Close')),
            FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Save access'))
          ]);
}

class WeeklyPricesDialog extends ConsumerStatefulWidget {
  const WeeklyPricesDialog({super.key});
  @override
  ConsumerState<WeeklyPricesDialog> createState() => _WeeklyPricesDialogState();
}

class _WeeklyPricesDialogState extends ConsumerState<WeeklyPricesDialog> {
  final _date = TextEditingController();
  final _rates = <String, TextEditingController>{},
      _mrps = <String, TextEditingController>{};
  List<Map<String, dynamic>> _rows = [];
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _date.dispose();
    for (final c in [..._rates.values, ..._mrps.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = <Map<String, dynamic>>[];
      int page = 0, total = 1;
      while (page < total) {
        final data = await ref
            .read(apiClientProvider)
            .get('/admin/products', query: {'page': page});
        total = data['totalPages'];
        rows.addAll((data['items'] as List).cast<Map<String, dynamic>>());
        page++;
      }
      if (!mounted) return;
      _rows = rows.where((r) => r['product']['active'] == true).toList();
      for (final r in _rows) {
        final id = r['product']['id'] as String;
        _rates[id] = TextEditingController();
        _mrps[id] = TextEditingController(text: r['mrp']?.toString() ?? '');
      }
    } catch (e) {
      if (mounted) _error = adminError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final entries = <Map<String, dynamic>>[];
      for (final row in _rows) {
        final id = row['product']['id'] as String;
        final raw = _rates[id]!.text.trim();
        if (raw.isEmpty) continue;
        final rate = double.tryParse(raw),
            mrp = double.tryParse(_mrps[id]!.text.trim());
        if (rate == null ||
            !rate.isFinite ||
            rate <= 0 ||
            (_mrps[id]!.text.trim().isNotEmpty &&
                (mrp == null || !mrp.isFinite || mrp < rate)))
          throw const ApiFailure(
              errorCode: 'VALIDATION_ERROR',
              userMessage:
                  'Enter positive prices and an MRP no lower than the selling price.');
        entries.add({
          'productId': id,
          'sellingPrice': rate,
          if (mrp != null) 'mrp': mrp
        });
      }
      if (entries.isEmpty)
        throw const ApiFailure(
            errorCode: 'VALIDATION_ERROR',
            userMessage: 'Enter at least one new price.');
      await ref.read(apiClientProvider).post('/ops/selling-prices/publish',
          body: {'weekStart': _date.text.trim(), 'prices': entries});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Weekly prices scheduled.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = adminError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Publish weekly prices'),
          content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    const Text(
                        'Publish all price changes for a future Monday together. A week can be published once. Leave a selling price blank to keep the existing rate. Confirmed orders keep their original prices.'),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _date,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                            labelText:
                                'Pricing week: Monday YYYY-MM-DD (IST)')),
                    if (_busy) const LinearProgressIndicator(),
                    for (final row in _rows)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${row['product']['name']} · ${row['product']['unit']} · current ₹${row['sellingPrice'] ?? '—'}'),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                      child: TextField(
                                          controller:
                                              _rates[row['product']['id']],
                                          enabled: !_busy,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                              labelText:
                                                  'New selling price ₹'))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: TextField(
                                          controller:
                                              _mrps[row['product']['id']],
                                          enabled: !_busy,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                              labelText: 'MRP ₹ (optional)')))
                                ]),
                              ])),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                  ]))),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: _busy || _rows.isEmpty ? null : _publish,
                child: const Text('Publish weekly prices'))
          ]);
}
