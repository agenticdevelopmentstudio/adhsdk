from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.provider_connection_spec_type_0 import ProviderConnectionSpecType0


T = TypeVar("T", bound="PatchPersonaServicesIdBody")


@_attrs_define
class PatchPersonaServicesIdBody:
    """
    Attributes:
        name (str | Unset):
        base_url (str | Unset):
        api_key (str | Unset): Plaintext provider key; stored, never returned
        connection_spec (None | ProviderConnectionSpecType0 | Unset):
    """

    name: str | Unset = UNSET
    base_url: str | Unset = UNSET
    api_key: str | Unset = UNSET
    connection_spec: None | ProviderConnectionSpecType0 | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.provider_connection_spec_type_0 import (
            ProviderConnectionSpecType0,
        )

        name = self.name

        base_url = self.base_url

        api_key = self.api_key

        connection_spec: dict[str, Any] | None | Unset
        if isinstance(self.connection_spec, Unset):
            connection_spec = UNSET
        elif isinstance(self.connection_spec, ProviderConnectionSpecType0):
            connection_spec = self.connection_spec.to_dict()
        else:
            connection_spec = self.connection_spec

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if base_url is not UNSET:
            field_dict["baseUrl"] = base_url
        if api_key is not UNSET:
            field_dict["apiKey"] = api_key
        if connection_spec is not UNSET:
            field_dict["connectionSpec"] = connection_spec

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.provider_connection_spec_type_0 import (
            ProviderConnectionSpecType0,
        )

        d = dict(src_dict)
        name = d.pop("name", UNSET)

        base_url = d.pop("baseUrl", UNSET)

        api_key = d.pop("apiKey", UNSET)

        def _parse_connection_spec(data: object) -> None | ProviderConnectionSpecType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_provider_connection_spec_type_0 = (
                    ProviderConnectionSpecType0.from_dict(data)
                )

                return componentsschemas_provider_connection_spec_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ProviderConnectionSpecType0 | Unset, data)

        connection_spec = _parse_connection_spec(d.pop("connectionSpec", UNSET))

        patch_persona_services_id_body = cls(
            name=name,
            base_url=base_url,
            api_key=api_key,
            connection_spec=connection_spec,
        )

        patch_persona_services_id_body.additional_properties = d
        return patch_persona_services_id_body

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
