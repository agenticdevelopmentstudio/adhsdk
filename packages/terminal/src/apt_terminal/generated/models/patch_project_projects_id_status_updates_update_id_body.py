from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.patch_project_projects_id_status_updates_update_id_body_health import (
    PatchProjectProjectsIdStatusUpdatesUpdateIdBodyHealth,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PatchProjectProjectsIdStatusUpdatesUpdateIdBody")


@_attrs_define
class PatchProjectProjectsIdStatusUpdatesUpdateIdBody:
    """At least one field is required (a no-op patch is a 400). AUTHOR ONLY — 403 for anyone else, whatever verbs they hold
    on the project, because a status update carries the reporter’s name.

        Attributes:
            health (PatchProjectProjectsIdStatusUpdatesUpdateIdBodyHealth | Unset):
            body (str | Unset):
    """

    health: PatchProjectProjectsIdStatusUpdatesUpdateIdBodyHealth | Unset = UNSET
    body: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        health: str | Unset = UNSET
        if not isinstance(self.health, Unset):
            health = self.health.value

        body = self.body

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if health is not UNSET:
            field_dict["health"] = health
        if body is not UNSET:
            field_dict["body"] = body

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        _health = d.pop("health", UNSET)
        health: PatchProjectProjectsIdStatusUpdatesUpdateIdBodyHealth | Unset
        if isinstance(_health, Unset):
            health = UNSET
        else:
            health = PatchProjectProjectsIdStatusUpdatesUpdateIdBodyHealth(_health)

        body = d.pop("body", UNSET)

        patch_project_projects_id_status_updates_update_id_body = cls(
            health=health,
            body=body,
        )

        patch_project_projects_id_status_updates_update_id_body.additional_properties = d
        return patch_project_projects_id_status_updates_update_id_body

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
