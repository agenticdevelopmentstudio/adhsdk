from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.unavailable_feature import UnavailableFeature


T = TypeVar("T", bound="GetV1EcosystemsByIdFeaturesResponse200Availability")


@_attrs_define
class GetV1EcosystemsByIdFeaturesResponse200Availability:
    """
    Attributes:
        unavailable (list[UnavailableFeature]):
    """

    unavailable: list[UnavailableFeature]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        unavailable = []
        for unavailable_item_data in self.unavailable:
            unavailable_item = unavailable_item_data.to_dict()
            unavailable.append(unavailable_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "unavailable": unavailable,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.unavailable_feature import UnavailableFeature

        d = dict(src_dict)
        unavailable = []
        _unavailable = d.pop("unavailable")
        for unavailable_item_data in _unavailable:
            unavailable_item = UnavailableFeature.from_dict(unavailable_item_data)

            unavailable.append(unavailable_item)

        get_v1_ecosystems_by_id_features_response_200_availability = cls(
            unavailable=unavailable,
        )

        get_v1_ecosystems_by_id_features_response_200_availability.additional_properties = d
        return get_v1_ecosystems_by_id_features_response_200_availability

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
