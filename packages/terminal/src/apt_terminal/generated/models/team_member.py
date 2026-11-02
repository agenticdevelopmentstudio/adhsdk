from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.team_member_member_kind import TeamMemberMemberKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="TeamMember")


@_attrs_define
class TeamMember:
    """
    Attributes:
        id (str):
        team_id (str):
        member_kind (TeamMemberMemberKind): which principal userId names — 'customer' (customer.customers) or 'persona'
            (persona.personas). Present on every response: GET list rows, the add-persona 201, and the by-email add 201
            (always a customer).
        user_id (str): the member principal id — a customer id, or a persona id when memberKind is 'persona'
        role (str):
        added_at (str):
        email (None | str | Unset): the member's email (resolved; null for a persona member or a foreign customer)
        display_name (None | str | Unset):
        persona_slug (None | str | Unset): the persona's slug when memberKind is 'persona' (null for a customer member)
        persona_name (None | str | Unset):
    """

    id: str
    team_id: str
    member_kind: TeamMemberMemberKind
    user_id: str
    role: str
    added_at: str
    email: None | str | Unset = UNSET
    display_name: None | str | Unset = UNSET
    persona_slug: None | str | Unset = UNSET
    persona_name: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        team_id = self.team_id

        member_kind = self.member_kind.value

        user_id = self.user_id

        role = self.role

        added_at = self.added_at

        email: None | str | Unset
        if isinstance(self.email, Unset):
            email = UNSET
        else:
            email = self.email

        display_name: None | str | Unset
        if isinstance(self.display_name, Unset):
            display_name = UNSET
        else:
            display_name = self.display_name

        persona_slug: None | str | Unset
        if isinstance(self.persona_slug, Unset):
            persona_slug = UNSET
        else:
            persona_slug = self.persona_slug

        persona_name: None | str | Unset
        if isinstance(self.persona_name, Unset):
            persona_name = UNSET
        else:
            persona_name = self.persona_name

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "teamId": team_id,
                "memberKind": member_kind,
                "userId": user_id,
                "role": role,
                "addedAt": added_at,
            }
        )
        if email is not UNSET:
            field_dict["email"] = email
        if display_name is not UNSET:
            field_dict["displayName"] = display_name
        if persona_slug is not UNSET:
            field_dict["personaSlug"] = persona_slug
        if persona_name is not UNSET:
            field_dict["personaName"] = persona_name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        team_id = d.pop("teamId")

        member_kind = TeamMemberMemberKind(d.pop("memberKind"))

        user_id = d.pop("userId")

        role = d.pop("role")

        added_at = d.pop("addedAt")

        def _parse_email(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        email = _parse_email(d.pop("email", UNSET))

        def _parse_display_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        display_name = _parse_display_name(d.pop("displayName", UNSET))

        def _parse_persona_slug(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        persona_slug = _parse_persona_slug(d.pop("personaSlug", UNSET))

        def _parse_persona_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        persona_name = _parse_persona_name(d.pop("personaName", UNSET))

        team_member = cls(
            id=id,
            team_id=team_id,
            member_kind=member_kind,
            user_id=user_id,
            role=role,
            added_at=added_at,
            email=email,
            display_name=display_name,
            persona_slug=persona_slug,
            persona_name=persona_name,
        )

        team_member.additional_properties = d
        return team_member

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
