from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_template_kind import ProjectTemplateKind
from ..models.project_template_owner_kind import ProjectTemplateOwnerKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.project_template_body import ProjectTemplateBody
    from ..models.work_item_template_body import WorkItemTemplateBody


T = TypeVar("T", bound="ProjectTemplate")


@_attrs_define
class ProjectTemplate:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (ProjectTemplateOwnerKind): the kind of principal that OWNS the template
        owner_id (str): the owning principal; server-stamped from the verified ?workspace= scope, else the creator
        kind (ProjectTemplateKind): what this template MAKES, and therefore which schema its `body` is read against.
            Immutable — a PATCH cannot re-kind a template, because that would silently re-interpret a stored body against a
            schema it was never written for.
        name (str): unique among the workspace’s live templates OF THIS KIND
        description (str):
        body (ProjectTemplateBody | WorkItemTemplateBody): the stored shape, read against `kind`
        created_at (str):
        updated_at (str):
        is_deleted (bool):
        customer_id (str | Unset): the customer (user) who created the template
        created_by (None | str | Unset):
        deleted_at (None | str | Unset):
        sync_version (int | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: ProjectTemplateOwnerKind
    owner_id: str
    kind: ProjectTemplateKind
    name: str
    description: str
    body: ProjectTemplateBody | WorkItemTemplateBody
    created_at: str
    updated_at: str
    is_deleted: bool
    customer_id: str | Unset = UNSET
    created_by: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    sync_version: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.work_item_template_body import WorkItemTemplateBody

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        kind = self.kind.value

        name = self.name

        description = self.description

        body: dict[str, Any]
        if isinstance(self.body, WorkItemTemplateBody):
            body = self.body.to_dict()
        else:
            body = self.body.to_dict()

        created_at = self.created_at

        updated_at = self.updated_at

        is_deleted = self.is_deleted

        customer_id = self.customer_id

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
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "kind": kind,
                "name": name,
                "description": description,
                "body": body,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "isDeleted": is_deleted,
            }
        )
        if customer_id is not UNSET:
            field_dict["customerId"] = customer_id
        if created_by is not UNSET:
            field_dict["createdBy"] = created_by
        if deleted_at is not UNSET:
            field_dict["deletedAt"] = deleted_at
        if sync_version is not UNSET:
            field_dict["syncVersion"] = sync_version

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.project_template_body import ProjectTemplateBody
        from ..models.work_item_template_body import WorkItemTemplateBody

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = ProjectTemplateOwnerKind(d.pop("ownerKind"))

        owner_id = d.pop("ownerId")

        kind = ProjectTemplateKind(d.pop("kind"))

        name = d.pop("name")

        description = d.pop("description")

        def _parse_body(data: object) -> ProjectTemplateBody | WorkItemTemplateBody:
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                body_type_0 = WorkItemTemplateBody.from_dict(data)

                return body_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            if not isinstance(data, dict):
                raise TypeError()
            body_type_1 = ProjectTemplateBody.from_dict(data)

            return body_type_1

        body = _parse_body(d.pop("body"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        is_deleted = d.pop("isDeleted")

        customer_id = d.pop("customerId", UNSET)

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

        project_template = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            kind=kind,
            name=name,
            description=description,
            body=body,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            customer_id=customer_id,
            created_by=created_by,
            deleted_at=deleted_at,
            sync_version=sync_version,
        )

        project_template.additional_properties = d
        return project_template

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
