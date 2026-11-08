from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_status_update_health import ProjectStatusUpdateHealth
from ..types import UNSET, Unset

T = TypeVar("T", bound="ProjectStatusUpdate")


@_attrs_define
class ProjectStatusUpdate:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        health (ProjectStatusUpdateHealth): the reported health. The NEWEST live update’s value is what `Project.health`
            returns.
        body (str): the report itself (1–10000 chars)
        created_at (str):
        updated_at (str):
        owner_kind (str | Unset): Kind of principal that owns the status update (inherited from the project):
            'customer', 'organization', 'application', 'persona' or 'ecosystem'.
        owner_id (str | Unset): Id of the owning principal.
        created_by (None | str | Unset): the AUTHOR, as the acting principal — a persona’s report is the persona’s.
            Never re-written: an edit revises the words, it does not change who signed them.
        deleted_at (None | str | Unset):
        sync_version (int | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    health: ProjectStatusUpdateHealth
    body: str
    created_at: str
    updated_at: str
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    created_by: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    sync_version: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        health = self.health.value

        body = self.body

        created_at = self.created_at

        updated_at = self.updated_at

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        created_by: None | str | Unset
        if isinstance(self.created_by, Unset):
            created_by = UNSET
        else:
            created_by = self.created_by

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        sync_version = self.sync_version

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "projectId": project_id,
                "health": health,
                "body": body,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if owner_kind is not UNSET:
            field_dict["ownerKind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if created_by is not UNSET:
            field_dict["createdBy"] = created_by
        if deleted_at is not UNSET:
            field_dict["deletedAt"] = deleted_at
        if sync_version is not UNSET:
            field_dict["syncVersion"] = sync_version

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        project_id = d.pop("projectId")

        health = ProjectStatusUpdateHealth(d.pop("health"))

        body = d.pop("body")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        owner_kind = d.pop("ownerKind", UNSET)

        owner_id = d.pop("ownerId", UNSET)

        def _parse_created_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        created_by = _parse_created_by(d.pop("createdBy", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt", UNSET))

        sync_version = d.pop("syncVersion", UNSET)

        project_status_update = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            health=health,
            body=body,
            created_at=created_at,
            updated_at=updated_at,
            owner_kind=owner_kind,
            owner_id=owner_id,
            created_by=created_by,
            deleted_at=deleted_at,
            sync_version=sync_version,
        )

        project_status_update.additional_properties = d
        return project_status_update

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
