from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1DataByTypeResponse200DataItem")


@_attrs_define
class GetV1DataByTypeResponse200DataItem:
    """
    Attributes:
        object_ (Literal['data'] | Unset):
    """

    object_: Literal["data"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        object_ = cast(Literal["data"] | Unset, d.pop("object", UNSET))
        if object_ != "data" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'data', got '{object_}'")

        get_v1_data_by_type_response_200_data_item = cls(
            object_=object_,
        )

        get_v1_data_by_type_response_200_data_item.additional_properties = d
        return get_v1_data_by_type_response_200_data_item

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
