from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="SearchDiscussionPostResult")


@_attrs_define
class SearchDiscussionPostResult:
    """
    Attributes:
        id (str):
        topic_id (str):
        post_number (int):
        created (int): Unix timestamp, in seconds.
        rank (float): ts_rank relevance score
        body_document_id (None | str | Unset):
    """

    id: str
    topic_id: str
    post_number: int
    created: int
    rank: float
    body_document_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        topic_id = self.topic_id

        post_number = self.post_number

        created = self.created

        rank = self.rank

        body_document_id: None | str | Unset
        if isinstance(self.body_document_id, Unset):
            body_document_id = UNSET
        else:
            body_document_id = self.body_document_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "topic_id": topic_id,
                "post_number": post_number,
                "created": created,
                "rank": rank,
            }
        )
        if body_document_id is not UNSET:
            field_dict["body_document_id"] = body_document_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        topic_id = d.pop("topic_id")

        post_number = d.pop("post_number")

        created = d.pop("created")

        rank = d.pop("rank")

        def _parse_body_document_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        body_document_id = _parse_body_document_id(d.pop("body_document_id", UNSET))

        search_discussion_post_result = cls(
            id=id,
            topic_id=topic_id,
            post_number=post_number,
            created=created,
            rank=rank,
            body_document_id=body_document_id,
        )

        search_discussion_post_result.additional_properties = d
        return search_discussion_post_result

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
