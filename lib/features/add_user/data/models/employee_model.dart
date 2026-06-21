class EmployeeModel {
  final int? id;
  final String employeecode;
  final String name;
  final String fathername;
  final String attendancecode;
  final String warehouseid;
  final String? latlong;
  final int faceSampleCount;

  const EmployeeModel({
    this.id,
    required this.employeecode,
    required this.name,
    required this.fathername,
    required this.attendancecode,
    required this.warehouseid,
    this.latlong,
    this.faceSampleCount = 0,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as int?,
      employeecode: json['employeecode'] as String,
      name: json['name'] as String,
      fathername: json['fathername'] as String,
      attendancecode: json['attendancecode'] as String,
      warehouseid: json['warehouseid'] as String,
      latlong: json['latlong'] as String?,
      faceSampleCount: (json['face_sample_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'employeecode': employeecode,
      'name': name,
      'fathername': fathername,
      'attendancecode': attendancecode,
      'warehouseid': warehouseid,
      'face_sample_count': faceSampleCount,
      if (latlong != null) 'latlong': latlong,
    };
  }
}

class AddEmployeeRequest {
  final String employeecode;
  final String name;
  final String fathername;
  final String attendancecode;
  final String warehouseid;
  final String? latlong;
  final List<String> photoPaths;
  final List<String> angleLabels;
  final String captureSessionId;

  const AddEmployeeRequest({
    required this.employeecode,
    required this.name,
    required this.fathername,
    required this.attendancecode,
    required this.warehouseid,
    this.latlong,
    required this.photoPaths,
    required this.angleLabels,
    required this.captureSessionId,
  });
}
