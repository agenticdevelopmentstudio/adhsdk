from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AccessFeaturesResponse200DataItem")


@_attrs_define
class GetV1AccessFeaturesResponse200DataItem:
    """
    Attributes:
        key (str): the feature-area key grants are recorded against, e.g. 'audiences'
        label (str): the display name for this area (the roles editor labels its row with it)
        object_ (Literal['access.feature'] | Unset):
    """

    key: str
    label: str
    object_: Literal["access.feature"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        object_ = cast(Literal["access.feature"] | Unset, d.pop("object", UNSET))
        if object_ != "access.feature" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'access.feature', got '{object_}'")

        get_v1_access_features_response_200_data_item = cls(
            key=key,
            label=label,
            object_=object_,
        )

        get_v1_access_features_response_200_data_item.additional_properties = d
        return get_v1_access_features_response_200_data_item

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
