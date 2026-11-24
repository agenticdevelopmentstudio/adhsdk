from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.project_activity_detail_type_0 import ProjectActivityDetailType0


T = TypeVar("T", bound="GetV1WorkItemsByIdActivityResponse200DataItem")


@_attrs_define
class GetV1WorkItemsByIdActivityResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        action (str): the event, e.g. project.created/updated/deleted, status.*, participant.*,
            work_item.created/updated/status_changed/assigned/iteration_changed/deleted, comment.added/edited/deleted.
            Iteration CRUD itself appends nothing — this table is FK-bound to a project and an iteration has none — but
            committing a card to a box writes work_item.iteration_changed on that card's project, which is where the history
            is legible.
        created (int): Unix timestamp, in seconds.
        work_item_id (None | str | Unset): set when the event is card-scoped
        actor_kind (None | str | Unset):
        actor_id (None | str | Unset):
        actor_label (None | str | Unset):
        detail (None | ProjectActivityDetailType0 | Unset): action-specific payload (jsonb)
        object_ (Literal['work_item'] | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    action: str
    created: int
    work_item_id: None | str | Unset = UNSET
    actor_kind: None | str | Unset = UNSET
    actor_id: None | str | Unset = UNSET
    actor_label: None | str | Unset = UNSET
    detail: None | ProjectActivityDetailType0 | Unset = UNSET
    object_: Literal["work_item"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.project_activity_detail_type_0 import (
            ProjectActivityDetailType0,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        action = self.action

        created = self.created

        work_item_id: None | str | Unset
        if isinstance(self.work_item_id, Unset):
            work_item_id = UNSET
        else:
            work_item_id = self.work_item_id

        actor_kind: None | str | Unset
        if isinstance(self.actor_kind, Unset):
            actor_kind = UNSET
        else:
            actor_kind = self.actor_kind

        actor_id: None | str | Unset
        if isinstance(self.actor_id, Unset):
            actor_id = UNSET
        else:
            actor_id = self.actor_id

        actor_label: None | str | Unset
        if isinstance(self.actor_label, Unset):
            actor_label = UNSET
        else:
            actor_label = self.actor_label

        detail: dict[str, Any] | None | Unset
        if isinstance(self.detail, Unset):
            detail = UNSET
        elif isinstance(self.detail, ProjectActivityDetailType0):
            detail = self.detail.to_dict()
        else:
            detail = self.detail

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "action": action,
                "created": created,
            }
        )
        if work_item_id is not UNSET:
            field_dict["work_item_id"] = work_item_id
        if actor_kind is not UNSET:
            field_dict["actor_kind"] = actor_kind
        if actor_id is not UNSET:
            field_dict["actor_id"] = actor_id
        if actor_label is not UNSET:
            field_dict["actor_label"] = actor_label
        if detail is not UNSET:
            field_dict["detail"] = detail
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.project_activity_detail_type_0 import (
            ProjectActivityDetailType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        action = d.pop("action")

        created = d.pop("created")

        def _parse_work_item_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        work_item_id = _parse_work_item_id(d.pop("work_item_id", UNSET))

        def _parse_actor_kind(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        actor_kind = _parse_actor_kind(d.pop("actor_kind", UNSET))

        def _parse_actor_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        actor_id = _parse_actor_id(d.pop("actor_id", UNSET))

        def _parse_actor_label(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        actor_label = _parse_actor_label(d.pop("actor_label", UNSET))

        def _parse_detail(data: object) -> None | ProjectActivityDetailType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                detail_type_0 = ProjectActivityDetailType0.from_dict(data)

                return detail_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ProjectActivityDetailType0 | Unset, data)

        detail = _parse_detail(d.pop("detail", UNSET))

        object_ = cast(Literal["work_item"] | Unset, d.pop("object", UNSET))
        if object_ != "work_item" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'work_item', got '{object_}'")

        get_v1_work_items_by_id_activity_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            action=action,
            created=created,
            work_item_id=work_item_id,
            actor_kind=actor_kind,
            actor_id=actor_id,
            actor_label=actor_label,
            detail=detail,
            object_=object_,
        )

        get_v1_work_items_by_id_activity_response_200_data_item.additional_properties = d
        return get_v1_work_items_by_id_activity_response_200_data_item

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
