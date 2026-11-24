from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_work_items_by_id_relations_response_201_kind import (
    PostV1WorkItemsByIdRelationsResponse201Kind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1WorkItemsByIdRelationsResponse201")


@_attrs_define
class PostV1WorkItemsByIdRelationsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        work_item_id (str): the subject item (the path {id})
        depends_on_id (str): the object item — read as a prerequisite only for kind depends_on
        kind (PostV1WorkItemsByIdRelationsResponse201Kind):
        created (int): Unix timestamp, in seconds.
        object_ (Literal['relation'] | Unset):
    """

    id: str
    ecosystem_id: str
    work_item_id: str
    depends_on_id: str
    kind: PostV1WorkItemsByIdRelationsResponse201Kind
    created: int
    object_: Literal["relation"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        work_item_id = self.work_item_id

        depends_on_id = self.depends_on_id

        kind = self.kind.value

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "work_item_id": work_item_id,
                "depends_on_id": depends_on_id,
                "kind": kind,
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

        ecosystem_id = d.pop("ecosystem_id")

        work_item_id = d.pop("work_item_id")

        depends_on_id = d.pop("depends_on_id")

        kind = PostV1WorkItemsByIdRelationsResponse201Kind(d.pop("kind"))

        created = d.pop("created")

        object_ = cast(Literal["relation"] | Unset, d.pop("object", UNSET))
        if object_ != "relation" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'relation', got '{object_}'")

        post_v1_work_items_by_id_relations_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            work_item_id=work_item_id,
            depends_on_id=depends_on_id,
            kind=kind,
            created=created,
            object_=object_,
        )

        post_v1_work_items_by_id_relations_response_201.additional_properties = d
        return post_v1_work_items_by_id_relations_response_201

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
