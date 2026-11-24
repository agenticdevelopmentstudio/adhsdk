from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="AuthUserMethod")


@_attrs_define
class AuthUserMethod:
    """
    Attributes:
        id (str):
        user_id (str):
        provider (str):
        provider_id (None | str):
        has_credential (bool):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
    """

    id: str
    user_id: str
    provider: str
    provider_id: None | str
    has_credential: bool
    created: int
    updated: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        user_id = self.user_id

        provider = self.provider

        provider_id: None | str
        provider_id = self.provider_id

        has_credential = self.has_credential

        created = self.created

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "user_id": user_id,
                "provider": provider,
                "provider_id": provider_id,
                "has_credential": has_credential,
                "created": created,
                "updated": updated,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        user_id = d.pop("user_id")

        provider = d.pop("provider")

        def _parse_provider_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        provider_id = _parse_provider_id(d.pop("provider_id"))

        has_credential = d.pop("has_credential")

        created = d.pop("created")

        updated = d.pop("updated")

        auth_user_method = cls(
            id=id,
            user_id=user_id,
            provider=provider,
            provider_id=provider_id,
            has_credential=has_credential,
            created=created,
            updated=updated,
        )

        auth_user_method.additional_properties = d
        return auth_user_method

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
