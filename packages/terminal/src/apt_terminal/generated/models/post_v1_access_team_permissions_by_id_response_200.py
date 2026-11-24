from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AccessTeamPermissionsByIdResponse200")


@_attrs_define
class PostV1AccessTeamPermissionsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        team_id (str):
        permission (str):
        granted_by (None | str):
        granted_at (str):
        object_ (Literal['access.team_permission'] | Unset):
    """

    id: str
    ecosystem_id: str
    team_id: str
    permission: str
    granted_by: None | str
    granted_at: str
    object_: Literal["access.team_permission"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        team_id = self.team_id

        permission = self.permission

        granted_by: None | str
        granted_by = self.granted_by

        granted_at = self.granted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "team_id": team_id,
                "permission": permission,
                "granted_by": granted_by,
                "granted_at": granted_at,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        team_id = d.pop("team_id")

        permission = d.pop("permission")

        def _parse_granted_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        granted_by = _parse_granted_by(d.pop("granted_by"))

        granted_at = d.pop("granted_at")

        object_ = cast(Literal["access.team_permission"] | Unset, d.pop("object", UNSET))
        if object_ != "access.team_permission" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'access.team_permission', got '{object_}'")

        post_v1_access_team_permissions_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            team_id=team_id,
            permission=permission,
            granted_by=granted_by,
            granted_at=granted_at,
            object_=object_,
        )

        return post_v1_access_team_permissions_by_id_response_200
