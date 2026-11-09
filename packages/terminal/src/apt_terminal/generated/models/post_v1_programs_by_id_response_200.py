from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_program_author_kind import ProjectProgramAuthorKind
from ..models.project_program_owner_kind import ProjectProgramOwnerKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProgramsByIdResponse200")


@_attrs_define
class PostV1ProgramsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (ProjectProgramOwnerKind): the kind of principal that OWNS the program
        owner_id (str): the owning principal; server-stamped from the verified ?workspace= scope, else the creator
        name (str): unique among the workspace’s live programs
        description (str):
        color (str): hex accent (DB default #007AFF)
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        author_kind (ProjectProgramAuthorKind | Unset): Kind of principal that created the program; null when nobody did
            (a storage token).
        author_id (None | str | Unset): Id of that principal.
        start_date (None | str | Unset): date (YYYY-MM-DD); null is ordinary here, UNLIKE an iteration — a standing
            program ("Platform") has no start, and a delivery program usually knows its target long before one
        target_date (None | str | Unset): date (YYYY-MM-DD); never before startDate
        created_by (None | str | Unset):
        deleted_at (None | str | Unset):
        sync_version (int | Unset):
        object_ (Literal['program'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: ProjectProgramOwnerKind
    owner_id: str
    name: str
    description: str
    color: str
    created: int
    updated: int
    is_deleted: bool
    author_kind: ProjectProgramAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    start_date: None | str | Unset = UNSET
    target_date: None | str | Unset = UNSET
    created_by: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    sync_version: int | Unset = UNSET
    object_: Literal["program"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        name = self.name

        description = self.description

        color = self.color

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

        start_date: None | str | Unset
        if isinstance(self.start_date, Unset):
            start_date = UNSET
        else:
            start_date = self.start_date

        target_date: None | str | Unset
        if isinstance(self.target_date, Unset):
            target_date = UNSET
        else:
            target_date = self.target_date

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
                "name": name,
                "description": description,
                "color": color,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
            }
        )
        if author_kind is not UNSET:
            field_dict["author_kind"] = author_kind
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
        if start_date is not UNSET:
            field_dict["start_date"] = start_date
        if target_date is not UNSET:
            field_dict["target_date"] = target_date
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

        owner_kind = ProjectProgramOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

        name = d.pop("name")

        description = d.pop("description")

        color = d.pop("color")

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: ProjectProgramAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = ProjectProgramAuthorKind(_author_kind)

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("author_id", UNSET))

        def _parse_start_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        start_date = _parse_start_date(d.pop("start_date", UNSET))

        def _parse_target_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        target_date = _parse_target_date(d.pop("target_date", UNSET))

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

        object_ = cast(Literal["program"] | Unset, d.pop("object", UNSET))
        if object_ != "program" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'program', got '{object_}'")

        post_v1_programs_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            name=name,
            description=description,
            color=color,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            author_kind=author_kind,
            author_id=author_id,
            start_date=start_date,
            target_date=target_date,
            created_by=created_by,
            deleted_at=deleted_at,
            sync_version=sync_version,
            object_=object_,
        )

        post_v1_programs_by_id_response_200.additional_properties = d
        return post_v1_programs_by_id_response_200

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
