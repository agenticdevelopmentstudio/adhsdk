from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.friendship import Friendship


T = TypeVar("T", bound="GetV1FriendsResponse200DataItem")


@_attrs_define
class GetV1FriendsResponse200DataItem:
    """
    Attributes:
        friend_id (str):
        friendship (Friendship):
        object_ (Literal['friend'] | Unset):
    """

    friend_id: str
    friendship: Friendship
    object_: Literal["friend"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        friend_id = self.friend_id

        friendship = self.friendship.to_dict()

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "friend_id": friend_id,
                "friendship": friendship,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.friendship import Friendship

        d = dict(src_dict)
        friend_id = d.pop("friend_id")

        friendship = Friendship.from_dict(d.pop("friendship"))

        object_ = cast(Literal["friend"] | Unset, d.pop("object", UNSET))
        if object_ != "friend" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'friend', got '{object_}'")

        get_v1_friends_response_200_data_item = cls(
            friend_id=friend_id,
            friendship=friendship,
            object_=object_,
        )

        get_v1_friends_response_200_data_item.additional_properties = d
        return get_v1_friends_response_200_data_item

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
