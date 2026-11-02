from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.provider_template_model_source import ProviderTemplateModelSource

if TYPE_CHECKING:
    from ..models.provider_template_model_metadata_type_0 import ProviderTemplateModelMetadataType0


T = TypeVar("T", bound="ProviderTemplateModel")


@_attrs_define
class ProviderTemplateModel:
    """
    Attributes:
        id (str):
        name (str):
        description (None | str):
        metadata (None | ProviderTemplateModelMetadataType0):
        source (ProviderTemplateModelSource):
        last_synced_at (None | str):
        created_at (str):
    """

    id: str
    name: str
    description: None | str
    metadata: None | ProviderTemplateModelMetadataType0
    source: ProviderTemplateModelSource
    last_synced_at: None | str
    created_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.provider_template_model_metadata_type_0 import (
            ProviderTemplateModelMetadataType0,
        )

        id = self.id

        name = self.name

        description: None | str
        description = self.description

        metadata: dict[str, Any] | None
        if isinstance(self.metadata, ProviderTemplateModelMetadataType0):
            metadata = self.metadata.to_dict()
        else:
            metadata = self.metadata

        source = self.source.value

        last_synced_at: None | str
        last_synced_at = self.last_synced_at

        created_at = self.created_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
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
        from ..models.provider_template_model_metadata_type_0 import (
            ProviderTemplateModelMetadataType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        def _parse_metadata(data: object) -> None | ProviderTemplateModelMetadataType0:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                metadata_type_0 = ProviderTemplateModelMetadataType0.from_dict(data)

                return metadata_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ProviderTemplateModelMetadataType0, data)

        metadata = _parse_metadata(d.pop("metadata"))

        source = ProviderTemplateModelSource(d.pop("source"))

        def _parse_last_synced_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_synced_at = _parse_last_synced_at(d.pop("lastSyncedAt"))

        created_at = d.pop("createdAt")

        provider_template_model = cls(
            id=id,
            name=name,
            description=description,
            metadata=metadata,
            source=source,
            last_synced_at=last_synced_at,
            created_at=created_at,
        )

        provider_template_model.additional_properties = d
        return provider_template_model

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
