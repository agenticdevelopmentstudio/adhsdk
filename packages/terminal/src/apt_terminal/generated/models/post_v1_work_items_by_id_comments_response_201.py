from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.project_comment_author_kind import ProjectCommentAuthorKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1WorkItemsByIdCommentsResponse201")


@_attrs_define
class PostV1WorkItemsByIdCommentsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        project_id (str):
        work_item_id (str):
        body (str):
        created (int): Unix timestamp, in seconds.
        parent_id (None | str | Unset): the comment this one replies to; null for a top-level comment
        author_kind (ProjectCommentAuthorKind | Unset):
        author_id (None | str | Unset):
        author_label (None | str | Unset):
        edited_at (None | str | Unset): set the first time the body changes; the prior text is in the trail
        updated (int | Unset): Unix timestamp, in seconds.
        object_ (Literal['comment'] | Unset):
    """

    id: str
    ecosystem_id: str
    project_id: str
    work_item_id: str
    body: str
    created: int
    parent_id: None | str | Unset = UNSET
    author_kind: ProjectCommentAuthorKind | Unset = UNSET
    author_id: None | str | Unset = UNSET
    author_label: None | str | Unset = UNSET
    edited_at: None | str | Unset = UNSET
    updated: int | Unset = UNSET
    object_: Literal["comment"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        project_id = self.project_id

        work_item_id = self.work_item_id

        body = self.body

        created = self.created

        parent_id: None | str | Unset
        if isinstance(self.parent_id, Unset):
            parent_id = UNSET
        else:
            parent_id = self.parent_id

        author_kind: str | Unset = UNSET
        if not isinstance(self.author_kind, Unset):
            author_kind = self.author_kind.value

        author_id: None | str | Unset
        if isinstance(self.author_id, Unset):
            author_id = UNSET
        else:
            author_id = self.author_id

        author_label: None | str | Unset
        if isinstance(self.author_label, Unset):
            author_label = UNSET
        else:
            author_label = self.author_label

        edited_at: None | str | Unset
        if isinstance(self.edited_at, Unset):
            edited_at = UNSET
        else:
            edited_at = self.edited_at

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "project_id": project_id,
                "work_item_id": work_item_id,
                "body": body,
                "created": created,
            }
        )
        if parent_id is not UNSET:
            field_dict["parent_id"] = parent_id
        if author_kind is not UNSET:
            field_dict["author_kind"] = author_kind
        if author_id is not UNSET:
            field_dict["author_id"] = author_id
        if author_label is not UNSET:
            field_dict["author_label"] = author_label
        if edited_at is not UNSET:
            field_dict["edited_at"] = edited_at
        if updated is not UNSET:
            field_dict["updated"] = updated
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        project_id = d.pop("project_id")

        work_item_id = d.pop("work_item_id")

        body = d.pop("body")

        created = d.pop("created")

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parent_id", UNSET))

        _author_kind = d.pop("author_kind", UNSET)
        author_kind: ProjectCommentAuthorKind | Unset
        if isinstance(_author_kind, Unset):
            author_kind = UNSET
        else:
            author_kind = ProjectCommentAuthorKind(_author_kind)

        def _parse_author_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_id = _parse_author_id(d.pop("author_id", UNSET))

        def _parse_author_label(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_label = _parse_author_label(d.pop("author_label", UNSET))

        def _parse_edited_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        edited_at = _parse_edited_at(d.pop("edited_at", UNSET))

        updated = d.pop("updated", UNSET)

        object_ = cast(Literal["comment"] | Unset, d.pop("object", UNSET))
        if object_ != "comment" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'comment', got '{object_}'")

        post_v1_work_items_by_id_comments_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            project_id=project_id,
            work_item_id=work_item_id,
            body=body,
            created=created,
            parent_id=parent_id,
            author_kind=author_kind,
            author_id=author_id,
            author_label=author_label,
            edited_at=edited_at,
            updated=updated,
            object_=object_,
        )

        post_v1_work_items_by_id_comments_response_201.additional_properties = d
        return post_v1_work_items_by_id_comments_response_201

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
