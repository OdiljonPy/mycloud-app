// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SyncSettingsState {
  bool get autoSyncEnabled => throw _privateConstructorUsedError;
  bool get wifiOnly => throw _privateConstructorUsedError;
  bool get useSelectedFiles => throw _privateConstructorUsedError;
  List<String> get selectedFiles => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of SyncSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncSettingsStateCopyWith<SyncSettingsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncSettingsStateCopyWith<$Res> {
  factory $SyncSettingsStateCopyWith(
    SyncSettingsState value,
    $Res Function(SyncSettingsState) then,
  ) = _$SyncSettingsStateCopyWithImpl<$Res, SyncSettingsState>;
  @useResult
  $Res call({
    bool autoSyncEnabled,
    bool wifiOnly,
    bool useSelectedFiles,
    List<String> selectedFiles,
    bool isLoading,
  });
}

/// @nodoc
class _$SyncSettingsStateCopyWithImpl<$Res, $Val extends SyncSettingsState>
    implements $SyncSettingsStateCopyWith<$Res> {
  _$SyncSettingsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? autoSyncEnabled = null,
    Object? wifiOnly = null,
    Object? useSelectedFiles = null,
    Object? selectedFiles = null,
    Object? isLoading = null,
  }) {
    return _then(
      _value.copyWith(
            autoSyncEnabled: null == autoSyncEnabled
                ? _value.autoSyncEnabled
                : autoSyncEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            wifiOnly: null == wifiOnly
                ? _value.wifiOnly
                : wifiOnly // ignore: cast_nullable_to_non_nullable
                      as bool,
            useSelectedFiles: null == useSelectedFiles
                ? _value.useSelectedFiles
                : useSelectedFiles // ignore: cast_nullable_to_non_nullable
                      as bool,
            selectedFiles: null == selectedFiles
                ? _value.selectedFiles
                : selectedFiles // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SyncSettingsStateImplCopyWith<$Res>
    implements $SyncSettingsStateCopyWith<$Res> {
  factory _$$SyncSettingsStateImplCopyWith(
    _$SyncSettingsStateImpl value,
    $Res Function(_$SyncSettingsStateImpl) then,
  ) = __$$SyncSettingsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool autoSyncEnabled,
    bool wifiOnly,
    bool useSelectedFiles,
    List<String> selectedFiles,
    bool isLoading,
  });
}

/// @nodoc
class __$$SyncSettingsStateImplCopyWithImpl<$Res>
    extends _$SyncSettingsStateCopyWithImpl<$Res, _$SyncSettingsStateImpl>
    implements _$$SyncSettingsStateImplCopyWith<$Res> {
  __$$SyncSettingsStateImplCopyWithImpl(
    _$SyncSettingsStateImpl _value,
    $Res Function(_$SyncSettingsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? autoSyncEnabled = null,
    Object? wifiOnly = null,
    Object? useSelectedFiles = null,
    Object? selectedFiles = null,
    Object? isLoading = null,
  }) {
    return _then(
      _$SyncSettingsStateImpl(
        autoSyncEnabled: null == autoSyncEnabled
            ? _value.autoSyncEnabled
            : autoSyncEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        wifiOnly: null == wifiOnly
            ? _value.wifiOnly
            : wifiOnly // ignore: cast_nullable_to_non_nullable
                  as bool,
        useSelectedFiles: null == useSelectedFiles
            ? _value.useSelectedFiles
            : useSelectedFiles // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectedFiles: null == selectedFiles
            ? _value._selectedFiles
            : selectedFiles // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$SyncSettingsStateImpl implements _SyncSettingsState {
  const _$SyncSettingsStateImpl({
    this.autoSyncEnabled = false,
    this.wifiOnly = false,
    this.useSelectedFiles = false,
    final List<String> selectedFiles = const <String>[],
    this.isLoading = true,
  }) : _selectedFiles = selectedFiles;

  @override
  @JsonKey()
  final bool autoSyncEnabled;
  @override
  @JsonKey()
  final bool wifiOnly;
  @override
  @JsonKey()
  final bool useSelectedFiles;
  final List<String> _selectedFiles;
  @override
  @JsonKey()
  List<String> get selectedFiles {
    if (_selectedFiles is EqualUnmodifiableListView) return _selectedFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedFiles);
  }

  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'SyncSettingsState(autoSyncEnabled: $autoSyncEnabled, wifiOnly: $wifiOnly, useSelectedFiles: $useSelectedFiles, selectedFiles: $selectedFiles, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncSettingsStateImpl &&
            (identical(other.autoSyncEnabled, autoSyncEnabled) ||
                other.autoSyncEnabled == autoSyncEnabled) &&
            (identical(other.wifiOnly, wifiOnly) ||
                other.wifiOnly == wifiOnly) &&
            (identical(other.useSelectedFiles, useSelectedFiles) ||
                other.useSelectedFiles == useSelectedFiles) &&
            const DeepCollectionEquality().equals(
              other._selectedFiles,
              _selectedFiles,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    autoSyncEnabled,
    wifiOnly,
    useSelectedFiles,
    const DeepCollectionEquality().hash(_selectedFiles),
    isLoading,
  );

  /// Create a copy of SyncSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncSettingsStateImplCopyWith<_$SyncSettingsStateImpl> get copyWith =>
      __$$SyncSettingsStateImplCopyWithImpl<_$SyncSettingsStateImpl>(
        this,
        _$identity,
      );
}

abstract class _SyncSettingsState implements SyncSettingsState {
  const factory _SyncSettingsState({
    final bool autoSyncEnabled,
    final bool wifiOnly,
    final bool useSelectedFiles,
    final List<String> selectedFiles,
    final bool isLoading,
  }) = _$SyncSettingsStateImpl;

  @override
  bool get autoSyncEnabled;
  @override
  bool get wifiOnly;
  @override
  bool get useSelectedFiles;
  @override
  List<String> get selectedFiles;
  @override
  bool get isLoading;

  /// Create a copy of SyncSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncSettingsStateImplCopyWith<_$SyncSettingsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
