// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_user_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddUserViewModel)
final addUserViewModelProvider = AddUserViewModelProvider._();

final class AddUserViewModelProvider
    extends $NotifierProvider<AddUserViewModel, AddUserState> {
  AddUserViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addUserViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addUserViewModelHash();

  @$internal
  @override
  AddUserViewModel create() => AddUserViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddUserState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddUserState>(value),
    );
  }
}

String _$addUserViewModelHash() => r'4532a59634f8c42e601e1405002af8f5c0779934';

abstract class _$AddUserViewModel extends $Notifier<AddUserState> {
  AddUserState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AddUserState, AddUserState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddUserState, AddUserState>,
              AddUserState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
