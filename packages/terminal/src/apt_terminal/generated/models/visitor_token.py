from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="VisitorToken")


@_attrs_define
class VisitorToken:
    """
    Attributes:
        token (str): The bearer token itself, `tmp_` followed by 64 hex characters. Returned once at mint and stored
            only as a hash — it cannot be recovered.
        expires_at (str):
        persona_id (str):
    """

    token: str
    expires_at: str
    persona_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        expires_at = self.expires_at

        persona_id = self.persona_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "token": token,
                "expiresAt": expires_at,
                "personaId": persona_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        token = d.pop("token")

        expires_at = d.pop("expiresAt")

        persona_id = d.pop("personaId")

        visitor_token = cls(
            token=token,
            expires_at=expires_at,
            persona_id=persona_id,
        )

        visitor_token.additional_properties = d
        return visitor_token

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
