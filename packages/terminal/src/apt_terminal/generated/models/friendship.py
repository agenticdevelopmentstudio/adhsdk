from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.friendship_status import FriendshipStatus

T = TypeVar("T", bound="Friendship")


@_attrs_define
class Friendship:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        requester_id (str):
        addressee_id (str):
        status (FriendshipStatus):
        created_at (str):
        updated_at (str):
    """

    id: str
    ecosystem_id: str
    requester_id: str
    addressee_id: str
    status: FriendshipStatus
    created_at: str
    updated_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        requester_id = self.requester_id

        addressee_id = self.addressee_id

        status = self.status.value

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "requesterId": requester_id,
                "addresseeId": addressee_id,
                "status": status,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        requester_id = d.pop("requesterId")

        addressee_id = d.pop("addresseeId")

        status = FriendshipStatus(d.pop("status"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        friendship = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            requester_id=requester_id,
            addressee_id=addressee_id,
            status=status,
            created_at=created_at,
            updated_at=updated_at,
        )

        friendship.additional_properties = d
        return friendship

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
