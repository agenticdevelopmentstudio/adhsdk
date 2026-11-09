from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.work_item_relation_direction import WorkItemRelationDirection
from ..models.work_item_relation_kind import WorkItemRelationKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1WorkItemsByIdRelationsResponse200DataItem")


@_attrs_define
class GetV1WorkItemsByIdRelationsResponse200DataItem:
    """
    Attributes:
        id (str): the relation edge id
        kind (WorkItemRelationKind):
        direction (WorkItemRelationDirection): outgoing = this item is the subject of the edge (it depends on /
            duplicates the other); incoming = the other item is
        related_id (str): the work item at the far end
        related_key (str): the far item's rendered key (ADH-42); '' when the project has no prefix
        title (str): the far item title (joined)
        status (str): the far item statusId (joined)
        created (int): Unix timestamp, in seconds.
        object_ (Literal['relation'] | Unset):
    """

    id: str
    kind: WorkItemRelationKind
    direction: WorkItemRelationDirection
    related_id: str
    related_key: str
    title: str
    status: str
    created: int
    object_: Literal["relation"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        kind = self.kind.value

        direction = self.direction.value

        related_id = self.related_id

        related_key = self.related_key

        title = self.title

        status = self.status

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "kind": kind,
                "direction": direction,
                "related_id": related_id,
                "related_key": related_key,
                "title": title,
                "status": status,
                "created": created,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        kind = WorkItemRelationKind(d.pop("kind"))

        direction = WorkItemRelationDirection(d.pop("direction"))

        related_id = d.pop("related_id")

        related_key = d.pop("related_key")

        title = d.pop("title")

        status = d.pop("status")

        created = d.pop("created")

        object_ = cast(Literal["relation"] | Unset, d.pop("object", UNSET))
        if object_ != "relation" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'relation', got '{object_}'")

        get_v1_work_items_by_id_relations_response_200_data_item = cls(
            id=id,
            kind=kind,
            direction=direction,
            related_id=related_id,
            related_key=related_key,
            title=title,
            status=status,
            created=created,
            object_=object_,
        )

        get_v1_work_items_by_id_relations_response_200_data_item.additional_properties = d
        return get_v1_work_items_by_id_relations_response_200_data_item

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
