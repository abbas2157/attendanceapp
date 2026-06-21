enum AttendanceAction {
  checkIn,
  checkOut,
  alreadyDone,
  cooldown,
  ambiguousFace,
  error,
}

enum AttendanceClaimType { employeeCode, attendanceCode }

class AttendancePrecheckResponse {
  final String status;
  final bool allowed;
  final String message;
  final String? warehouseShortName;
  final String? warehouseFullName;
  final String? employeeName;

  const AttendancePrecheckResponse({
    required this.status,
    required this.allowed,
    required this.message,
    this.warehouseShortName,
    this.warehouseFullName,
    this.employeeName,
  });

  factory AttendancePrecheckResponse.fromJson(Map<String, dynamic> json) {
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final employee = json['employee'] as Map<String, dynamic>?;

    return AttendancePrecheckResponse(
      status: json['status'] as String? ?? 'error',
      allowed: json['allowed'] as bool? ?? false,
      message:
          json['message'] as String? ?? 'Unable to validate attendance code.',
      warehouseShortName: warehouse?['short_name'] as String?,
      warehouseFullName: warehouse?['full_name'] as String?,
      employeeName: employee?['name'] as String?,
    );
  }
}

class AttendanceResponse {
  final String status;
  final String? action;
  final String message;
  final String? employee;
  final String? time;
  final String? hoursWorked;
  final double? confidence;
  final String? checkIn;
  final String? checkOut;
  final double? matchMargin;
  final String? decision;

  const AttendanceResponse({
    required this.status,
    this.action,
    required this.message,
    this.employee,
    this.time,
    this.hoursWorked,
    this.confidence,
    this.checkIn,
    this.checkOut,
    this.matchMargin,
    this.decision,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      status: json['status'] as String,
      action: json['action'] as String?,
      message: json['message'] as String,
      employee: json['employee'] as String?,
      time: json['time'] as String?,
      hoursWorked: json['hours_worked'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      checkIn: json['check_in'] as String?,
      checkOut: json['check_out'] as String?,
      matchMargin: (json['match_margin'] as num?)?.toDouble(),
      decision: json['decision'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'action': action,
      'message': message,
      'employee': employee,
      'time': time,
      'hours_worked': hoursWorked,
      'confidence': confidence,
      'check_in': checkIn,
      'check_out': checkOut,
      'match_margin': matchMargin,
      'decision': decision,
    };
  }

  AttendanceAction get parsedAction {
    if (status == 'cooldown') return AttendanceAction.cooldown;
    if (status == 'already_done') return AttendanceAction.alreadyDone;
    if (status == 'ambiguous_face') return AttendanceAction.ambiguousFace;
    if (status == 'error') return AttendanceAction.error;

    switch (action) {
      case 'check_in':
        return AttendanceAction.checkIn;
      case 'check_out':
        return AttendanceAction.checkOut;
      default:
        return AttendanceAction.error;
    }
  }
}
