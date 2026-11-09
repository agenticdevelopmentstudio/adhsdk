from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1OauthClientsByIdProvidersByProviderIdResponse200")


@_attrs_define
class PostV1OauthClientsByIdProvidersByProviderIdResponse200:
    """
    Attributes:
        client_slug (str):
        provider_slug (str):
        has_overrides (bool):
        object_ (Literal['provider'] | Unset):
    """

    client_slug: str
    provider_slug: str
    has_overrides: bool
    object_: Literal["provider"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client_slug = self.client_slug

        provider_slug = self.provider_slug

        has_overrides = self.has_overrides

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "client_slug": client_slug,
                "provider_slug": provider_slug,
                "has_overrides": has_overrides,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        client_slug = d.pop("client_slug")

        provider_slug = d.pop("provider_slug")

        has_overrides = d.pop("has_overrides")

        object_ = cast(Literal["provider"] | Unset, d.pop("object", UNSET))
        if object_ != "provider" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'provider', got '{object_}'")

        post_v1_oauth_clients_by_id_providers_by_provider_id_response_200 = cls(
            client_slug=client_slug,
            provider_slug=provider_slug,
            has_overrides=has_overrides,
            object_=object_,
        )

        post_v1_oauth_clients_by_id_providers_by_provider_id_response_200.additional_properties = d
        return post_v1_oauth_clients_by_id_providers_by_provider_id_response_200

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
