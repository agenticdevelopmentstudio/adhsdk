from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_bucket_types_by_id_body_metadata_type_0_type_1 import (
        PostV1BucketTypesByIdBodyMetadataType0Type1,
    )


T = TypeVar("T", bound="PostV1BucketTypesByIdBody")


@_attrs_define
class PostV1BucketTypesByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        bucket_id (str | Unset):
        sql_table_name (str | Unset):
        name (str | Unset):
        description (str | Unset):
        ref_mode (str | Unset):
        metadata (bool | float | list[Any] | None | PostV1BucketTypesByIdBodyMetadataType0Type1 | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    bucket_id: str | Unset = UNSET
    sql_table_name: str | Unset = UNSET
    name: str | Unset = UNSET
    description: str | Unset = UNSET
    ref_mode: str | Unset = UNSET
    metadata: (
        bool | float | list[Any] | None | PostV1BucketTypesByIdBodyMetadataType0Type1 | str | Unset
    ) = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_bucket_types_by_id_body_metadata_type_0_type_1 import (
            PostV1BucketTypesByIdBodyMetadataType0Type1,
        )

        ecosystem_id = self.ecosystem_id

        bucket_id = self.bucket_id

        sql_table_name = self.sql_table_name

        name = self.name

        description = self.description

        ref_mode = self.ref_mode

        metadata: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.metadata, Unset):
            metadata = UNSET
        elif isinstance(self.metadata, PostV1BucketTypesByIdBodyMetadataType0Type1):
            metadata = self.metadata.to_dict()
        elif isinstance(self.metadata, list):
            metadata = self.metadata

        else:
            metadata = self.metadata

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if bucket_id is not UNSET:
            field_dict["bucket_id"] = bucket_id
        if sql_table_name is not UNSET:
            field_dict["sql_table_name"] = sql_table_name
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if ref_mode is not UNSET:
            field_dict["ref_mode"] = ref_mode
        if metadata is not UNSET:
            field_dict["metadata"] = metadata

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_bucket_types_by_id_body_metadata_type_0_type_1 import (
            PostV1BucketTypesByIdBodyMetadataType0Type1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        bucket_id = d.pop("bucket_id", UNSET)

        sql_table_name = d.pop("sql_table_name", UNSET)

        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        ref_mode = d.pop("ref_mode", UNSET)

        def _parse_metadata(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1BucketTypesByIdBodyMetadataType0Type1
            | str
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = PostV1BucketTypesByIdBodyMetadataType0Type1.from_dict(data)

                return metadata_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                metadata_type_0_type_2 = cast(list[Any], data)

                return metadata_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostV1BucketTypesByIdBodyMetadataType0Type1
                | str
                | Unset,
                data,
            )

        metadata = _parse_metadata(d.pop("metadata", UNSET))

        post_v1_bucket_types_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            bucket_id=bucket_id,
            sql_table_name=sql_table_name,
            name=name,
            description=description,
            ref_mode=ref_mode,
            metadata=metadata,
        )

        return post_v1_bucket_types_by_id_body
