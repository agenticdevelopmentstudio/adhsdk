from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.catalog_feature_allowed_in_item import CatalogFeatureAllowedInItem
from ..models.catalog_feature_automatic_in_item import CatalogFeatureAutomaticInItem
from ..models.catalog_feature_subscription_tier import CatalogFeatureSubscriptionTier
from ..models.catalog_feature_workspace_owner_kinds_item import (
    CatalogFeatureWorkspaceOwnerKindsItem,
)
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
        allowed_in (list[CatalogFeatureAllowedInItem] | Unset): The ecosystem types that may hold it; absent means every
            type except workspace, personal and organization. Adding it elsewhere is refused (400). GET
            /ecosystem/features/{id}/availability names these per ecosystem.
        workspace_owner_kinds (list[CatalogFeatureWorkspaceOwnerKindsItem] | Unset): Narrows allowedIn for a workspace
            by who owns it: Teams is allowed only in an organization workspace. Absent means either owner kind.
        automatic_in (list[CatalogFeatureAutomaticInItem] | Unset): The ecosystem types that get it when provisioned,
            with no owner opt-in (a workspace gets Personas; a Personal or Organization ecosystem gets its hub data).
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
    allowed_in: list[CatalogFeatureAllowedInItem] | Unset = UNSET
    workspace_owner_kinds: list[CatalogFeatureWorkspaceOwnerKindsItem] | Unset = UNSET
    automatic_in: list[CatalogFeatureAutomaticInItem] | Unset = UNSET
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

        allowed_in: list[str] | Unset = UNSET
        if not isinstance(self.allowed_in, Unset):
            allowed_in = []
            for allowed_in_item_data in self.allowed_in:
                allowed_in_item = allowed_in_item_data.value
                allowed_in.append(allowed_in_item)

        workspace_owner_kinds: list[str] | Unset = UNSET
        if not isinstance(self.workspace_owner_kinds, Unset):
            workspace_owner_kinds = []
            for workspace_owner_kinds_item_data in self.workspace_owner_kinds:
                workspace_owner_kinds_item = workspace_owner_kinds_item_data.value
                workspace_owner_kinds.append(workspace_owner_kinds_item)

        automatic_in: list[str] | Unset = UNSET
        if not isinstance(self.automatic_in, Unset):
            automatic_in = []
            for automatic_in_item_data in self.automatic_in:
                automatic_in_item = automatic_in_item_data.value
                automatic_in.append(automatic_in_item)

        included_with = self.included_with

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "description": description,
                "subscription_tier": subscription_tier,
            }
        )
        if feature_site is not UNSET:
            field_dict["feature_site"] = feature_site
        if coming_soon is not UNSET:
            field_dict["coming_soon"] = coming_soon
        if requires_features is not UNSET:
            field_dict["requires_features"] = requires_features
        if allowed_in is not UNSET:
            field_dict["allowed_in"] = allowed_in
        if workspace_owner_kinds is not UNSET:
            field_dict["workspace_owner_kinds"] = workspace_owner_kinds
        if automatic_in is not UNSET:
            field_dict["automatic_in"] = automatic_in
        if included_with is not UNSET:
            field_dict["included_with"] = included_with

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        description = d.pop("description")

        subscription_tier = CatalogFeatureSubscriptionTier(d.pop("subscription_tier"))

        feature_site = d.pop("feature_site", UNSET)

        coming_soon = d.pop("coming_soon", UNSET)

        requires_features = cast(list[str], d.pop("requires_features", UNSET))

        _allowed_in = d.pop("allowed_in", UNSET)
        allowed_in: list[CatalogFeatureAllowedInItem] | Unset = UNSET
        if _allowed_in is not UNSET:
            allowed_in = []
            for allowed_in_item_data in _allowed_in:
                allowed_in_item = CatalogFeatureAllowedInItem(allowed_in_item_data)

                allowed_in.append(allowed_in_item)

        _workspace_owner_kinds = d.pop("workspace_owner_kinds", UNSET)
        workspace_owner_kinds: list[CatalogFeatureWorkspaceOwnerKindsItem] | Unset = UNSET
        if _workspace_owner_kinds is not UNSET:
            workspace_owner_kinds = []
            for workspace_owner_kinds_item_data in _workspace_owner_kinds:
                workspace_owner_kinds_item = CatalogFeatureWorkspaceOwnerKindsItem(
                    workspace_owner_kinds_item_data
                )

                workspace_owner_kinds.append(workspace_owner_kinds_item)

        _automatic_in = d.pop("automatic_in", UNSET)
        automatic_in: list[CatalogFeatureAutomaticInItem] | Unset = UNSET
        if _automatic_in is not UNSET:
            automatic_in = []
            for automatic_in_item_data in _automatic_in:
                automatic_in_item = CatalogFeatureAutomaticInItem(automatic_in_item_data)

                automatic_in.append(automatic_in_item)

        included_with = d.pop("included_with", UNSET)

        catalog_feature = cls(
            key=key,
            label=label,
            description=description,
            subscription_tier=subscription_tier,
            feature_site=feature_site,
            coming_soon=coming_soon,
            requires_features=requires_features,
            allowed_in=allowed_in,
            workspace_owner_kinds=workspace_owner_kinds,
            automatic_in=automatic_in,
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
