from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1OauthClientsByIdProvidersByProviderIdBody")


@_attrs_define
class PostV1OauthClientsByIdProvidersByProviderIdBody:
    """
    Attributes:
        client_id_override (None | str | Unset):
        client_secret_override (None | str | Unset):
    """

    client_id_override: None | str | Unset = UNSET
    client_secret_override: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client_id_override: None | str | Unset
        if isinstance(self.client_id_override, Unset):
            client_id_override = UNSET
        else:
            client_id_override = self.client_id_override

        client_secret_override: None | str | Unset
        if isinstance(self.client_secret_override, Unset):
            client_secret_override = UNSET
        else:
            client_secret_override = self.client_secret_override

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if client_id_override is not UNSET:
            field_dict["client_id_override"] = client_id_override
        if client_secret_override is not UNSET:
            field_dict["client_secret_override"] = client_secret_override

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)

        def _parse_client_id_override(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        client_id_override = _parse_client_id_override(d.pop("client_id_override", UNSET))

        def _parse_client_secret_override(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        client_secret_override = _parse_client_secret_override(
            d.pop("client_secret_override", UNSET)
        )

        post_v1_oauth_clients_by_id_providers_by_provider_id_body = cls(
            client_id_override=client_id_override,
            client_secret_override=client_secret_override,
        )

        post_v1_oauth_clients_by_id_providers_by_provider_id_body.additional_properties = d
        return post_v1_oauth_clients_by_id_providers_by_provider_id_body

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
