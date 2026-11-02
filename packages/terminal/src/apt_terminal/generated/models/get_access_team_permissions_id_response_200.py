from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetAccessTeamPermissionsIdResponse200")


@_attrs_define
class GetAccessTeamPermissionsIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        team_id (str):
        permission (str):
        granted_by (None | str):
        granted_at (str):
    """

    id: str
    ecosystem_id: str
    team_id: str
    permission: str
    granted_by: None | str
    granted_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        team_id = self.team_id

        permission = self.permission

        granted_by: None | str
        granted_by = self.granted_by

        granted_at = self.granted_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "teamId": team_id,
                "permission": permission,
                "grantedBy": granted_by,
                "grantedAt": granted_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        team_id = d.pop("teamId")

        permission = d.pop("permission")

        def _parse_granted_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        granted_by = _parse_granted_by(d.pop("grantedBy"))

        granted_at = d.pop("grantedAt")

        get_access_team_permissions_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            team_id=team_id,
            permission=permission,
            granted_by=granted_by,
            granted_at=granted_at,
        )

        return get_access_team_permissions_id_response_200
