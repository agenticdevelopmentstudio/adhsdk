from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostTeamMembersPersonasBody")


@_attrs_define
class PostTeamMembersPersonasBody:
    """
    Attributes:
        team_id (str):
        persona_key (str): the persona addressed by its registry key: uuid, persona rdid, or owned-namespace rdid
        role (str | Unset):
    """

    team_id: str
    persona_key: str
    role: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        team_id = self.team_id

        persona_key = self.persona_key

        role = self.role

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "teamId": team_id,
                "personaKey": persona_key,
            }
        )
        if role is not UNSET:
            field_dict["role"] = role

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        team_id = d.pop("teamId")

        persona_key = d.pop("personaKey")

        role = d.pop("role", UNSET)

        post_team_members_personas_body = cls(
            team_id=team_id,
            persona_key=persona_key,
            role=role,
        )

        post_team_members_personas_body.additional_properties = d
        return post_team_members_personas_body

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
