from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.ai_processing_provider_kind import AiProcessingProviderKind

if TYPE_CHECKING:
    from ..models.ai_processing_config_set_params import AiProcessingConfigSetParams
    from ..models.ai_processing_config_set_service_type_0 import AiProcessingConfigSetServiceType0


T = TypeVar("T", bound="AiProcessingConfigSet")


@_attrs_define
class AiProcessingConfigSet:
    """
    Attributes:
        id (UUID):
        name (str):
        description (None | str):
        service (AiProcessingConfigSetServiceType0 | None): The personas service this set calls; null = the node's local
            LLM
        provider (AiProcessingProviderKind):
        model (str):
        params (AiProcessingConfigSetParams):
        is_default (bool):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
    """

    id: UUID
    name: str
    description: None | str
    service: AiProcessingConfigSetServiceType0 | None
    provider: AiProcessingProviderKind
    model: str
    params: AiProcessingConfigSetParams
    is_default: bool
    created: int
    updated: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.ai_processing_config_set_service_type_0 import (
            AiProcessingConfigSetServiceType0,
        )

        id = str(self.id)

        name = self.name

        description: None | str
        description = self.description

        service: dict[str, Any] | None
        if isinstance(self.service, AiProcessingConfigSetServiceType0):
            service = self.service.to_dict()
        else:
            service = self.service

        provider = self.provider.value

        model = self.model

        params = self.params.to_dict()

        is_default = self.is_default

        created = self.created

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "description": description,
                "service": service,
                "provider": provider,
                "model": model,
                "params": params,
                "is_default": is_default,
                "created": created,
                "updated": updated,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_config_set_params import (
            AiProcessingConfigSetParams,
        )
        from ..models.ai_processing_config_set_service_type_0 import (
            AiProcessingConfigSetServiceType0,
        )

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        def _parse_service(data: object) -> AiProcessingConfigSetServiceType0 | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                service_type_0 = AiProcessingConfigSetServiceType0.from_dict(data)

                return service_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(AiProcessingConfigSetServiceType0 | None, data)

        service = _parse_service(d.pop("service"))

        provider = AiProcessingProviderKind(d.pop("provider"))

        model = d.pop("model")

        params = AiProcessingConfigSetParams.from_dict(d.pop("params"))

        is_default = d.pop("is_default")

        created = d.pop("created")

        updated = d.pop("updated")

        ai_processing_config_set = cls(
            id=id,
            name=name,
            description=description,
            service=service,
            provider=provider,
            model=model,
            params=params,
            is_default=is_default,
            created=created,
            updated=updated,
        )

        ai_processing_config_set.additional_properties = d
        return ai_processing_config_set

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
