import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_intl_phone_field/countries.dart';
import 'package:flutter_intl_phone_field/helpers.dart';

class PickerDialogStyle {
  final Color? backgroundColor;

  final TextStyle? countryCodeStyle;

  final TextStyle? countryNameStyle;

  final Widget? listTileDivider;

  final EdgeInsets? listTilePadding;

  final EdgeInsets? dialogPadding;

  final EdgeInsets? padding;

  final Color? searchFieldCursorColor;

  final InputDecoration? searchFieldInputDecoration;

  final EdgeInsets? searchFieldPadding;

  final double? width;

  PickerDialogStyle({
    this.backgroundColor,
    this.countryCodeStyle,
    this.countryNameStyle,
    this.listTileDivider,
    this.listTilePadding,
    this.dialogPadding,
    this.padding,
    this.searchFieldCursorColor,
    this.searchFieldInputDecoration,
    this.searchFieldPadding,
    this.width,
  });
}

class CountryPickerDialog extends StatefulWidget {
  final List<Country> countryList;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final String searchText;
  final List<Country> filteredCountries;
  final PickerDialogStyle? style;
  final String languageCode;

  final EdgeInsets? dialogPadding;

  final List<String>? allowedCountryCodes;
  final String? deviceCountryCode;

  const CountryPickerDialog({
    Key? key,
    required this.searchText,
    required this.languageCode,
    required this.countryList,
    required this.onCountryChanged,
    required this.selectedCountry,
    required this.filteredCountries,
    this.style,
    this.dialogPadding,
    this.allowedCountryCodes,
    this.deviceCountryCode,
  }) : super(key: key);

  @override
  State<CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<CountryPickerDialog> {
  late List<Country> _filteredCountries;
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.selectedCountry;

    _filteredCountries = widget.filteredCountries.toList()
      ..sort(_countryComparator);

    final availableCountries = _buildAvailableCountries();

    _filteredCountries = availableCountries.toList()
      ..sort(_countryComparator);
  }

  List<Country> _buildAvailableCountries() {
    // 1️⃣ 没有限制 → 全部
    if (widget.allowedCountryCodes == null ||
        widget.allowedCountryCodes!.isEmpty) {
      return widget.countryList;
    }

    // 2️⃣ 允许的国家 code 集合
    final Set<String> codes = widget.allowedCountryCodes!
        .map((e) => e.toUpperCase())
        .toSet();

    // 3️⃣ 加入手机国家
    if (widget.deviceCountryCode != null &&
        widget.deviceCountryCode!.isNotEmpty) {
      codes.add(widget.deviceCountryCode!.toUpperCase());
    }

    // 4️⃣ 过滤国家列表
    return widget.countryList
        .where((c) => codes.contains(c.code.toUpperCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final width = widget.style?.width ?? mediaWidth;
    const defaultHorizontalPadding = 40.0;
    const defaultVerticalPadding = 24.0;
    return Dialog(
      insetPadding: widget.style?.dialogPadding ??
          widget.dialogPadding ??
          EdgeInsets.symmetric(
              vertical: defaultVerticalPadding,
              horizontal: mediaWidth > (width + defaultHorizontalPadding * 2)
                  ? (mediaWidth - width) / 2
                  : defaultHorizontalPadding),
      backgroundColor: widget.style?.backgroundColor,
      child: Container(
        padding: widget.style?.padding ?? const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Padding(
              padding:
                  widget.style?.searchFieldPadding ?? const EdgeInsets.all(0),
              child: TextField(
                  cursorColor: widget.style?.searchFieldCursorColor,
                  decoration: widget.style?.searchFieldInputDecoration ??
                      InputDecoration(
                        suffixIcon: const Icon(Icons.search),
                        labelText: widget.searchText,
                      ),
                onChanged: (value) {
                  final source = _buildAvailableCountries();

                  _filteredCountries = source.stringSearch(value)
                    ..sort(_countryComparator);

                  if (mounted) setState(() {});
                })),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCountries.length,
                itemBuilder: (ctx, index) => Column(
                  children: <Widget>[
                    ListTile(
                      leading: kIsWeb
                          ? Image.asset(
                              'assets/flags/${_filteredCountries[index].code.toLowerCase()}.png',
                              package: 'flutter_intl_phone_field',
                              width: 32,
                            )
                          : Text(
                              _filteredCountries[index].flag,
                              style: const TextStyle(fontSize: 18),
                            ),
                      contentPadding: widget.style?.listTilePadding,
                      title: Text(
                        _filteredCountries[index]
                            .localizedName(widget.languageCode),
                        style: widget.style?.countryNameStyle ??
                            const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: Text(
                        '+${_filteredCountries[index].dialCode}',
                        style: widget.style?.countryCodeStyle ??
                            const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        _selectedCountry = _filteredCountries[index];
                        widget.onCountryChanged(_selectedCountry);
                        Navigator.of(context).pop();
                      },
                    ),
                    widget.style?.listTileDivider ??
                        const Divider(thickness: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Put this inside _CountryPickerDialogState
  final Map<String, int> _pinRank = <String, int>{
    // Simplified Chinese regions
    'CN': 0, // China
    'SG': 1, // Singapore
    'MY': 2, // Malaysia

    // Traditional Chinese regions
    'TW': 3, // Taiwan
    'HK': 4, // Hong Kong
    'MO': 5, // Macau

    // English
    'US': 6, // United States
    'CA': 7, // Canada
    'GB': 8, // United Kingdom
    'AU': 9, // Australia

    // French
    'FR': 10, // France

    // Spanish (Spain + LatAm)
    'ES': 11, // Spain
    'MX': 12, // Mexico
    'AR': 13, // Argentina
    'CO': 14, // Colombia
    'CL': 15, // Chile
    'PE': 16, // Peru

    // Hindi
    'IN': 17, // India

    // Korean (South Korea)
    'KR': 18, // Korea, Republic of

    // Japanese
    'JP': 19, // Japan
  };

  int _countryComparator(Country a, Country b) {
    final int ra = _pinRank[a.code] ?? 1 << 20;
    final int rb = _pinRank[b.code] ?? 1 << 20;

    if (ra != rb) return ra.compareTo(rb);

    // same pin-rank (both pinned or both not), fall back to localized name
    return a
        .localizedName(widget.languageCode)
        .compareTo(b.localizedName(widget.languageCode));
  }
}
