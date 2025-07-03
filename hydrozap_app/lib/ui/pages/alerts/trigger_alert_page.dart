// ui/pages/alerts/trigger_alert_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/alert_provider.dart';

class TriggerAlertPage extends StatefulWidget {
  final String userId;
  final String deviceId;
  const TriggerAlertPage({super.key, required this.userId, required this.deviceId});

  @override
  _TriggerAlertPageState createState() => _TriggerAlertPageState();
}

class _TriggerAlertPageState extends State<TriggerAlertPage> {
  final _formKey = GlobalKey<FormState>();
  String alertMessage = '';
  String alertType = 'sensor';

  Future<void> _triggerAlert() async {
    if (_formKey.currentState!.validate()) {
      final alertProvider =
          Provider.of<AlertProvider>(context, listen: false);

      final success = await alertProvider.triggerAlert({
        "user_id": widget.userId,
        "device_id": widget.deviceId,
        "message": alertMessage,
        "alert_type": alertType,
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alert triggered successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error triggering alert!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trigger Alert")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Alert Message"),
                onSaved: (value) => alertMessage = value!,
                validator: (value) =>
                    value!.isEmpty ? "Enter alert message" : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Alert Type"),
                value: alertType,
                items: const [
                  DropdownMenuItem(value: "sensor", child: Text("Sensor Alert")),
                  DropdownMenuItem(value: "system", child: Text("System Alert")),
                ],
                onChanged: (value) => setState(() {
                  alertType = value!;
                }),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _triggerAlert,
                child: const Text("Trigger Alert"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
