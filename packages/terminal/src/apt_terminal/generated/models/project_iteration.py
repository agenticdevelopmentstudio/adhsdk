from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_iteration_owner_kind import ProjectIterationOwnerKind
from ..models.project_iteration_state import ProjectIterationState
from ..types import UNSET, Unset

T = TypeVar("T", bound="ProjectIteration")


@_attrs_define
class ProjectIteration:
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
        created_at (str):
        updated_at (str):
        is_deleted (bool):
        customer_id (str | Unset): the customer (user) who created the iteration
        created_by (None | str | Unset):
        deleted_at (None | str | Unset):
        sync_version (int | Unset):
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
    created_at: str
    updated_at: str
    is_deleted: bool
    customer_id: str | Unset = UNSET
    created_by: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    sync_version: int | Unset = UNSET
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
                "name": name,
                "description": description,
                "startDate": start_date,
                "endDate": end_date,
                "state": state,
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
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = ProjectIterationOwnerKind(d.pop("ownerKind"))

        owner_id = d.pop("ownerId")

        name = d.pop("name")

        description = d.pop("description")

        start_date = d.pop("startDate")

        end_date = d.pop("endDate")

        state = ProjectIterationState(d.pop("state"))

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

        project_iteration = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            name=name,
            description=description,
            start_date=start_date,
            end_date=end_date,
            state=state,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            customer_id=customer_id,
            created_by=created_by,
            deleted_at=deleted_at,
            sync_version=sync_version,
        )

        project_iteration.additional_properties = d
        return project_iteration

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
