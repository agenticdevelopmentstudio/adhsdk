from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_account_mfa_passkeys_response_200_data_item_kind import (
    GetV1AccountMfaPasskeysResponse200DataItemKind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AccountMfaPasskeysResponse200DataItem")


@_attrs_define
class GetV1AccountMfaPasskeysResponse200DataItem:
    """
    Attributes:
        id (str):
        name (str):
        kind (GetV1AccountMfaPasskeysResponse200DataItemKind):
        created (int): Unix timestamp, in seconds.
        object_ (Literal['account.mfa.passkey'] | Unset):
        last_used_at (None | str | Unset):
    """

    id: str
    name: str
    kind: GetV1AccountMfaPasskeysResponse200DataItemKind
    created: int
    object_: Literal["account.mfa.passkey"] | Unset = UNSET
    last_used_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        kind = self.kind.value

        created = self.created

        object_ = self.object_

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
                "created": created,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if last_used_at is not UNSET:
            field_dict["last_used_at"] = last_used_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        kind = GetV1AccountMfaPasskeysResponse200DataItemKind(d.pop("kind"))

        created = d.pop("created")

        object_ = cast(Literal["account.mfa.passkey"] | Unset, d.pop("object", UNSET))
        if object_ != "account.mfa.passkey" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'account.mfa.passkey', got '{object_}'")

        def _parse_last_used_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_used_at = _parse_last_used_at(d.pop("last_used_at", UNSET))

        get_v1_account_mfa_passkeys_response_200_data_item = cls(
            id=id,
            name=name,
            kind=kind,
            created=created,
            object_=object_,
            last_used_at=last_used_at,
        )

        get_v1_account_mfa_passkeys_response_200_data_item.additional_properties = d
        return get_v1_account_mfa_passkeys_response_200_data_item

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
