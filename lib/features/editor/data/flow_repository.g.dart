// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flow_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(flowRepository)
const flowRepositoryProvider = FlowRepositoryProvider._();

final class FlowRepositoryProvider
    extends $FunctionalProvider<FlowRepository, FlowRepository, FlowRepository>
    with $Provider<FlowRepository> {
  const FlowRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flowRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flowRepositoryHash();

  @$internal
  @override
  $ProviderElement<FlowRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FlowRepository create(Ref ref) {
    return flowRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlowRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlowRepository>(value),
    );
  }
}

String _$flowRepositoryHash() => r'75320cf0c77604f1161f36db5525cc2c9637a113';
