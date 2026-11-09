from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AccessTeamPermissionsBody")


@_attrs_define
class PostV1AccessTeamPermissionsBody:
    """
    Attributes:
        team_id (str):
        permission (str):
        granted_at (str):
        ecosystem_id (str | Unset):
    """

    team_id: str
    permission: str
    granted_at: str
    ecosystem_id: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        team_id = self.team_id

        permission = self.permission

        granted_at = self.granted_at

        ecosystem_id = self.ecosystem_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "team_id": team_id,
                "permission": permission,
                "granted_at": granted_at,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        team_id = d.pop("team_id")

        permission = d.pop("permission")

        granted_at = d.pop("granted_at")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        post_v1_access_team_permissions_body = cls(
            team_id=team_id,
            permission=permission,
            granted_at=granted_at,
            ecosystem_id=ecosystem_id,
        )

        return post_v1_access_team_permissions_body
