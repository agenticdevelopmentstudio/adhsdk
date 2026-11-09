from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AccessTeamPermissionsByIdBody")


@_attrs_define
class PostV1AccessTeamPermissionsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        team_id (str | Unset):
        permission (str | Unset):
        granted_at (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    team_id: str | Unset = UNSET
    permission: str | Unset = UNSET
    granted_at: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        team_id = self.team_id

        permission = self.permission

        granted_at = self.granted_at

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if team_id is not UNSET:
            field_dict["team_id"] = team_id
        if permission is not UNSET:
            field_dict["permission"] = permission
        if granted_at is not UNSET:
            field_dict["granted_at"] = granted_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        team_id = d.pop("team_id", UNSET)

        permission = d.pop("permission", UNSET)

        granted_at = d.pop("granted_at", UNSET)

        post_v1_access_team_permissions_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            team_id=team_id,
            permission=permission,
            granted_at=granted_at,
        )

        return post_v1_access_team_permissions_by_id_body
