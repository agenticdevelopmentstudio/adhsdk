from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_models_response_201_metadata_type_0_type_1 import (
        PostV1ModelsResponse201MetadataType0Type1,
    )


T = TypeVar("T", bound="PostV1ModelsResponse201")


@_attrs_define
class PostV1ModelsResponse201:
    """
    Attributes:
        id (str):
        template_id (str):
        name (str):
        description (None | str):
        metadata (bool | float | list[Any] | None | PostV1ModelsResponse201MetadataType0Type1 | str):
        source (str):
        last_synced_at (None | str):
        created (int): Unix timestamp, in seconds.
        object_ (Literal['model'] | Unset):
    """

    id: str
    template_id: str
    name: str
    description: None | str
    metadata: bool | float | list[Any] | None | PostV1ModelsResponse201MetadataType0Type1 | str
    source: str
    last_synced_at: None | str
    created: int
    object_: Literal["model"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_models_response_201_metadata_type_0_type_1 import (
            PostV1ModelsResponse201MetadataType0Type1,
        )

        id = self.id

        template_id = self.template_id

        name = self.name

        description: None | str
        description = self.description

        metadata: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.metadata, PostV1ModelsResponse201MetadataType0Type1):
            metadata = self.metadata.to_dict()
        elif isinstance(self.metadata, list):
            metadata = self.metadata

        else:
            metadata = self.metadata

        source = self.source

        last_synced_at: None | str
        last_synced_at = self.last_synced_at

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "template_id": template_id,
                "name": name,
                "description": description,
                "metadata": metadata,
                "source": source,
                "last_synced_at": last_synced_at,
                "created": created,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_models_response_201_metadata_type_0_type_1 import (
            PostV1ModelsResponse201MetadataType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        template_id = d.pop("template_id")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        def _parse_metadata(
            data: object,
        ) -> bool | float | list[Any] | None | PostV1ModelsResponse201MetadataType0Type1 | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = PostV1ModelsResponse201MetadataType0Type1.from_dict(data)

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
                bool | float | list[Any] | None | PostV1ModelsResponse201MetadataType0Type1 | str,
                data,
            )

        metadata = _parse_metadata(d.pop("metadata"))

        source = d.pop("source")

        def _parse_last_synced_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_synced_at = _parse_last_synced_at(d.pop("last_synced_at"))

        created = d.pop("created")

        object_ = cast(Literal["model"] | Unset, d.pop("object", UNSET))
        if object_ != "model" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'model', got '{object_}'")

        post_v1_models_response_201 = cls(
            id=id,
            template_id=template_id,
            name=name,
            description=description,
            metadata=metadata,
            source=source,
            last_synced_at=last_synced_at,
            created=created,
            object_=object_,
        )

        return post_v1_models_response_201
