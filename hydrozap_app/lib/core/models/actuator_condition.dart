class ActuatorCondition {
  final String id;
  final String name;
  final String status;
  final String deviceId;

  ActuatorCondition({
    required this.id,
    required this.name,
    required this.status,
    required this.deviceId,
  });

  // Create a factory method to parse JSON
  factory ActuatorCondition.fromJson(Map<String, dynamic> json) {
    return ActuatorCondition(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      deviceId: json['device_id'] ?? '',
    );
  }
}
