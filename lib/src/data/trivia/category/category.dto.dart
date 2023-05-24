// ignore_for_file: avoid_final_parameters, invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.dto.freezed.dart';
part 'category.dto.g.dart';

@freezed
class CategoryDTO with _$CategoryDTO {
  const factory CategoryDTO({
    /// The id of category.
    @JsonKey(name: 'id') required final int id,

    /// The name of category
    /// For example: Film, Music, Books, etc...
    @JsonKey(name: 'name') required final String name,
  }) = _CategoryDTO;

  factory CategoryDTO.fromJson(Map<String, dynamic> json) =>
      _$CategoryDTOFromJson(json);
}