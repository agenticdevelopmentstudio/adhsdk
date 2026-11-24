from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.team_member_member_kind import TeamMemberMemberKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1TeamMembersResponse200DataItem")


@_attrs_define
class GetV1TeamMembersResponse200DataItem:
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
        object_ (Literal['team_member'] | Unset):
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
    object_: Literal["team_member"] | Unset = UNSET
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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "team_id": team_id,
                "member_kind": member_kind,
                "user_id": user_id,
                "role": role,
                "added_at": added_at,
            }
        )
        if email is not UNSET:
            field_dict["email"] = email
        if display_name is not UNSET:
            field_dict["display_name"] = display_name
        if persona_slug is not UNSET:
            field_dict["persona_slug"] = persona_slug
        if persona_name is not UNSET:
            field_dict["persona_name"] = persona_name
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        team_id = d.pop("team_id")

        member_kind = TeamMemberMemberKind(d.pop("member_kind"))

        user_id = d.pop("user_id")

        role = d.pop("role")

        added_at = d.pop("added_at")

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

        display_name = _parse_display_name(d.pop("display_name", UNSET))

        def _parse_persona_slug(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        persona_slug = _parse_persona_slug(d.pop("persona_slug", UNSET))

        def _parse_persona_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        persona_name = _parse_persona_name(d.pop("persona_name", UNSET))

        object_ = cast(Literal["team_member"] | Unset, d.pop("object", UNSET))
        if object_ != "team_member" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'team_member', got '{object_}'")

        get_v1_team_members_response_200_data_item = cls(
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
            object_=object_,
        )

        get_v1_team_members_response_200_data_item.additional_properties = d
        return get_v1_team_members_response_200_data_item

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
