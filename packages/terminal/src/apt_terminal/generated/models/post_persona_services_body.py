from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_persona_services_body_provider_kind import PostPersonaServicesBodyProviderKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.provider_connection_spec_type_0 import ProviderConnectionSpecType0


T = TypeVar("T", bound="PostPersonaServicesBody")


@_attrs_define
class PostPersonaServicesBody:
    """
    Attributes:
        name (str):
        provider_kind (PostPersonaServicesBodyProviderKind):
        base_url (str):
        template_id (str | Unset):
        api_key (str | Unset): Plaintext provider key; stored, never returned
        connection_spec (None | ProviderConnectionSpecType0 | Unset):
    """

    name: str
    provider_kind: PostPersonaServicesBodyProviderKind
    base_url: str
    template_id: str | Unset = UNSET
    api_key: str | Unset = UNSET
    connection_spec: None | ProviderConnectionSpecType0 | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.provider_connection_spec_type_0 import (
            ProviderConnectionSpecType0,
        )

        name = self.name

        provider_kind = self.provider_kind.value

        base_url = self.base_url

        template_id = self.template_id

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
        field_dict.update(
            {
                "name": name,
                "providerKind": provider_kind,
                "baseUrl": base_url,
            }
        )
        if template_id is not UNSET:
            field_dict["templateId"] = template_id
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
        name = d.pop("name")

        provider_kind = PostPersonaServicesBodyProviderKind(d.pop("providerKind"))

        base_url = d.pop("baseUrl")

        template_id = d.pop("templateId", UNSET)

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

        post_persona_services_body = cls(
            name=name,
            provider_kind=provider_kind,
            base_url=base_url,
            template_id=template_id,
            api_key=api_key,
            connection_spec=connection_spec,
        )

        post_persona_services_body.additional_properties = d
        return post_persona_services_body

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
