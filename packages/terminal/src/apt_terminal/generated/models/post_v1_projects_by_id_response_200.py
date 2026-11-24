from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_author_kind import ProjectAuthorKind
from ..models.project_estimate_scale import ProjectEstimateScale
from ..models.project_health_type_1 import ProjectHealthType1
from ..models.project_health_type_2_type_1 import ProjectHealthType2Type1
from ..models.project_health_type_3_type_1 import ProjectHealthType3Type1
from ..models.project_lead_kind_type_1 import ProjectLeadKindType1
from ..models.project_lead_kind_type_2_type_1 import ProjectLeadKindType2Type1
from ..models.project_lead_kind_type_3_type_1 import ProjectLeadKindType3Type1
from ..models.project_owner_kind import ProjectOwnerKind
from ..models.project_priority_scale import ProjectPriorityScale
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProjectsByIdResponse200")


@_attrs_define
class PostV1ProjectsByIdResponse200:
    """
    Attributes:
        id (str):
        name (str):
        description (str):
        status (str): lifecycle status (DB default 'active')
        color (str): hex board accent (DB default #007AFF)
        estimate_scale (ProjectEstimateScale): how this board writes estimates (DB default 'none' — the board does not
            estimate). Advisory: it tells a client which picker to render, and constrains nothing the API accepts.
        priority_scale (ProjectPriorityScale): whether this board ranks its work (DB default 'standard'). Advisory in
            the same way: 'none' means render no priority control and no priority column, and the API still accepts and
            returns the 0–4 integer every card already carries.
        item_noun (str): what this board calls ONE of its items, lower-case (DB default 'work item') — the word a client
            puts in 'New …', in an empty state and in a bulk-action count
        item_noun_plural (str): what this board calls MANY of its items (DB default 'work items'). Stored rather than
            derived from itemNoun: English pluralisation is not a rule this API can pretend to know ('story' → 'storys'), so
            the word is the author's.
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        sync_version (int):
        ecosystem_id (str): the owning ecosystem (tenant scope)
        owner_kind (ProjectOwnerKind): the kind of principal that OWNS the project
        owner_id (str): the owning principal (customer or organization id); server-stamped from the verified ?workspace=
            scope, else the creator
        key_prefix (str): the prefix every card's key is rendered from (ADH-42) — 2–8 chars, a letter then letters or
            digits, stored upper-cased and unique among the OWNER's live boards. '' = unassigned (a project predating
            migration 0181, until the backfill reaches it); its cards render an empty key rather than a broken one.
        health (None | ProjectHealthType1 | ProjectHealthType2Type1 | ProjectHealthType3Type1): DERIVED, never stored:
            the health on the NEWEST live status update (GET /project/projects/{id}/status-updates returns it first). null
            means no update has been posted — which is not "on track", and the distinction is the reason this is not a
            column with a default. Retracting the newest update moves it back to the previous one, or to null.
        health_updated_at (None | str): when the update that decided `health` was posted; null exactly when `health` is
            null. A dashboard needs this to say whether a green board is green or merely stale.
        author_kind (ProjectAuthorKind | Unset): Kind of principal that created the project; null when nobody did (a
            storage token).
        author_id (None | str | Unset): Id of that principal.
        deleted_at (None | str | Unset):
        archived_at (None | str | Unset): ISO timestamp when archived; null = not archived
        start_date (None | str | Unset): date (YYYY-MM-DD); null = no committed start
        target_date (None | str | Unset): date (YYYY-MM-DD); never before startDate; null = no committed target
        lead_kind (None | ProjectLeadKindType1 | ProjectLeadKindType2Type1 | ProjectLeadKindType3Type1 | Unset): the
            kind of principal that ANSWERS for the project. Whole or absent: a lead is always a kind AND an id, never half
            of one.
        lead_id (None | str | Unset): set with leadKind (both or neither)
        program_id (None | str | Unset): the program this board rolls up into; null = it stands alone. The program
            belongs to the project's OWNER, so a workspace can group boards without a project ever naming a container
            another workspace runs.
        object_ (Literal['project'] | Unset):
    """

    id: str
    name: str
    description: str
    status: str
    color: str
    estimate_scale: ProjectEstimateScale
    priority_scale: ProjectPriorityScale
    item_noun: str
    item_noun_plural: str
    created: int
    updated: int
    is_deleted: bool
    sync_version: int
    ecosystem_id: str
    owner_kind: ProjectOwnerKind
    owner_id: str
    key_prefix: str
    health: None | ProjectHealthType1 | ProjectHealthType2Type1 | ProjectHealthType3Type1
    health_updated_at: None | str
    author_kind: ProjectAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    archived_at: None | str | Unset = UNSET
    start_date: None | str | Unset = UNSET
    target_date: None | str | Unset = UNSET
    lead_kind: (
        None | ProjectLeadKindType1 | ProjectLeadKindType2Type1 | ProjectLeadKindType3Type1 | Unset
    ) = UNSET
    lead_id: None | str | Unset = UNSET
    program_id: None | str | Unset = UNSET
    object_: Literal["project"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        description = self.description

        status = self.status

        color = self.color

        estimate_scale = self.estimate_scale.value

        priority_scale = self.priority_scale.value

        item_noun = self.item_noun

        item_noun_plural = self.item_noun_plural

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        sync_version = self.sync_version

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        key_prefix = self.key_prefix

        health: None | str
        if (
            isinstance(self.health, ProjectHealthType1)
            or isinstance(self.health, ProjectHealthType2Type1)
            or isinstance(self.health, ProjectHealthType3Type1)
        ):
            health = self.health.value
        else:
            health = self.health

        health_updated_at: None | str
        health_updated_at = self.health_updated_at

        author_kind: str | Unset = UNSET
        if not isinstance(self.author_kind, Unset):
            author_kind = self.author_kind.value

        author_id: None | str | Unset
        if isinstance(self.author_id, Unset):
            author_id = UNSET
        else:
            author_id = self.author_id

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        archived_at: None | str | Unset
        if isinstance(self.archived_at, Unset):
            archived_at = UNSET
        else:
            archived_at = self.archived_at

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

        lead_kind: None | str | Unset
        if isinstance(self.lead_kind, Unset):
            lead_kind = UNSET
        elif (
            isinstance(self.lead_kind, ProjectLeadKindType1)
            or isinstance(self.lead_kind, ProjectLeadKindType2Type1)
            or isinstance(self.lead_kind, ProjectLeadKindType3Type1)
        ):
            lead_kind = self.lead_kind.value
        else:
            lead_kind = self.lead_kind

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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "description": description,
                "status": status,
                "color": color,
                "estimate_scale": estimate_scale,
                "priority_scale": priority_scale,
                "item_noun": item_noun,
                "item_noun_plural": item_noun_plural,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
                "sync_version": sync_version,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "key_prefix": key_prefix,
                "health": health,
                "health_updated_at": health_updated_at,
            }
        )
        if author_kind is not UNSET:
            field_dict["author_kind"] = author_kind
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if archived_at is not UNSET:
            field_dict["archived_at"] = archived_at
        if start_date is not UNSET:
            field_dict["start_date"] = start_date
        if target_date is not UNSET:
            field_dict["target_date"] = target_date
        if lead_kind is not UNSET:
            field_dict["lead_kind"] = lead_kind
        if lead_id is not UNSET:
            field_dict["lead_id"] = lead_id
        if program_id is not UNSET:
            field_dict["program_id"] = program_id
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        description = d.pop("description")

        status = d.pop("status")

        color = d.pop("color")

        estimate_scale = ProjectEstimateScale(d.pop("estimate_scale"))

        priority_scale = ProjectPriorityScale(d.pop("priority_scale"))

        item_noun = d.pop("item_noun")

        item_noun_plural = d.pop("item_noun_plural")

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        sync_version = d.pop("sync_version")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = ProjectOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

        key_prefix = d.pop("key_prefix")

        def _parse_health(
            data: object,
        ) -> None | ProjectHealthType1 | ProjectHealthType2Type1 | ProjectHealthType3Type1:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                health_type_1 = ProjectHealthType1(data)

                return health_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                health_type_2_type_1 = ProjectHealthType2Type1(data)

                return health_type_2_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                health_type_3_type_1 = ProjectHealthType3Type1(data)

                return health_type_3_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                None | ProjectHealthType1 | ProjectHealthType2Type1 | ProjectHealthType3Type1, data
            )

        health = _parse_health(d.pop("health"))

        def _parse_health_updated_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        health_updated_at = _parse_health_updated_at(d.pop("health_updated_at"))

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: ProjectAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = ProjectAuthorKind(_author_kind)

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("author_id", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        def _parse_archived_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        archived_at = _parse_archived_at(d.pop("archived_at", UNSET))

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

        def _parse_lead_kind(
            data: object,
        ) -> (
            None
            | ProjectLeadKindType1
            | ProjectLeadKindType2Type1
            | ProjectLeadKindType3Type1
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                lead_kind_type_1 = ProjectLeadKindType1(data)

                return lead_kind_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                lead_kind_type_2_type_1 = ProjectLeadKindType2Type1(data)

                return lead_kind_type_2_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                lead_kind_type_3_type_1 = ProjectLeadKindType3Type1(data)

                return lead_kind_type_3_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                None
                | ProjectLeadKindType1
                | ProjectLeadKindType2Type1
                | ProjectLeadKindType3Type1
                | Unset,
                data,
            )

        lead_kind = _parse_lead_kind(d.pop("lead_kind", UNSET))

        def _parse_lead_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        lead_id = _parse_lead_id(d.pop("lead_id", UNSET))

        def _parse_program_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        program_id = _parse_program_id(d.pop("program_id", UNSET))

        object_ = cast(Literal["project"] | Unset, d.pop("object", UNSET))
        if object_ != "project" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'project', got '{object_}'")

        post_v1_projects_by_id_response_200 = cls(
            id=id,
            name=name,
            description=description,
            status=status,
            color=color,
            estimate_scale=estimate_scale,
            priority_scale=priority_scale,
            item_noun=item_noun,
            item_noun_plural=item_noun_plural,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            sync_version=sync_version,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            key_prefix=key_prefix,
            health=health,
            health_updated_at=health_updated_at,
            author_kind=author_kind,
            author_id=author_id,
            deleted_at=deleted_at,
            archived_at=archived_at,
            start_date=start_date,
            target_date=target_date,
            lead_kind=lead_kind,
            lead_id=lead_id,
            program_id=program_id,
            object_=object_,
        )

        post_v1_projects_by_id_response_200.additional_properties = d
        return post_v1_projects_by_id_response_200

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
