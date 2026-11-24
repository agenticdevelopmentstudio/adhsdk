from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AccessTeamReachResponse200DataItem")


@_attrs_define
class GetV1AccessTeamReachResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str): the canonical uuid of the ecosystem reached INTO (never the rdid form)
        team_id (str):
        permission (str): free-form permission key (max 100 chars)
        granted_at (str):
        granted_by (None | str | Unset): the user who granted it; null for rows seeded outside this route
        team_name (None | str | Unset):
        team_slug (None | str | Unset):
        object_ (Literal['access.team_reach'] | Unset):
    """

    id: str
    ecosystem_id: str
    team_id: str
    permission: str
    granted_at: str
    granted_by: None | str | Unset = UNSET
    team_name: None | str | Unset = UNSET
    team_slug: None | str | Unset = UNSET
    object_: Literal["access.team_reach"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        team_id = self.team_id

        permission = self.permission

        granted_at = self.granted_at

        granted_by: None | str | Unset
        if isinstance(self.granted_by, Unset):
            granted_by = UNSET
        else:
            granted_by = self.granted_by

        team_name: None | str | Unset
        if isinstance(self.team_name, Unset):
            team_name = UNSET
        else:
            team_name = self.team_name

        team_slug: None | str | Unset
        if isinstance(self.team_slug, Unset):
            team_slug = UNSET
        else:
            team_slug = self.team_slug

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "team_id": team_id,
                "permission": permission,
                "granted_at": granted_at,
            }
        )
        if granted_by is not UNSET:
            field_dict["granted_by"] = granted_by
        if team_name is not UNSET:
            field_dict["team_name"] = team_name
        if team_slug is not UNSET:
            field_dict["team_slug"] = team_slug
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

        granted_at = d.pop("granted_at")

        def _parse_granted_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        granted_by = _parse_granted_by(d.pop("granted_by", UNSET))

        def _parse_team_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        team_name = _parse_team_name(d.pop("team_name", UNSET))

        def _parse_team_slug(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        team_slug = _parse_team_slug(d.pop("team_slug", UNSET))

        object_ = cast(Literal["access.team_reach"] | Unset, d.pop("object", UNSET))
        if object_ != "access.team_reach" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'access.team_reach', got '{object_}'")

        get_v1_access_team_reach_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            team_id=team_id,
            permission=permission,
            granted_at=granted_at,
            granted_by=granted_by,
            team_name=team_name,
            team_slug=team_slug,
            object_=object_,
        )

        get_v1_access_team_reach_response_200_data_item.additional_properties = d
        return get_v1_access_team_reach_response_200_data_item

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
