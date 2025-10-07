import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTrips)),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.car_rental)),
            title: Text('${l10n.trip} #${index + 1}'),
            subtitle: Text('${DateTime.now().subtract(Duration(days: index)).toString().split('.')[0]}'),
            trailing: Text('\$${(index + 1) * 10}'),
            onTap: () {},
          );
        },
      ),
    );
  }
}
