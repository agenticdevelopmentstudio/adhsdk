from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.post_v1_pending_users_response_201_data_item import (
        PostV1PendingUsersResponse201DataItem,
    )


T = TypeVar("T", bound="PostV1PendingUsersResponse201")


@_attrs_define
class PostV1PendingUsersResponse201:
    """
    Attributes:
        object_ (Literal['list']):
        data (list[PostV1PendingUsersResponse201DataItem]):
        has_more (bool):
        url (str):
    """

    object_: Literal["list"]
    data: list[PostV1PendingUsersResponse201DataItem]
    has_more: bool
    url: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        object_ = self.object_

        data = []
        for data_item_data in self.data:
            data_item = data_item_data.to_dict()
            data.append(data_item)

        has_more = self.has_more

        url = self.url

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "object": object_,
                "data": data,
                "has_more": has_more,
                "url": url,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_pending_users_response_201_data_item import (
            PostV1PendingUsersResponse201DataItem,
        )

        d = dict(src_dict)
        object_ = cast(Literal["list"], d.pop("object"))
        if object_ != "list":
            raise ValueError(f"object must match const 'list', got '{object_}'")

        data = []
        _data = d.pop("data")
        for data_item_data in _data:
            data_item = PostV1PendingUsersResponse201DataItem.from_dict(data_item_data)

            data.append(data_item)

        has_more = d.pop("has_more")

        url = d.pop("url")

        post_v1_pending_users_response_201 = cls(
            object_=object_,
            data=data,
            has_more=has_more,
            url=url,
        )

        post_v1_pending_users_response_201.additional_properties = d
        return post_v1_pending_users_response_201

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
