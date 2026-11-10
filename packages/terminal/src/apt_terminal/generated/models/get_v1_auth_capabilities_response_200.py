from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.get_v1_auth_capabilities_response_200_data_item_type_0 import (
        GetV1AuthCapabilitiesResponse200DataItemType0,
    )


T = TypeVar("T", bound="GetV1AuthCapabilitiesResponse200")


@_attrs_define
class GetV1AuthCapabilitiesResponse200:
    """
    Attributes:
        object_ (Literal['list']):
        data (list[GetV1AuthCapabilitiesResponse200DataItemType0 | str]):
        has_more (bool):
        url (str):
    """

    object_: Literal["list"]
    data: list[GetV1AuthCapabilitiesResponse200DataItemType0 | str]
    has_more: bool
    url: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_v1_auth_capabilities_response_200_data_item_type_0 import (
            GetV1AuthCapabilitiesResponse200DataItemType0,
        )

        object_ = self.object_

        data = []
        for data_item_data in self.data:
            data_item: dict[str, Any] | str
            if isinstance(data_item_data, GetV1AuthCapabilitiesResponse200DataItemType0):
                data_item = data_item_data.to_dict()
            else:
                data_item = data_item_data
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
        from ..models.get_v1_auth_capabilities_response_200_data_item_type_0 import (
            GetV1AuthCapabilitiesResponse200DataItemType0,
        )

        d = dict(src_dict)
        object_ = cast(Literal["list"], d.pop("object"))
        if object_ != "list":
            raise ValueError(f"object must match const 'list', got '{object_}'")

        data = []
        _data = d.pop("data")
        for data_item_data in _data:

            def _parse_data_item(
                data: object,
            ) -> GetV1AuthCapabilitiesResponse200DataItemType0 | str:
                try:
                    if not isinstance(data, dict):
                        raise TypeError()
                    data_item_type_0 = GetV1AuthCapabilitiesResponse200DataItemType0.from_dict(data)

                    return data_item_type_0
                except (TypeError, ValueError, AttributeError, KeyError):
                    pass
                return cast(GetV1AuthCapabilitiesResponse200DataItemType0 | str, data)

            data_item = _parse_data_item(data_item_data)

            data.append(data_item)

        has_more = d.pop("has_more")

        url = d.pop("url")

        get_v1_auth_capabilities_response_200 = cls(
            object_=object_,
            data=data,
            has_more=has_more,
            url=url,
        )

        get_v1_auth_capabilities_response_200.additional_properties = d
        return get_v1_auth_capabilities_response_200

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
