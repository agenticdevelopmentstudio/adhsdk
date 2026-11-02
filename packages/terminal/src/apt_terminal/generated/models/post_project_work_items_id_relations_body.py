from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_project_work_items_id_relations_body_kind import (
    PostProjectWorkItemsIdRelationsBodyKind,
)

T = TypeVar("T", bound="PostProjectWorkItemsIdRelationsBody")


@_attrs_define
class PostProjectWorkItemsIdRelationsBody:
    """
    Attributes:
        related_id (str): a live work item in the same project (not self; must not already be linked to this one)
        kind (PostProjectWorkItemsIdRelationsBodyKind): which relationship this edge asserts; only depends_on is cycle-
            checked, because only it claims an order
    """

    related_id: str
    kind: PostProjectWorkItemsIdRelationsBodyKind
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        related_id = self.related_id

        kind = self.kind.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "relatedId": related_id,
                "kind": kind,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        related_id = d.pop("relatedId")

        kind = PostProjectWorkItemsIdRelationsBodyKind(d.pop("kind"))

        post_project_work_items_id_relations_body = cls(
            related_id=related_id,
            kind=kind,
        )

        post_project_work_items_id_relations_body.additional_properties = d
        return post_project_work_items_id_relations_body

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
