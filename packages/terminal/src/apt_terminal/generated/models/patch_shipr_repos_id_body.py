from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.patch_shipr_repos_id_body_env_branches import PatchShiprReposIdBodyEnvBranches


T = TypeVar("T", bound="PatchShiprReposIdBody")


@_attrs_define
class PatchShiprReposIdBody:
    """
    Attributes:
        group_id (None | str | Unset):
        position (int | Unset):
        slug (str | Unset): owner/name of the DEPLOYMENT repository. 409 once it is provisioned.
        display_name (None | str | Unset): The source repository’s label, shown in the console instead of its slug. Null
            clears it.
        ship_branch (str | Unset):
        ci_context (str | Unset):
        env_branches (PatchShiprReposIdBodyEnvBranches | Unset):
    """

    group_id: None | str | Unset = UNSET
    position: int | Unset = UNSET
    slug: str | Unset = UNSET
    display_name: None | str | Unset = UNSET
    ship_branch: str | Unset = UNSET
    ci_context: str | Unset = UNSET
    env_branches: PatchShiprReposIdBodyEnvBranches | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        group_id: None | str | Unset
        if isinstance(self.group_id, Unset):
            group_id = UNSET
        else:
            group_id = self.group_id

        position = self.position

        slug = self.slug

        display_name: None | str | Unset
        if isinstance(self.display_name, Unset):
            display_name = UNSET
        else:
            display_name = self.display_name

        ship_branch = self.ship_branch

        ci_context = self.ci_context

        env_branches: dict[str, Any] | Unset = UNSET
        if not isinstance(self.env_branches, Unset):
            env_branches = self.env_branches.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if group_id is not UNSET:
            field_dict["groupId"] = group_id
        if position is not UNSET:
            field_dict["position"] = position
        if slug is not UNSET:
            field_dict["slug"] = slug
        if display_name is not UNSET:
            field_dict["displayName"] = display_name
        if ship_branch is not UNSET:
            field_dict["shipBranch"] = ship_branch
        if ci_context is not UNSET:
            field_dict["ciContext"] = ci_context
        if env_branches is not UNSET:
            field_dict["envBranches"] = env_branches

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.patch_shipr_repos_id_body_env_branches import (
            PatchShiprReposIdBodyEnvBranches,
        )

        d = dict(src_dict)

        def _parse_group_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        group_id = _parse_group_id(d.pop("groupId", UNSET))

        position = d.pop("position", UNSET)

        slug = d.pop("slug", UNSET)

        def _parse_display_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        display_name = _parse_display_name(d.pop("displayName", UNSET))

        ship_branch = d.pop("shipBranch", UNSET)

        ci_context = d.pop("ciContext", UNSET)

        _env_branches = d.pop("envBranches", UNSET)
        env_branches: PatchShiprReposIdBodyEnvBranches | Unset
        if isinstance(_env_branches, Unset):
            env_branches = UNSET
        else:
            env_branches = PatchShiprReposIdBodyEnvBranches.from_dict(_env_branches)

        patch_shipr_repos_id_body = cls(
            group_id=group_id,
            position=position,
            slug=slug,
            display_name=display_name,
            ship_branch=ship_branch,
            ci_context=ci_context,
            env_branches=env_branches,
        )

        patch_shipr_repos_id_body.additional_properties = d
        return patch_shipr_repos_id_body

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
