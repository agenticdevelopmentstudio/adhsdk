from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostAccessTeamReachBody")


@_attrs_define
class PostAccessTeamReachBody:
    """
    Attributes:
        ecosystem_id (str): the ecosystem being reached INTO — uuid or `ecosystem.<slug>` rdid
        team_id (str):
        permission (str):
    """

    ecosystem_id: str
    team_id: str
    permission: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        team_id = self.team_id

        permission = self.permission

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystemId": ecosystem_id,
                "teamId": team_id,
                "permission": permission,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId")

        team_id = d.pop("teamId")

        permission = d.pop("permission")

        post_access_team_reach_body = cls(
            ecosystem_id=ecosystem_id,
            team_id=team_id,
            permission=permission,
        )

        post_access_team_reach_body.additional_properties = d
        return post_access_team_reach_body

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
