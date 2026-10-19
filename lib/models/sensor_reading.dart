class SensorReading {
  final int bpm;
  final int spO2;
  final double stressScore;
  final bool isDistress;
  final String status;
  final DateTime timestamp;

  SensorReading({
    required this.bpm,
    required this.spO2,
    required this.stressScore,
    required this.isDistress,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SensorReading.fromBpm(int bpm, int spO2) {
    bool distress = bpm > 120 || bpm < 45 || spO2 < 90;
    String statusStr;
    double stress;

    if (bpm > 120) {
      statusStr = 'Critical Spike - Distress Detected!';
      stress = 92.0;
    } else if (bpm > 100) {
      statusStr = 'Elevated Pulse - High Stress';
      stress = 68.0;
    } else if (bpm < 50) {
      statusStr = 'Bradycardia - Low Pulse';
      stress = 75.0;
    } else {
      statusStr = 'Normal & Stable';
      stress = 24.0;
    }

    return SensorReading(
      bpm: bpm,
      spO2: spO2,
      stressScore: stress,
      isDistress: distress,
      status: statusStr,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'spO2': spO2,
      'stressScore': stressScore,
      'isDistress': isDistress,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}