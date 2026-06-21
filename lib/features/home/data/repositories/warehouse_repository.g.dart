// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(warehouseRepository)
final warehouseRepositoryProvider = WarehouseRepositoryProvider._();

final class WarehouseRepositoryProvider
    extends
        $FunctionalProvider<
          WarehouseRepository,
          WarehouseRepository,
          WarehouseRepository
        >
    with $Provider<WarehouseRepository> {
  WarehouseRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'warehouseRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$warehouseRepositoryHash();

  @$internal
  @override
  $ProviderElement<WarehouseRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WarehouseRepository create(Ref ref) {
    return warehouseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WarehouseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WarehouseRepository>(value),
    );
  }
}

String _$warehouseRepositoryHash() =>
    r'5a00efac13cce60b8b81a7d62757b5dcff805734';
