import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final TextEditingController _carTypeController = TextEditingController();
  final TextEditingController _carPlateController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  String? _userType;
  String? _docId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _carTypeController.dispose();
    _carPlateController.dispose();
    _carColorController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        setState(() {
          userData = query.docs.first.data();
          _docId = query.docs.first.id;
          _userType = userData!['userType'];
          if (_userType == 'driver' && userData!['car'] != null) {
            _carTypeController.text = userData!['car']['type'] ?? '';
            _carPlateController.text = userData!['car']['plate'] ?? '';
            _carColorController.text = userData!['car']['color'] ?? '';
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserType() async {
    if (_docId == null) return;
    final updateData = <String, dynamic>{
      'userType': _userType,
    };
    if (_userType == 'driver') {
      updateData['car'] = {
        'type': _carTypeController.text.trim(),
        'plate': _carPlateController.text.trim(),
        'color': _carColorController.text.trim(),
      };
    } else {
      updateData['car'] = FieldValue.delete();
    }
    await FirebaseFirestore.instance.collection('users').doc(_docId).update(updateData);
    setState(() {
      userData!['userType'] = _userType;
      if (_userType == 'driver') {
        userData!['car'] = {
          'type': _carTypeController.text.trim(),
          'plate': _carPlateController.text.trim(),
          'color': _carColorController.text.trim(),
        };
      } else {
        userData!.remove('car');
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', _userType!);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.accountTypeUpdated)));
    }
    if (_userType == 'driver') {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/driver');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? Center(child: Text(l10n.noUserDataFound))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(l10n.name),
                      subtitle: Text(userData!['name'] ?? ''),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(l10n.email),
                      subtitle: Text(userData!['email'] ?? ''),
                    ),
                    ListTile(
                      leading: const Icon(Icons.account_box),
                      title: Text(l10n.accountType),
                      subtitle: Text(_userType == 'customer' ? l10n.customer : l10n.driver),
                      trailing: DropdownButton<String>(
                        value: _userType,
                        items: [
                          DropdownMenuItem(value: 'customer', child: Text(l10n.customer)),
                          DropdownMenuItem(value: 'driver', child: Text(l10n.driver)),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _userType = val;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l10n.language),
                      subtitle: Text(languageService.getLanguageName(languageService.currentLocale.languageCode)),
                      trailing: DropdownButton<String>(
                        value: languageService.currentLocale.languageCode,
                        items: [
                          DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                          DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
                        ],
                        onChanged: (String? languageCode) async {
                          if (languageCode != null) {
                            await languageService.changeLanguage(languageCode);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.languageChanged)),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    if (_userType == 'driver') ...[
                      const Divider(),
                      TextField(
                        controller: _carTypeController,
                        decoration: InputDecoration(
                          labelText: l10n.carType,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.directions_car),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _carPlateController,
                        decoration: InputDecoration(
                          labelText: l10n.carPlate,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.confirmation_number),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _carColorController,
                        decoration: InputDecoration(
                          labelText: l10n.carColor,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.color_lens),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _updateUserType,
                      child: Text(l10n.saveChanges),
                    ),
                  ],
                ),
    );
  }
}
