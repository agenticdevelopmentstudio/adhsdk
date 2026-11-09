from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.provisioned_feature import ProvisionedFeature


T = TypeVar("T", bound="PostV1EcosystemsByIdFeaturesResponse201")


@_attrs_define
class PostV1EcosystemsByIdFeaturesResponse201:
    """
    Attributes:
        features (list[ProvisionedFeature]):
        object_ (Literal['feature'] | Unset):
    """

    features: list[ProvisionedFeature]
    object_: Literal["feature"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        features = []
        for features_item_data in self.features:
            features_item = features_item_data.to_dict()
            features.append(features_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "features": features,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["feature"] | Unset, d.pop("object", UNSET))
        if object_ != "feature" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'feature', got '{object_}'")

        post_v1_ecosystems_by_id_features_response_201 = cls(
            features=features,
            object_=object_,
        )

        post_v1_ecosystems_by_id_features_response_201.additional_properties = d
        return post_v1_ecosystems_by_id_features_response_201

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
