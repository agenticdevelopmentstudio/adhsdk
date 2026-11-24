from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AuthUserMethodsBody")


@_attrs_define
class PostV1AuthUserMethodsBody:
    """
    Attributes:
        user_id (str):
        provider (str):
        provider_id (None | str | Unset):
        credential (None | str | Unset):
    """

    user_id: str
    provider: str
    provider_id: None | str | Unset = UNSET
    credential: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_id = self.user_id

        provider = self.provider

        provider_id: None | str | Unset
        if isinstance(self.provider_id, Unset):
            provider_id = UNSET
        else:
            provider_id = self.provider_id

        credential: None | str | Unset
        if isinstance(self.credential, Unset):
            credential = UNSET
        else:
            credential = self.credential

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "user_id": user_id,
                "provider": provider,
            }
        )
        if provider_id is not UNSET:
            field_dict["provider_id"] = provider_id
        if credential is not UNSET:
            field_dict["credential"] = credential

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        user_id = d.pop("user_id")

        provider = d.pop("provider")

        def _parse_provider_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        provider_id = _parse_provider_id(d.pop("provider_id", UNSET))

        def _parse_credential(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        credential = _parse_credential(d.pop("credential", UNSET))

        post_v1_auth_user_methods_body = cls(
            user_id=user_id,
            provider=provider,
            provider_id=provider_id,
            credential=credential,
        )

        post_v1_auth_user_methods_body.additional_properties = d
        return post_v1_auth_user_methods_body

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
