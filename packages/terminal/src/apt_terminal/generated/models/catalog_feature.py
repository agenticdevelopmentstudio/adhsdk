from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.catalog_feature_subscription_tier import CatalogFeatureSubscriptionTier
from ..types import UNSET, Unset

T = TypeVar("T", bound="CatalogFeature")


@_attrs_define
class CatalogFeature:
    """
    Attributes:
        key (str): Stable, permanent identifier.
        label (str):
        description (str):
        subscription_tier (CatalogFeatureSubscriptionTier): Displayed as "Subscription Level Required: <tier>". A
            PLACEHOLDER — nothing enforces it.
        feature_site (bool | Unset): The feature carries a public site of its own (the persona registry, research).
        coming_soon (bool | Unset): Not built yet. Listed so the picker can say it is coming; provisioning it is refused
            (400).
        requires_features (list[str] | Unset): Feature keys this one needs. Adding it provisions them too; they cannot
            be removed while it is active (409 feature_required).
        own_ecosystem_only (bool | Unset): Only a user's or an organization's own ecosystem may hold it; a client
            ecosystem cannot (400). GET /ecosystem/features/{id}/availability names these per ecosystem.
        included_with (str | Unset): The feature this one comes with (the Users Settings, the Applications Client Auth
            panel). The picker does not list it: adding the parent adds it, removing the parent removes it, adding it adds
            the parent, and removing it on its own is refused (400).
    """

    key: str
    label: str
    description: str
    subscription_tier: CatalogFeatureSubscriptionTier
    feature_site: bool | Unset = UNSET
    coming_soon: bool | Unset = UNSET
    requires_features: list[str] | Unset = UNSET
    own_ecosystem_only: bool | Unset = UNSET
    included_with: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        description = self.description

        subscription_tier = self.subscription_tier.value

        feature_site = self.feature_site

        coming_soon = self.coming_soon

        requires_features: list[str] | Unset = UNSET
        if not isinstance(self.requires_features, Unset):
            requires_features = self.requires_features

        own_ecosystem_only = self.own_ecosystem_only

        included_with = self.included_with

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "description": description,
                "subscriptionTier": subscription_tier,
            }
        )
        if feature_site is not UNSET:
            field_dict["featureSite"] = feature_site
        if coming_soon is not UNSET:
            field_dict["comingSoon"] = coming_soon
        if requires_features is not UNSET:
            field_dict["requiresFeatures"] = requires_features
        if own_ecosystem_only is not UNSET:
            field_dict["ownEcosystemOnly"] = own_ecosystem_only
        if included_with is not UNSET:
            field_dict["includedWith"] = included_with

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        description = d.pop("description")

        subscription_tier = CatalogFeatureSubscriptionTier(d.pop("subscriptionTier"))

        feature_site = d.pop("featureSite", UNSET)

        coming_soon = d.pop("comingSoon", UNSET)

        requires_features = cast(list[str], d.pop("requiresFeatures", UNSET))

        own_ecosystem_only = d.pop("ownEcosystemOnly", UNSET)

        included_with = d.pop("includedWith", UNSET)

        catalog_feature = cls(
            key=key,
            label=label,
            description=description,
            subscription_tier=subscription_tier,
            feature_site=feature_site,
            coming_soon=coming_soon,
            requires_features=requires_features,
            own_ecosystem_only=own_ecosystem_only,
            included_with=included_with,
        )

        catalog_feature.additional_properties = d
        return catalog_feature

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
