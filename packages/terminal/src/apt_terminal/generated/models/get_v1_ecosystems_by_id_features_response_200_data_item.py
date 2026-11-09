from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.provisioned_feature_state import ProvisionedFeatureState
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1EcosystemsByIdFeaturesResponse200DataItem")


@_attrs_define
class GetV1EcosystemsByIdFeaturesResponse200DataItem:
    """
    Attributes:
        feature_key (str):
        state (ProvisionedFeatureState): Only `active` counts as on. `provisioning` is a claim whose artifacts are not
            all there yet; `removed` keeps the record (and the data) of a feature taken off the rail.
        provisioned_at (str): When the feature was FIRST added. Never rewritten by a re-add.
        updated (int): Unix timestamp, in seconds.
        provisioned_by (None | str | Unset):
        object_ (Literal['feature'] | Unset):
    """

    feature_key: str
    state: ProvisionedFeatureState
    provisioned_at: str
    updated: int
    provisioned_by: None | str | Unset = UNSET
    object_: Literal["feature"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        feature_key = self.feature_key

        state = self.state.value

        provisioned_at = self.provisioned_at

        updated = self.updated

        provisioned_by: None | str | Unset
        if isinstance(self.provisioned_by, Unset):
            provisioned_by = UNSET
        else:
            provisioned_by = self.provisioned_by

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "feature_key": feature_key,
                "state": state,
                "provisioned_at": provisioned_at,
                "updated": updated,
            }
        )
        if provisioned_by is not UNSET:
            field_dict["provisioned_by"] = provisioned_by
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        feature_key = d.pop("feature_key")

        state = ProvisionedFeatureState(d.pop("state"))

        provisioned_at = d.pop("provisioned_at")

        updated = d.pop("updated")

        def _parse_provisioned_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        provisioned_by = _parse_provisioned_by(d.pop("provisioned_by", UNSET))

        object_ = cast(Literal["feature"] | Unset, d.pop("object", UNSET))
        if object_ != "feature" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'feature', got '{object_}'")

        get_v1_ecosystems_by_id_features_response_200_data_item = cls(
            feature_key=feature_key,
            state=state,
            provisioned_at=provisioned_at,
            updated=updated,
            provisioned_by=provisioned_by,
            object_=object_,
        )

        get_v1_ecosystems_by_id_features_response_200_data_item.additional_properties = d
        return get_v1_ecosystems_by_id_features_response_200_data_item

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
