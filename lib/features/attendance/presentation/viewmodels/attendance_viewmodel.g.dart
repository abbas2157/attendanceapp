// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AttendanceViewModel)
final attendanceViewModelProvider = AttendanceViewModelFamily._();

final class AttendanceViewModelProvider
    extends $NotifierProvider<AttendanceViewModel, AttendanceState> {
  AttendanceViewModelProvider._({
    required AttendanceViewModelFamily super.from,
    required ({Position initialPosition, WarehouseModel activeWarehouse})
    super.argument,
  }) : super(
         retry: null,
         name: r'attendanceViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attendanceViewModelHash();

  @override
  String toString() {
    return r'attendanceViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AttendanceViewModel create() => AttendanceViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttendanceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttendanceState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AttendanceViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attendanceViewModelHash() =>
    r'a85ba3419e365ef9134a977543cc9e5f33c588aa';

final class AttendanceViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          AttendanceViewModel,
          AttendanceState,
          AttendanceState,
          AttendanceState,
          ({Position initialPosition, WarehouseModel activeWarehouse})
        > {
  AttendanceViewModelFamily._()
    : super(
        retry: null,
        name: r'attendanceViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AttendanceViewModelProvider call({
    required Position initialPosition,
    required WarehouseModel activeWarehouse,
  }) => AttendanceViewModelProvider._(
    argument: (
      initialPosition: initialPosition,
      activeWarehouse: activeWarehouse,
    ),
    from: this,
  );

  @override
  String toString() => r'attendanceViewModelProvider';
}

abstract class _$AttendanceViewModel extends $Notifier<AttendanceState> {
  late final _$args =
      ref.$arg as ({Position initialPosition, WarehouseModel activeWarehouse});
  Position get initialPosition => _$args.initialPosition;
  WarehouseModel get activeWarehouse => _$args.activeWarehouse;

  AttendanceState build({
    required Position initialPosition,
    required WarehouseModel activeWarehouse,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AttendanceState, AttendanceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AttendanceState, AttendanceState>,
              AttendanceState,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        initialPosition: _$args.initialPosition,
        activeWarehouse: _$args.activeWarehouse,
      ),
    );
  }
}
