from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.get_v1_content_urls_response_200_data_item import (
        GetV1ContentUrlsResponse200DataItem,
    )


T = TypeVar("T", bound="GetV1ContentUrlsResponse200")


@_attrs_define
class GetV1ContentUrlsResponse200:
    """
    Attributes:
        object_ (Literal['list']):
        data (list[GetV1ContentUrlsResponse200DataItem]):
        has_more (bool):
        url (str):
    """

    object_: Literal["list"]
    data: list[GetV1ContentUrlsResponse200DataItem]
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
        from ..models.get_v1_content_urls_response_200_data_item import (
            GetV1ContentUrlsResponse200DataItem,
        )

        d = dict(src_dict)
        object_ = cast(Literal["list"], d.pop("object"))
        if object_ != "list":
            raise ValueError(f"object must match const 'list', got '{object_}'")

        data = []
        _data = d.pop("data")
        for data_item_data in _data:
            data_item = GetV1ContentUrlsResponse200DataItem.from_dict(data_item_data)

            data.append(data_item)

        has_more = d.pop("has_more")

        url = d.pop("url")

        get_v1_content_urls_response_200 = cls(
            object_=object_,
            data=data,
            has_more=has_more,
            url=url,
        )

        get_v1_content_urls_response_200.additional_properties = d
        return get_v1_content_urls_response_200

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
