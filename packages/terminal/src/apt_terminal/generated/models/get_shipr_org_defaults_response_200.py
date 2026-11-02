from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.shipr_org_defaults import ShiprOrgDefaults


T = TypeVar("T", bound="GetShiprOrgDefaultsResponse200")


@_attrs_define
class GetShiprOrgDefaultsResponse200:
    """
    Attributes:
        org_defaults (list[ShiprOrgDefaults]):
    """

    org_defaults: list[ShiprOrgDefaults]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        org_defaults = []
        for org_defaults_item_data in self.org_defaults:
            org_defaults_item = org_defaults_item_data.to_dict()
            org_defaults.append(org_defaults_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "orgDefaults": org_defaults,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.shipr_org_defaults import ShiprOrgDefaults

        d = dict(src_dict)
        org_defaults = []
        _org_defaults = d.pop("orgDefaults")
        for org_defaults_item_data in _org_defaults:
            org_defaults_item = ShiprOrgDefaults.from_dict(org_defaults_item_data)

            org_defaults.append(org_defaults_item)

        get_shipr_org_defaults_response_200 = cls(
            org_defaults=org_defaults,
        )

        get_shipr_org_defaults_response_200.additional_properties = d
        return get_shipr_org_defaults_response_200

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
