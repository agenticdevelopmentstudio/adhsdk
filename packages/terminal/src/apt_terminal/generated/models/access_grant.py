from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="AccessGrant")


@_attrs_define
class AccessGrant:
    """
    Attributes:
        feature (str): a feature-area key, e.g. 'projects' | 'personas'
        item_verbs (str): top-level item verbs, comma-letter subset of 'C,R,U,D,M' (M = manage access)
        subitem_verbs (str): sub-item verbs, subset of 'C,R,U,D'
    """

    feature: str
    item_verbs: str
    subitem_verbs: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        feature = self.feature

        item_verbs = self.item_verbs

        subitem_verbs = self.subitem_verbs

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "feature": feature,
                "itemVerbs": item_verbs,
                "subitemVerbs": subitem_verbs,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        feature = d.pop("feature")

        item_verbs = d.pop("itemVerbs")

        subitem_verbs = d.pop("subitemVerbs")

        access_grant = cls(
            feature=feature,
            item_verbs=item_verbs,
            subitem_verbs=subitem_verbs,
        )

        access_grant.additional_properties = d
        return access_grant

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
