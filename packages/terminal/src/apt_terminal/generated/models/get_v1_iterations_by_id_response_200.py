from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_iteration_author_kind import ProjectIterationAuthorKind
from ..models.project_iteration_owner_kind import ProjectIterationOwnerKind
from ..models.project_iteration_state import ProjectIterationState
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1IterationsByIdResponse200")


@_attrs_define
class GetV1IterationsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (ProjectIterationOwnerKind): the kind of principal that OWNS the time-box
        owner_id (str): the owning principal; server-stamped from the verified ?workspace= scope, else the creator
        name (str): unique among the workspace’s live iterations
        description (str):
        start_date (str): date (YYYY-MM-DD), inclusive
        end_date (str): date (YYYY-MM-DD), inclusive; never before startDate
        state (ProjectIterationState): derived from startDate/endDate against today (UTC), inclusive at both ends:
            upcoming before the box opens, active within it, completed after
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        author_kind (ProjectIterationAuthorKind | Unset): Kind of principal that created the iteration; null when nobody
            did (a storage token).
        author_id (None | str | Unset): Id of that principal.
        created_by (None | str | Unset):
        deleted_at (None | str | Unset):
        sync_version (int | Unset):
        object_ (Literal['iteration'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: ProjectIterationOwnerKind
    owner_id: str
    name: str
    description: str
    start_date: str
    end_date: str
    state: ProjectIterationState
    created: int
    updated: int
    is_deleted: bool
    author_kind: ProjectIterationAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    created_by: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    sync_version: int | Unset = UNSET
    object_: Literal["iteration"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        name = self.name

        description = self.description

        start_date = self.start_date

        end_date = self.end_date

        state = self.state.value

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
                "name": name,
                "description": description,
                "start_date": start_date,
                "end_date": end_date,
                "state": state,
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
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = ProjectIterationOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

        name = d.pop("name")

        description = d.pop("description")

        start_date = d.pop("start_date")

        end_date = d.pop("end_date")

        state = ProjectIterationState(d.pop("state"))

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: ProjectIterationAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = ProjectIterationAuthorKind(_author_kind)

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

        object_ = cast(Literal["iteration"] | Unset, d.pop("object", UNSET))
        if object_ != "iteration" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'iteration', got '{object_}'")

        get_v1_iterations_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            name=name,
            description=description,
            start_date=start_date,
            end_date=end_date,
            state=state,
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

        get_v1_iterations_by_id_response_200.additional_properties = d
        return get_v1_iterations_by_id_response_200

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
