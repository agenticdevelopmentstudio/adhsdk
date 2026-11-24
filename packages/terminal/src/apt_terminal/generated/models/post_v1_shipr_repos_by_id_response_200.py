from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.shipr_repo_env_branches import ShiprRepoEnvBranches
    from ..models.shipr_repo_provisioned_type_0 import ShiprRepoProvisionedType0


T = TypeVar("T", bound="PostV1ShiprReposByIdResponse200")


@_attrs_define
class PostV1ShiprReposByIdResponse200:
    """
    Attributes:
        id (str | Unset):
        dev_repo_id (str | Unset):
        group_id (None | str | Unset):
        slug (str | Unset): owner/name on the forge.
        shard (str | Unset):
        ship_branch (str | Unset):
        env_branches (ShiprRepoEnvBranches | Unset): environment → branch. An environment absent here is one this
            repository does not deploy to, and its ladder column is not drawn.
        registered_at (None | str | Unset):
        provisioned (None | ShiprRepoProvisionedType0 | Unset):
        position (int | Unset):
        object_ (Literal['shipr.repo'] | Unset):
    """

    id: str | Unset = UNSET
    dev_repo_id: str | Unset = UNSET
    group_id: None | str | Unset = UNSET
    slug: str | Unset = UNSET
    shard: str | Unset = UNSET
    ship_branch: str | Unset = UNSET
    env_branches: ShiprRepoEnvBranches | Unset = UNSET
    registered_at: None | str | Unset = UNSET
    provisioned: None | ShiprRepoProvisionedType0 | Unset = UNSET
    position: int | Unset = UNSET
    object_: Literal["shipr.repo"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.shipr_repo_provisioned_type_0 import ShiprRepoProvisionedType0

        id = self.id

        dev_repo_id = self.dev_repo_id

        group_id: None | str | Unset
        if isinstance(self.group_id, Unset):
            group_id = UNSET
        else:
            group_id = self.group_id

        slug = self.slug

        shard = self.shard

        ship_branch = self.ship_branch

        env_branches: dict[str, Any] | Unset = UNSET
        if not isinstance(self.env_branches, Unset):
            env_branches = self.env_branches.to_dict()

        registered_at: None | str | Unset
        if isinstance(self.registered_at, Unset):
            registered_at = UNSET
        else:
            registered_at = self.registered_at

        provisioned: dict[str, Any] | None | Unset
        if isinstance(self.provisioned, Unset):
            provisioned = UNSET
        elif isinstance(self.provisioned, ShiprRepoProvisionedType0):
            provisioned = self.provisioned.to_dict()
        else:
            provisioned = self.provisioned

        position = self.position

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if dev_repo_id is not UNSET:
            field_dict["dev_repo_id"] = dev_repo_id
        if group_id is not UNSET:
            field_dict["group_id"] = group_id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if shard is not UNSET:
            field_dict["shard"] = shard
        if ship_branch is not UNSET:
            field_dict["ship_branch"] = ship_branch
        if env_branches is not UNSET:
            field_dict["env_branches"] = env_branches
        if registered_at is not UNSET:
            field_dict["registered_at"] = registered_at
        if provisioned is not UNSET:
            field_dict["provisioned"] = provisioned
        if position is not UNSET:
            field_dict["position"] = position
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.shipr_repo_env_branches import ShiprRepoEnvBranches
        from ..models.shipr_repo_provisioned_type_0 import (
            ShiprRepoProvisionedType0,
        )

        d = dict(src_dict)
        id = d.pop("id", UNSET)

        dev_repo_id = d.pop("dev_repo_id", UNSET)

        def _parse_group_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        group_id = _parse_group_id(d.pop("group_id", UNSET))

        slug = d.pop("slug", UNSET)

        shard = d.pop("shard", UNSET)

        ship_branch = d.pop("ship_branch", UNSET)

        _env_branches = d.pop("env_branches", UNSET)
        env_branches: ShiprRepoEnvBranches | Unset
        if isinstance(_env_branches, Unset):
            env_branches = UNSET
        else:
            env_branches = ShiprRepoEnvBranches.from_dict(_env_branches)

        def _parse_registered_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        registered_at = _parse_registered_at(d.pop("registered_at", UNSET))

        def _parse_provisioned(data: object) -> None | ShiprRepoProvisionedType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                provisioned_type_0 = ShiprRepoProvisionedType0.from_dict(data)

                return provisioned_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ShiprRepoProvisionedType0 | Unset, data)

        provisioned = _parse_provisioned(d.pop("provisioned", UNSET))

        position = d.pop("position", UNSET)

        object_ = cast(Literal["shipr.repo"] | Unset, d.pop("object", UNSET))
        if object_ != "shipr.repo" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'shipr.repo', got '{object_}'")

        post_v1_shipr_repos_by_id_response_200 = cls(
            id=id,
            dev_repo_id=dev_repo_id,
            group_id=group_id,
            slug=slug,
            shard=shard,
            ship_branch=ship_branch,
            env_branches=env_branches,
            registered_at=registered_at,
            provisioned=provisioned,
            position=position,
            object_=object_,
        )

        post_v1_shipr_repos_by_id_response_200.additional_properties = d
        return post_v1_shipr_repos_by_id_response_200

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
