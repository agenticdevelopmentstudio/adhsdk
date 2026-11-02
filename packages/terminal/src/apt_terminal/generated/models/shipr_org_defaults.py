from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.shipr_org_defaults_env_branches import ShiprOrgDefaultsEnvBranches


T = TypeVar("T", bound="ShiprOrgDefaults")


@_attrs_define
class ShiprOrgDefaults:
    """What a mirror in one forge org is BORN with — never a description of one that already exists. Read when a mirror is
    first written; changing it re-aims the next repository and moves nothing already registered.

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
            created_at (str | Unset):
            updated_at (str | Unset):
    """

    id: str | Unset = UNSET
    org: str | Unset = UNSET
    deployment_owner: None | str | Unset = UNSET
    name_suffix: str | Unset = UNSET
    env_branches: ShiprOrgDefaultsEnvBranches | Unset = UNSET
    created_at: str | Unset = UNSET
    updated_at: str | Unset = UNSET
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

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if org is not UNSET:
            field_dict["org"] = org
        if deployment_owner is not UNSET:
            field_dict["deploymentOwner"] = deployment_owner
        if name_suffix is not UNSET:
            field_dict["nameSuffix"] = name_suffix
        if env_branches is not UNSET:
            field_dict["envBranches"] = env_branches
        if created_at is not UNSET:
            field_dict["createdAt"] = created_at
        if updated_at is not UNSET:
            field_dict["updatedAt"] = updated_at

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

        deployment_owner = _parse_deployment_owner(d.pop("deploymentOwner", UNSET))

        name_suffix = d.pop("nameSuffix", UNSET)

        _env_branches = d.pop("envBranches", UNSET)
        env_branches: ShiprOrgDefaultsEnvBranches | Unset
        if isinstance(_env_branches, Unset):
            env_branches = UNSET
        else:
            env_branches = ShiprOrgDefaultsEnvBranches.from_dict(_env_branches)

        created_at = d.pop("createdAt", UNSET)

        updated_at = d.pop("updatedAt", UNSET)

        shipr_org_defaults = cls(
            id=id,
            org=org,
            deployment_owner=deployment_owner,
            name_suffix=name_suffix,
            env_branches=env_branches,
            created_at=created_at,
            updated_at=updated_at,
        )

        shipr_org_defaults.additional_properties = d
        return shipr_org_defaults

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
