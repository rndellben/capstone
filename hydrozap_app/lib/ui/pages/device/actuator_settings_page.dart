// ui/pages/device/actuator_settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/actuator_provider.dart';

class ActuatorSettingsPage extends StatefulWidget {
  final String deviceId;
  const ActuatorSettingsPage({super.key, required this.deviceId});

  @override
  _ActuatorSettingsPageState createState() => _ActuatorSettingsPageState();
}

class _ActuatorSettingsPageState extends State<ActuatorSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  String sensorType = '';
  String operator = '>';
  double thresholdValue = 0.0;
  String action = '';
  String actuatorName = '';

  Future<void> _addCondition() async {
    if (_formKey.currentState!.validate()) {
      final actuatorProvider =
          Provider.of<ActuatorProvider>(context, listen: false);

      final success = await actuatorProvider.addActuatorCondition({
        "device_id": widget.deviceId,
        "sensor": sensorType,
        "operator": operator,
        "value": thresholdValue,
        "action": action,
        "actuator": actuatorName,
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Condition added successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error adding condition!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Actuator Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Sensor Type"),
                onSaved: (value) => sensorType = value!,
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: "Operator"),
                value: operator,
                items: const [
                  DropdownMenuItem(value: ">", child: Text(">")),
                  DropdownMenuItem(value: "<", child: Text("<")),
                  DropdownMenuItem(value: "==", child: Text("==")),
                ],
                onChanged: (value) => setState(() {
                  operator = value.toString();
                }),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Threshold Value"),
                keyboardType: TextInputType.number,
                onSaved: (value) => thresholdValue = double.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Action"),
                onSaved: (value) => action = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Actuator Name"),
                onSaved: (value) => actuatorName = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addCondition,
                child: const Text("Add Condition"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
