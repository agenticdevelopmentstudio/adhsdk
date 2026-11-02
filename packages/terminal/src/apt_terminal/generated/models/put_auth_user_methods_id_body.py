from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutAuthUserMethodsIdBody")


@_attrs_define
class PutAuthUserMethodsIdBody:
    """
    Attributes:
        provider_id (str | Unset):
        credential (str | Unset):
        clear_credential (bool | Unset):
    """

    provider_id: str | Unset = UNSET
    credential: str | Unset = UNSET
    clear_credential: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        provider_id = self.provider_id

        credential = self.credential

        clear_credential = self.clear_credential

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if provider_id is not UNSET:
            field_dict["providerId"] = provider_id
        if credential is not UNSET:
            field_dict["credential"] = credential
        if clear_credential is not UNSET:
            field_dict["clearCredential"] = clear_credential

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        provider_id = d.pop("providerId", UNSET)

        credential = d.pop("credential", UNSET)

        clear_credential = d.pop("clearCredential", UNSET)

        put_auth_user_methods_id_body = cls(
            provider_id=provider_id,
            credential=credential,
            clear_credential=clear_credential,
        )

        put_auth_user_methods_id_body.additional_properties = d
        return put_auth_user_methods_id_body

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
