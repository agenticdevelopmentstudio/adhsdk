from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_models_by_id_body_metadata_type_0_type_1 import (
        PostV1ModelsByIdBodyMetadataType0Type1,
    )


T = TypeVar("T", bound="PostV1ModelsByIdBody")


@_attrs_define
class PostV1ModelsByIdBody:
    """
    Attributes:
        template_id (str | Unset):
        name (str | Unset):
        description (None | str | Unset):
        metadata (bool | float | list[Any] | None | PostV1ModelsByIdBodyMetadataType0Type1 | str | Unset):
    """

    template_id: str | Unset = UNSET
    name: str | Unset = UNSET
    description: None | str | Unset = UNSET
    metadata: (
        bool | float | list[Any] | None | PostV1ModelsByIdBodyMetadataType0Type1 | str | Unset
    ) = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_models_by_id_body_metadata_type_0_type_1 import (
            PostV1ModelsByIdBodyMetadataType0Type1,
        )

        template_id = self.template_id

        name = self.name

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        metadata: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.metadata, Unset):
            metadata = UNSET
        elif isinstance(self.metadata, PostV1ModelsByIdBodyMetadataType0Type1):
            metadata = self.metadata.to_dict()
        elif isinstance(self.metadata, list):
            metadata = self.metadata

        else:
            metadata = self.metadata

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if template_id is not UNSET:
            field_dict["template_id"] = template_id
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if metadata is not UNSET:
            field_dict["metadata"] = metadata

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_models_by_id_body_metadata_type_0_type_1 import (
            PostV1ModelsByIdBodyMetadataType0Type1,
        )

        d = dict(src_dict)
        template_id = d.pop("template_id", UNSET)

        name = d.pop("name", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        def _parse_metadata(
            data: object,
        ) -> bool | float | list[Any] | None | PostV1ModelsByIdBodyMetadataType0Type1 | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = PostV1ModelsByIdBodyMetadataType0Type1.from_dict(data)

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
                | PostV1ModelsByIdBodyMetadataType0Type1
                | str
                | Unset,
                data,
            )

        metadata = _parse_metadata(d.pop("metadata", UNSET))

        post_v1_models_by_id_body = cls(
            template_id=template_id,
            name=name,
            description=description,
            metadata=metadata,
        )

        return post_v1_models_by_id_body
