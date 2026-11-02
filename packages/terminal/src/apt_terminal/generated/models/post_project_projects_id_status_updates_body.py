from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_project_projects_id_status_updates_body_health import (
    PostProjectProjectsIdStatusUpdatesBodyHealth,
)

T = TypeVar("T", bound="PostProjectProjectsIdStatusUpdatesBody")


@_attrs_define
class PostProjectProjectsIdStatusUpdatesBody:
    """
    Attributes:
        health (PostProjectProjectsIdStatusUpdatesBodyHealth): required WITH the prose: a health with no explanation is
            a colour nobody can act on
        body (str): required WITH the health: prose that moves no dashboard is a comment, not a report
    """

    health: PostProjectProjectsIdStatusUpdatesBodyHealth
    body: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        health = self.health.value

        body = self.body

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "health": health,
                "body": body,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        health = PostProjectProjectsIdStatusUpdatesBodyHealth(d.pop("health"))

        body = d.pop("body")

        post_project_projects_id_status_updates_body = cls(
            health=health,
            body=body,
        )

        post_project_projects_id_status_updates_body.additional_properties = d
        return post_project_projects_id_status_updates_body

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
