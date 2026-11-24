from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.project_milestone_counts import ProjectMilestoneCounts


T = TypeVar("T", bound="ProjectMilestone")


@_attrs_define
class ProjectMilestone:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        name (str): unique among the project’s live milestones
        description (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        owner_kind (str | Unset): Kind of principal that owns the milestone (inherited from the project): 'customer',
            'organization', 'application', 'persona' or 'ecosystem'.
        owner_id (str | Unset): Id of the owning principal.
        target_date (None | str | Unset): date (YYYY-MM-DD); null = undated, an ordinary state — an ordered-but-undated
            plan is a real thing, and requiring a date would only get one invented. Undated milestones sort LAST.
        counts (ProjectMilestoneCounts | Unset): the milestone’s live cards counted by status CATEGORY, every category
            present (0 included) so a client never has to distinguish an absent key from an empty column. DERIVED on every
            read, never stored. The API deliberately reports no percentage: whether a `canceled` card belongs in the
            denominator is a product question, and answering it here would freeze one answer into the wire format.
        created_by (None | str | Unset):
        deleted_at (None | str | Unset):
        sync_version (int | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    name: str
    description: str
    created: int
    updated: int
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    target_date: None | str | Unset = UNSET
    counts: ProjectMilestoneCounts | Unset = UNSET
    created_by: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    sync_version: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        name = self.name

        description = self.description

        created = self.created

        updated = self.updated

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        target_date: None | str | Unset
        if isinstance(self.target_date, Unset):
            target_date = UNSET
        else:
            target_date = self.target_date

        counts: dict[str, Any] | Unset = UNSET
        if not isinstance(self.counts, Unset):
            counts = self.counts.to_dict()

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
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "name": name,
                "description": description,
                "created": created,
                "updated": updated,
            }
        )
        if owner_kind is not UNSET:
            field_dict["owner_kind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["owner_id"] = owner_id
        if target_date is not UNSET:
            field_dict["target_date"] = target_date
        if counts is not UNSET:
            field_dict["counts"] = counts
        if created_by is not UNSET:
            field_dict["created_by"] = created_by
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if sync_version is not UNSET:
            field_dict["sync_version"] = sync_version

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.project_milestone_counts import ProjectMilestoneCounts

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        name = d.pop("name")

        description = d.pop("description")

        created = d.pop("created")

        updated = d.pop("updated")

        owner_kind = d.pop("owner_kind", UNSET)

        owner_id = d.pop("owner_id", UNSET)

        def _parse_target_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        target_date = _parse_target_date(d.pop("target_date", UNSET))

        _counts = d.pop("counts", UNSET)
        counts: ProjectMilestoneCounts | Unset
        if isinstance(_counts, Unset):
            counts = UNSET
        else:
            counts = ProjectMilestoneCounts.from_dict(_counts)

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

        project_milestone = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            name=name,
            description=description,
            created=created,
            updated=updated,
            owner_kind=owner_kind,
            owner_id=owner_id,
            target_date=target_date,
            counts=counts,
            created_by=created_by,
            deleted_at=deleted_at,
            sync_version=sync_version,
        )

        project_milestone.additional_properties = d
        return project_milestone

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
