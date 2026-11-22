from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.catalog_feature_set_entries_limits_item_type import (
    CatalogFeatureSetEntriesLimitsItemType,
)

T = TypeVar("T", bound="CatalogFeatureSetEntriesLimitsItem")


@_attrs_define
class CatalogFeatureSetEntriesLimitsItem:
    """
    Attributes:
        key (str):
        type_ (CatalogFeatureSetEntriesLimitsItemType):
        label (str):
    """

    key: str
    type_: CatalogFeatureSetEntriesLimitsItemType
    label: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        type_ = self.type_.value

        label = self.label

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "type": type_,
                "label": label,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        type_ = CatalogFeatureSetEntriesLimitsItemType(d.pop("type"))

        label = d.pop("label")

        catalog_feature_set_entries_limits_item = cls(
            key=key,
            type_=type_,
            label=label,
        )

        catalog_feature_set_entries_limits_item.additional_properties = d
        return catalog_feature_set_entries_limits_item

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
