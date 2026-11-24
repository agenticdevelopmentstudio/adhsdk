from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_template_author_kind import ProjectTemplateAuthorKind
from ..models.project_template_kind import ProjectTemplateKind
from ..models.project_template_owner_kind import ProjectTemplateOwnerKind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.project_template_body import ProjectTemplateBody
    from ..models.work_item_template_body import WorkItemTemplateBody


T = TypeVar("T", bound="GetV1ProjectTemplatesResponse200DataItem")


@_attrs_define
class GetV1ProjectTemplatesResponse200DataItem:
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        author_kind (ProjectTemplateAuthorKind | Unset): Kind of principal that created the template; null when nobody
            did (a storage token).
        author_id (None | str | Unset): Id of that principal.
        created_by (None | str | Unset):
        deleted_at (None | str | Unset):
        sync_version (int | Unset):
        object_ (Literal['project_template'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: ProjectTemplateOwnerKind
    owner_id: str
    kind: ProjectTemplateKind
    name: str
    description: str
    body: ProjectTemplateBody | WorkItemTemplateBody
    created: int
    updated: int
    is_deleted: bool
    author_kind: ProjectTemplateAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    created_by: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    sync_version: int | Unset = UNSET
    object_: Literal["project_template"] | Unset = UNSET
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

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        author_kind: str | Unset = UNSET
        if not isinstance(self.author_kind, Unset):
            author_kind = self.author_kind.value

        author_id: None | str | Unset
        if isinstance(self.author_id, Unset):
            author_id = UNSET
        else:
            author_id = self.author_id

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
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "kind": kind,
                "name": name,
                "description": description,
                "body": body,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
            }
        )
        if author_kind is not UNSET:
            field_dict["author_kind"] = author_kind
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
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
        from ..models.project_template_body import ProjectTemplateBody
        from ..models.work_item_template_body import WorkItemTemplateBody

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = ProjectTemplateOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

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

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: ProjectTemplateAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = ProjectTemplateAuthorKind(_author_kind)

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("author_id", UNSET))

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

        object_ = cast(Literal["project_template"] | Unset, d.pop("object", UNSET))
        if object_ != "project_template" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'project_template', got '{object_}'")

        get_v1_project_templates_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            kind=kind,
            name=name,
            description=description,
            body=body,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            author_kind=author_kind,
            author_id=author_id,
            created_by=created_by,
            deleted_at=deleted_at,
            sync_version=sync_version,
            object_=object_,
        )

        get_v1_project_templates_response_200_data_item.additional_properties = d
        return get_v1_project_templates_response_200_data_item

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
