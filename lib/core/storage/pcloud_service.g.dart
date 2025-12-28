// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pcloud_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PCloudService)
const pCloudServiceProvider = PCloudServiceProvider._();

final class PCloudServiceProvider
    extends $AsyncNotifierProvider<PCloudService, void> {
  const PCloudServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pCloudServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pCloudServiceHash();

  @$internal
  @override
  PCloudService create() => PCloudService();
}

String _$pCloudServiceHash() => r'421d4d59b113565ea709b425986eec104245ed34';

abstract class _$PCloudService extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
