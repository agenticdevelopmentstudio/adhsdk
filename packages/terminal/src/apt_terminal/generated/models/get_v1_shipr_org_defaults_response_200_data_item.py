from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.shipr_org_defaults_env_branches import ShiprOrgDefaultsEnvBranches


T = TypeVar("T", bound="GetV1ShiprOrgDefaultsResponse200DataItem")


@_attrs_define
class GetV1ShiprOrgDefaultsResponse200DataItem:
    """
    Attributes:
        id (str | Unset):
        org (str | Unset): The forge account login.
        deployment_owner (None | str | Unset): Which org the deployment repositories go in. Null is “the same org”,
            stored as null rather than as a copy so that an operator who never chose stays distinguishable from one who
            chose the org they were already in.
        name_suffix (str | Unset): `-deployment`, spelled per-org. Appended to the source repository’s name when its
            `.shipr` declares no shards.
        env_branches (ShiprOrgDefaultsEnvBranches | Unset): The ladder a new mirror starts with. Empty means the built-
            in default (every environment, named after itself), not a repository that deploys nowhere.
        created (int | Unset): Unix timestamp, in seconds.
        updated (int | Unset): Unix timestamp, in seconds.
        object_ (Literal['shipr.org_default'] | Unset):
    """

    id: str | Unset = UNSET
    org: str | Unset = UNSET
    deployment_owner: None | str | Unset = UNSET
    name_suffix: str | Unset = UNSET
    env_branches: ShiprOrgDefaultsEnvBranches | Unset = UNSET
    created: int | Unset = UNSET
    updated: int | Unset = UNSET
    object_: Literal["shipr.org_default"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        org = self.org

        deployment_owner: None | str | Unset
        if isinstance(self.deployment_owner, Unset):
            deployment_owner = UNSET
        else:
            deployment_owner = self.deployment_owner

        name_suffix = self.name_suffix

        env_branches: dict[str, Any] | Unset = UNSET
        if not isinstance(self.env_branches, Unset):
            env_branches = self.env_branches.to_dict()

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if org is not UNSET:
            field_dict["org"] = org
        if deployment_owner is not UNSET:
            field_dict["deployment_owner"] = deployment_owner
        if name_suffix is not UNSET:
            field_dict["name_suffix"] = name_suffix
        if env_branches is not UNSET:
            field_dict["env_branches"] = env_branches
        if created is not UNSET:
            field_dict["created"] = created
        if updated is not UNSET:
            field_dict["updated"] = updated
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.shipr_org_defaults_env_branches import (
            ShiprOrgDefaultsEnvBranches,
        )

        d = dict(src_dict)
        id = d.pop("id", UNSET)

        org = d.pop("org", UNSET)

        def _parse_deployment_owner(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deployment_owner = _parse_deployment_owner(d.pop("deployment_owner", UNSET))

        name_suffix = d.pop("name_suffix", UNSET)

        _env_branches = d.pop("env_branches", UNSET)
        env_branches: ShiprOrgDefaultsEnvBranches | Unset
        if isinstance(_env_branches, Unset):
            env_branches = UNSET
        else:
            env_branches = ShiprOrgDefaultsEnvBranches.from_dict(_env_branches)

        created = d.pop("created", UNSET)

        updated = d.pop("updated", UNSET)

        object_ = cast(Literal["shipr.org_default"] | Unset, d.pop("object", UNSET))
        if object_ != "shipr.org_default" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'shipr.org_default', got '{object_}'")

        get_v1_shipr_org_defaults_response_200_data_item = cls(
            id=id,
            org=org,
            deployment_owner=deployment_owner,
            name_suffix=name_suffix,
            env_branches=env_branches,
            created=created,
            updated=updated,
            object_=object_,
        )

        get_v1_shipr_org_defaults_response_200_data_item.additional_properties = d
        return get_v1_shipr_org_defaults_response_200_data_item

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
