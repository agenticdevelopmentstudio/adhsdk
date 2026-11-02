from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.get_persona_models_response_200_item_metadata_type_0_type_1 import (
        GetPersonaModelsResponse200ItemMetadataType0Type1,
    )


T = TypeVar("T", bound="GetPersonaModelsResponse200Item")


@_attrs_define
class GetPersonaModelsResponse200Item:
    """
    Attributes:
        id (str):
        template_id (str):
        name (str):
        description (None | str):
        metadata (bool | float | GetPersonaModelsResponse200ItemMetadataType0Type1 | list[Any] | None | str):
        source (str):
        last_synced_at (None | str):
        created_at (str):
    """

    id: str
    template_id: str
    name: str
    description: None | str
    metadata: (
        bool | float | GetPersonaModelsResponse200ItemMetadataType0Type1 | list[Any] | None | str
    )
    source: str
    last_synced_at: None | str
    created_at: str

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_persona_models_response_200_item_metadata_type_0_type_1 import (
            GetPersonaModelsResponse200ItemMetadataType0Type1,
        )

        id = self.id

        template_id = self.template_id

        name = self.name

        description: None | str
        description = self.description

        metadata: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.metadata, GetPersonaModelsResponse200ItemMetadataType0Type1):
            metadata = self.metadata.to_dict()
        elif isinstance(self.metadata, list):
            metadata = self.metadata

        else:
            metadata = self.metadata

        source = self.source

        last_synced_at: None | str
        last_synced_at = self.last_synced_at

        created_at = self.created_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "templateId": template_id,
                "name": name,
                "description": description,
                "metadata": metadata,
                "source": source,
                "lastSyncedAt": last_synced_at,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_persona_models_response_200_item_metadata_type_0_type_1 import (
            GetPersonaModelsResponse200ItemMetadataType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        template_id = d.pop("templateId")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        def _parse_metadata(
            data: object,
        ) -> (
            bool
            | float
            | GetPersonaModelsResponse200ItemMetadataType0Type1
            | list[Any]
            | None
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0_type_1 = (
                    GetPersonaModelsResponse200ItemMetadataType0Type1.from_dict(data)
                )

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
                | GetPersonaModelsResponse200ItemMetadataType0Type1
                | list[Any]
                | None
                | str,
                data,
            )

        metadata = _parse_metadata(d.pop("metadata"))

        source = d.pop("source")

        def _parse_last_synced_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_synced_at = _parse_last_synced_at(d.pop("lastSyncedAt"))

        created_at = d.pop("createdAt")

        get_persona_models_response_200_item = cls(
            id=id,
            template_id=template_id,
            name=name,
            description=description,
            metadata=metadata,
            source=source,
            last_synced_at=last_synced_at,
            created_at=created_at,
        )

        return get_persona_models_response_200_item
