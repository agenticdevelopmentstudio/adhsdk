from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="SetGrantResult")


@_attrs_define
class SetGrantResult:
    """
    Attributes:
        grant_id (UUID): The new grant, or the live one when the set was already held.
        revoked (list[UUID]):
    """

    grant_id: UUID
    revoked: list[UUID]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        grant_id = str(self.grant_id)

        revoked = []
        for revoked_item_data in self.revoked:
            revoked_item = str(revoked_item_data)
            revoked.append(revoked_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "grant_id": grant_id,
                "revoked": revoked,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        grant_id = UUID(d.pop("grant_id"))

        revoked = []
        _revoked = d.pop("revoked")
        for revoked_item_data in _revoked:
            revoked_item = UUID(revoked_item_data)

            revoked.append(revoked_item)

        set_grant_result = cls(
            grant_id=grant_id,
            revoked=revoked,
        )

        set_grant_result.additional_properties = d
        return set_grant_result

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
