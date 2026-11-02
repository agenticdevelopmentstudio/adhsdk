from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.patch_project_projects_id_body_estimate_scale import (
    PatchProjectProjectsIdBodyEstimateScale,
)
from ..models.patch_project_projects_id_body_lead_kind import PatchProjectProjectsIdBodyLeadKind
from ..models.patch_project_projects_id_body_priority_scale import (
    PatchProjectProjectsIdBodyPriorityScale,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PatchProjectProjectsIdBody")


@_attrs_define
class PatchProjectProjectsIdBody:
    """
    Attributes:
        name (str | Unset):
        description (str | Unset):
        status (str | Unset):
        color (str | Unset):
        archived_at (None | str | Unset): an ISO timestamp archives; null un-archives
        estimate_scale (PatchProjectProjectsIdBodyEstimateScale | Unset): which estimate vocabulary this board writes
            in. Changing it NEVER invalidates an estimate already stored — the column takes any non-negative integer
            whatever the scale is — so this is safe to switch mid-flight. 'none' turns estimating off.
        priority_scale (PatchProjectProjectsIdBodyPriorityScale | Unset): whether this board ranks its work. Safe to
            switch for the same reason as the scale above: 'none' hides the priority control and the priority column and
            keeps every rank already recorded, so turning ranking back on restores the order rather than an empty one.
        item_noun (str | Unset): what this board calls ONE of its items, e.g. 'recipe'. Lower case by convention — the
            client capitalises where a sentence needs it, and a stored 'Recipe' would read as 'Delete 3 Recipes'.
        item_noun_plural (str | Unset): what this board calls MANY, e.g. 'recipes'. Accepted on its OWN, unlike in a
            template body: this patch edits words the board already has, so correcting a plural the client guessed
            ('storys') is a real request rather than half a rename.
        key_prefix (str | Unset): the prefix this board's keys render from. Upper-cased before it is checked, so `adh`
            and `ADH` are not two claims on the same prefix; 409 if another live board of the same owner already holds it.
            Renaming it re-renders every key at once — which is why the prefix is stored here and not on each card.
        start_date (None | str | Unset): null clears it — a project that turns out to have no committed start must be
            able to say so again
        target_date (None | str | Unset): null clears it. The pair is checked as it WILL BE, not as it was sent, so
            moving one end of a dated project is an ordinary one-key edit; 400 if the target would precede the start.
        lead_kind (PatchProjectProjectsIdBodyLeadKind | Unset): set WITH leadId, or send both as null to clear. A half —
            a kind naming nobody, or an id with no kind — is a 400 here rather than the projects_lead_kind_chk violation it
            would otherwise become.
        lead_id (None | str | Unset):
        program_id (None | str | Unset): a live program of this project's OWN workspace (400 otherwise — the same
            relational rule a card's iteration follows); null takes the board out of its program
    """

    name: str | Unset = UNSET
    description: str | Unset = UNSET
    status: str | Unset = UNSET
    color: str | Unset = UNSET
    archived_at: None | str | Unset = UNSET
    estimate_scale: PatchProjectProjectsIdBodyEstimateScale | Unset = UNSET
    priority_scale: PatchProjectProjectsIdBodyPriorityScale | Unset = UNSET
    item_noun: str | Unset = UNSET
    item_noun_plural: str | Unset = UNSET
    key_prefix: str | Unset = UNSET
    start_date: None | str | Unset = UNSET
    target_date: None | str | Unset = UNSET
    lead_kind: PatchProjectProjectsIdBodyLeadKind | Unset = UNSET
    lead_id: None | str | Unset = UNSET
    program_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description = self.description

        status = self.status

        color = self.color

        archived_at: None | str | Unset
        if isinstance(self.archived_at, Unset):
            archived_at = UNSET
        else:
            archived_at = self.archived_at

        estimate_scale: str | Unset = UNSET
        if not isinstance(self.estimate_scale, Unset):
            estimate_scale = self.estimate_scale.value

        priority_scale: str | Unset = UNSET
        if not isinstance(self.priority_scale, Unset):
            priority_scale = self.priority_scale.value

        item_noun = self.item_noun

        item_noun_plural = self.item_noun_plural

        key_prefix = self.key_prefix

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

        lead_kind: str | Unset = UNSET
        if not isinstance(self.lead_kind, Unset):
            lead_kind = self.lead_kind.value

        lead_id: None | str | Unset
        if isinstance(self.lead_id, Unset):
            lead_id = UNSET
        else:
            lead_id = self.lead_id

        program_id: None | str | Unset
        if isinstance(self.program_id, Unset):
            program_id = UNSET
        else:
            program_id = self.program_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if status is not UNSET:
            field_dict["status"] = status
        if color is not UNSET:
            field_dict["color"] = color
        if archived_at is not UNSET:
            field_dict["archivedAt"] = archived_at
        if estimate_scale is not UNSET:
            field_dict["estimateScale"] = estimate_scale
        if priority_scale is not UNSET:
            field_dict["priorityScale"] = priority_scale
        if item_noun is not UNSET:
            field_dict["itemNoun"] = item_noun
        if item_noun_plural is not UNSET:
            field_dict["itemNounPlural"] = item_noun_plural
        if key_prefix is not UNSET:
            field_dict["keyPrefix"] = key_prefix
        if start_date is not UNSET:
            field_dict["startDate"] = start_date
        if target_date is not UNSET:
            field_dict["targetDate"] = target_date
        if lead_kind is not UNSET:
            field_dict["leadKind"] = lead_kind
        if lead_id is not UNSET:
            field_dict["leadId"] = lead_id
        if program_id is not UNSET:
            field_dict["programId"] = program_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        status = d.pop("status", UNSET)

        color = d.pop("color", UNSET)

        def _parse_archived_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        archived_at = _parse_archived_at(d.pop("archivedAt", UNSET))

        _estimate_scale = d.pop("estimateScale", UNSET)
        estimate_scale: PatchProjectProjectsIdBodyEstimateScale | Unset
        if isinstance(_estimate_scale, Unset):
            estimate_scale = UNSET
        else:
            estimate_scale = PatchProjectProjectsIdBodyEstimateScale(_estimate_scale)

        _priority_scale = d.pop("priorityScale", UNSET)
        priority_scale: PatchProjectProjectsIdBodyPriorityScale | Unset
        if isinstance(_priority_scale, Unset):
            priority_scale = UNSET
        else:
            priority_scale = PatchProjectProjectsIdBodyPriorityScale(_priority_scale)

        item_noun = d.pop("itemNoun", UNSET)

        item_noun_plural = d.pop("itemNounPlural", UNSET)

        key_prefix = d.pop("keyPrefix", UNSET)

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

        _lead_kind = d.pop("leadKind", UNSET)
        lead_kind: PatchProjectProjectsIdBodyLeadKind | Unset
        if isinstance(_lead_kind, Unset):
            lead_kind = UNSET
        else:
            lead_kind = PatchProjectProjectsIdBodyLeadKind(_lead_kind)

        def _parse_lead_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        lead_id = _parse_lead_id(d.pop("leadId", UNSET))

        def _parse_program_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        program_id = _parse_program_id(d.pop("programId", UNSET))

        patch_project_projects_id_body = cls(
            name=name,
            description=description,
            status=status,
            color=color,
            archived_at=archived_at,
            estimate_scale=estimate_scale,
            priority_scale=priority_scale,
            item_noun=item_noun,
            item_noun_plural=item_noun_plural,
            key_prefix=key_prefix,
            start_date=start_date,
            target_date=target_date,
            lead_kind=lead_kind,
            lead_id=lead_id,
            program_id=program_id,
        )

        patch_project_projects_id_body.additional_properties = d
        return patch_project_projects_id_body

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
