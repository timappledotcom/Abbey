// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'essay_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EssayRepository)
const essayRepositoryProvider = EssayRepositoryProvider._();

final class EssayRepositoryProvider
    extends $AsyncNotifierProvider<EssayRepository, List<Essay>> {
  const EssayRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'essayRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$essayRepositoryHash();

  @$internal
  @override
  EssayRepository create() => EssayRepository();
}

String _$essayRepositoryHash() => r'45eb72051deaa9f21e19f1d7c6487f65093e2287';

abstract class _$EssayRepository extends $AsyncNotifier<List<Essay>> {
  FutureOr<List<Essay>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Essay>>, List<Essay>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Essay>>, List<Essay>>,
              AsyncValue<List<Essay>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
