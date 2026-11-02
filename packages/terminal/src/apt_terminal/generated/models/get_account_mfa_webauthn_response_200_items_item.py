from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_account_mfa_webauthn_response_200_items_item_kind import (
    GetAccountMfaWebauthnResponse200ItemsItemKind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetAccountMfaWebauthnResponse200ItemsItem")


@_attrs_define
class GetAccountMfaWebauthnResponse200ItemsItem:
    """
    Attributes:
        id (str):
        name (str):
        kind (GetAccountMfaWebauthnResponse200ItemsItemKind):
        created_at (str):
        last_used_at (None | str | Unset):
    """

    id: str
    name: str
    kind: GetAccountMfaWebauthnResponse200ItemsItemKind
    created_at: str
    last_used_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        kind = self.kind.value

        created_at = self.created_at

        last_used_at: None | str | Unset
        if isinstance(self.last_used_at, Unset):
            last_used_at = UNSET
        else:
            last_used_at = self.last_used_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "kind": kind,
                "createdAt": created_at,
            }
        )
        if last_used_at is not UNSET:
            field_dict["lastUsedAt"] = last_used_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        kind = GetAccountMfaWebauthnResponse200ItemsItemKind(d.pop("kind"))

        created_at = d.pop("createdAt")

        def _parse_last_used_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_used_at = _parse_last_used_at(d.pop("lastUsedAt", UNSET))

        get_account_mfa_webauthn_response_200_items_item = cls(
            id=id,
            name=name,
            kind=kind,
            created_at=created_at,
            last_used_at=last_used_at,
        )

        get_account_mfa_webauthn_response_200_items_item.additional_properties = d
        return get_account_mfa_webauthn_response_200_items_item

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
