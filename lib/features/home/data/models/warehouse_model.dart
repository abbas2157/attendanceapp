class WarehouseModel {
  int id;
  String fullName;
  String shortName;
  int status;
  String? remarks;
  String? latlong;

  WarehouseModel({
    required this.id,
    required this.fullName,
    required this.shortName,
    required this.status,
    this.remarks,
    this.latlong,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      shortName: json['short_name'] as String,
      status: json['status'] as int,
      remarks: json['remarks'] as String?,
      latlong: json['latlong'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'short_name': shortName,
      'status': status,
      'remarks': remarks,
      'latlong': latlong,
    };
  }
}
