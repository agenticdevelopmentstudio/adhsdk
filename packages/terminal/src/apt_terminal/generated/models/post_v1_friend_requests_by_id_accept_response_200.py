from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.friendship_status import FriendshipStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1FriendRequestsByIdAcceptResponse200")


@_attrs_define
class PostV1FriendRequestsByIdAcceptResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        requester_id (str):
        addressee_id (str):
        status (FriendshipStatus):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['friend_request'] | Unset):
    """

    id: str
    ecosystem_id: str
    requester_id: str
    addressee_id: str
    status: FriendshipStatus
    created: int
    updated: int
    object_: Literal["friend_request"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        requester_id = self.requester_id

        addressee_id = self.addressee_id

        status = self.status.value

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "requester_id": requester_id,
                "addressee_id": addressee_id,
                "status": status,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        requester_id = d.pop("requester_id")

        addressee_id = d.pop("addressee_id")

        status = FriendshipStatus(d.pop("status"))

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["friend_request"] | Unset, d.pop("object", UNSET))
        if object_ != "friend_request" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'friend_request', got '{object_}'")

        post_v1_friend_requests_by_id_accept_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            requester_id=requester_id,
            addressee_id=addressee_id,
            status=status,
            created=created,
            updated=updated,
            object_=object_,
        )

        post_v1_friend_requests_by_id_accept_response_200.additional_properties = d
        return post_v1_friend_requests_by_id_accept_response_200

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
