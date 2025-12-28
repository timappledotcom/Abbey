// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Unified file service that handles saving/loading files
/// to either local storage or pCloud based on user settings.

@ProviderFor(fileService)
const fileServiceProvider = FileServiceProvider._();

/// Unified file service that handles saving/loading files
/// to either local storage or pCloud based on user settings.

final class FileServiceProvider
    extends $FunctionalProvider<FileService, FileService, FileService>
    with $Provider<FileService> {
  /// Unified file service that handles saving/loading files
  /// to either local storage or pCloud based on user settings.
  const FileServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileServiceHash();

  @$internal
  @override
  $ProviderElement<FileService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileService create(Ref ref) {
    return fileService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileService>(value),
    );
  }
}

String _$fileServiceHash() => r'94fd5263f49f99caa7fcfad9d33e00b4240917b0';
