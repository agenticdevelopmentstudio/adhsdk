from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.put_shipr_org_defaults_org_body_env_branches import (
        PutShiprOrgDefaultsOrgBodyEnvBranches,
    )


T = TypeVar("T", bound="PutShiprOrgDefaultsOrgBody")


@_attrs_define
class PutShiprOrgDefaultsOrgBody:
    """
    Attributes:
        deployment_owner (None | str | Unset):
        name_suffix (str | Unset):
        env_branches (PutShiprOrgDefaultsOrgBodyEnvBranches | Unset):
    """

    deployment_owner: None | str | Unset = UNSET
    name_suffix: str | Unset = UNSET
    env_branches: PutShiprOrgDefaultsOrgBodyEnvBranches | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        deployment_owner: None | str | Unset
        if isinstance(self.deployment_owner, Unset):
            deployment_owner = UNSET
        else:
            deployment_owner = self.deployment_owner

        name_suffix = self.name_suffix

        env_branches: dict[str, Any] | Unset = UNSET
        if not isinstance(self.env_branches, Unset):
            env_branches = self.env_branches.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if deployment_owner is not UNSET:
            field_dict["deploymentOwner"] = deployment_owner
        if name_suffix is not UNSET:
            field_dict["nameSuffix"] = name_suffix
        if env_branches is not UNSET:
            field_dict["envBranches"] = env_branches

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_shipr_org_defaults_org_body_env_branches import (
            PutShiprOrgDefaultsOrgBodyEnvBranches,
        )

        d = dict(src_dict)

        def _parse_deployment_owner(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deployment_owner = _parse_deployment_owner(d.pop("deploymentOwner", UNSET))

        name_suffix = d.pop("nameSuffix", UNSET)

        _env_branches = d.pop("envBranches", UNSET)
        env_branches: PutShiprOrgDefaultsOrgBodyEnvBranches | Unset
        if isinstance(_env_branches, Unset):
            env_branches = UNSET
        else:
            env_branches = PutShiprOrgDefaultsOrgBodyEnvBranches.from_dict(_env_branches)

        put_shipr_org_defaults_org_body = cls(
            deployment_owner=deployment_owner,
            name_suffix=name_suffix,
            env_branches=env_branches,
        )

        put_shipr_org_defaults_org_body.additional_properties = d
        return put_shipr_org_defaults_org_body

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
