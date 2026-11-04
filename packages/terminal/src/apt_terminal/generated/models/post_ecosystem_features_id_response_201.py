from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.provisioned_feature import ProvisionedFeature


T = TypeVar("T", bound="PostEcosystemFeaturesIdResponse201")


@_attrs_define
class PostEcosystemFeaturesIdResponse201:
    """
    Attributes:
        features (list[ProvisionedFeature]):
    """

    features: list[ProvisionedFeature]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        features = []
        for features_item_data in self.features:
            features_item = features_item_data.to_dict()
            features.append(features_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "features": features,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.provisioned_feature import ProvisionedFeature

        d = dict(src_dict)
        features = []
        _features = d.pop("features")
        for features_item_data in _features:
            features_item = ProvisionedFeature.from_dict(features_item_data)

            features.append(features_item)

        post_ecosystem_features_id_response_201 = cls(
            features=features,
        )

        post_ecosystem_features_id_response_201.additional_properties = d
        return post_ecosystem_features_id_response_201

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
