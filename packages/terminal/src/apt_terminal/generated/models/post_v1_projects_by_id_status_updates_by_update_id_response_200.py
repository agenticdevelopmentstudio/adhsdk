from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_status_update_health import ProjectStatusUpdateHealth
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProjectsByIdStatusUpdatesByUpdateIdResponse200")


@_attrs_define
class PostV1ProjectsByIdStatusUpdatesByUpdateIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        health (ProjectStatusUpdateHealth): the reported health. The NEWEST live update’s value is what `Project.health`
            returns.
        body (str): the report itself (1–10000 chars)
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        owner_kind (str | Unset): Kind of principal that owns the status update (inherited from the project):
            'customer', 'organization', 'application', 'persona' or 'ecosystem'.
        owner_id (str | Unset): Id of the owning principal.
        created_by (None | str | Unset): the AUTHOR, as the acting principal — a persona’s report is the persona’s.
            Never re-written: an edit revises the words, it does not change who signed them.
        deleted_at (None | str | Unset):
        sync_version (int | Unset):
        object_ (Literal['status_update'] | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    health: ProjectStatusUpdateHealth
    body: str
    created: int
    updated: int
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    created_by: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    sync_version: int | Unset = UNSET
    object_: Literal["status_update"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        health = self.health.value

        body = self.body

        created = self.created

        updated = self.updated

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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "health": health,
                "body": body,
                "created": created,
                "updated": updated,
            }
        )
        if owner_kind is not UNSET:
            field_dict["owner_kind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["owner_id"] = owner_id
        if created_by is not UNSET:
            field_dict["created_by"] = created_by
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if sync_version is not UNSET:
            field_dict["sync_version"] = sync_version
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        health = ProjectStatusUpdateHealth(d.pop("health"))

        body = d.pop("body")

        created = d.pop("created")

        updated = d.pop("updated")

        owner_kind = d.pop("owner_kind", UNSET)

        owner_id = d.pop("owner_id", UNSET)

        def _parse_created_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        created_by = _parse_created_by(d.pop("created_by", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        sync_version = d.pop("sync_version", UNSET)

        object_ = cast(Literal["status_update"] | Unset, d.pop("object", UNSET))
        if object_ != "status_update" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'status_update', got '{object_}'")

        post_v1_projects_by_id_status_updates_by_update_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            health=health,
            body=body,
            created=created,
            updated=updated,
            owner_kind=owner_kind,
            owner_id=owner_id,
            created_by=created_by,
            deleted_at=deleted_at,
            sync_version=sync_version,
            object_=object_,
        )

        post_v1_projects_by_id_status_updates_by_update_id_response_200.additional_properties = d
        return post_v1_projects_by_id_status_updates_by_update_id_response_200

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
