from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.catalog_feature_set_entries_limits_item import CatalogFeatureSetEntriesLimitsItem


T = TypeVar("T", bound="CatalogFeatureSetEntries")


@_attrs_define
class CatalogFeatureSetEntries:
    """What the feature contributes to sets: `permission` when the feature itself can be in a set, and the typed limits a
    set may define under it. Limit keys are unique across the catalog. The Sets screen is generated from these.

        Attributes:
            permission (bool | Unset):
            limits (list[CatalogFeatureSetEntriesLimitsItem] | Unset):
    """

    permission: bool | Unset = UNSET
    limits: list[CatalogFeatureSetEntriesLimitsItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        permission = self.permission

        limits: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.limits, Unset):
            limits = []
            for limits_item_data in self.limits:
                limits_item = limits_item_data.to_dict()
                limits.append(limits_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if permission is not UNSET:
            field_dict["permission"] = permission
        if limits is not UNSET:
            field_dict["limits"] = limits

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.catalog_feature_set_entries_limits_item import (
            CatalogFeatureSetEntriesLimitsItem,
        )

        d = dict(src_dict)
        permission = d.pop("permission", UNSET)

        _limits = d.pop("limits", UNSET)
        limits: list[CatalogFeatureSetEntriesLimitsItem] | Unset = UNSET
        if _limits is not UNSET:
            limits = []
            for limits_item_data in _limits:
                limits_item = CatalogFeatureSetEntriesLimitsItem.from_dict(limits_item_data)

                limits.append(limits_item)

        catalog_feature_set_entries = cls(
            permission=permission,
            limits=limits,
        )

        catalog_feature_set_entries.additional_properties = d
        return catalog_feature_set_entries

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
