from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_program_owner_kind import ProjectProgramOwnerKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="ProjectProgram")


@_attrs_define
class ProjectProgram:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (ProjectProgramOwnerKind): the kind of principal that OWNS the program
        owner_id (str): the owning principal; server-stamped from the verified ?workspace= scope, else the creator
        name (str): unique among the workspace’s live programs
        description (str):
        color (str): hex accent (DB default #007AFF)
        created_at (str):
        updated_at (str):
        is_deleted (bool):
        customer_id (str | Unset): the customer (user) who created the program
        start_date (None | str | Unset): date (YYYY-MM-DD); null is ordinary here, UNLIKE an iteration — a standing
            program ("Platform") has no start, and a delivery program usually knows its target long before one
        target_date (None | str | Unset): date (YYYY-MM-DD); never before startDate
        created_by (None | str | Unset):
        deleted_at (None | str | Unset):
        sync_version (int | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: ProjectProgramOwnerKind
    owner_id: str
    name: str
    description: str
    color: str
    created_at: str
    updated_at: str
    is_deleted: bool
    customer_id: str | Unset = UNSET
    start_date: None | str | Unset = UNSET
    target_date: None | str | Unset = UNSET
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

        color = self.color

        created_at = self.created_at

        updated_at = self.updated_at

        is_deleted = self.is_deleted

        customer_id = self.customer_id

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
                "color": color,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "isDeleted": is_deleted,
            }
        )
        if customer_id is not UNSET:
            field_dict["customerId"] = customer_id
        if start_date is not UNSET:
            field_dict["startDate"] = start_date
        if target_date is not UNSET:
            field_dict["targetDate"] = target_date
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

        owner_kind = ProjectProgramOwnerKind(d.pop("ownerKind"))

        owner_id = d.pop("ownerId")

        name = d.pop("name")

        description = d.pop("description")

        color = d.pop("color")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        is_deleted = d.pop("isDeleted")

        customer_id = d.pop("customerId", UNSET)

        def _parse_start_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        start_date = _parse_start_date(d.pop("startDate", UNSET))

        def _parse_target_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        target_date = _parse_target_date(d.pop("targetDate", UNSET))

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

        project_program = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            name=name,
            description=description,
            color=color,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            customer_id=customer_id,
            start_date=start_date,
            target_date=target_date,
            created_by=created_by,
            deleted_at=deleted_at,
            sync_version=sync_version,
        )

        project_program.additional_properties = d
        return project_program

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
