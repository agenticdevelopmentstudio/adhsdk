from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutTeamTeamsIdBody")


@_attrs_define
class PutTeamTeamsIdBody:
    """
    Attributes:
        owner_kind (str | Unset):
        owner_id (str | Unset):
        slug (str | Unset):
        name (str | Unset):
        description (str | Unset):
    """

    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    slug: str | Unset = UNSET
    name: str | Unset = UNSET
    description: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        owner_kind = self.owner_kind

        owner_id = self.owner_id

        slug = self.slug

        name = self.name

        description = self.description

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if owner_kind is not UNSET:
            field_dict["ownerKind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        owner_kind = d.pop("ownerKind", UNSET)

        owner_id = d.pop("ownerId", UNSET)

        slug = d.pop("slug", UNSET)

        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        put_team_teams_id_body = cls(
            owner_kind=owner_kind,
            owner_id=owner_id,
            slug=slug,
            name=name,
            description=description,
        )

        return put_team_teams_id_body
