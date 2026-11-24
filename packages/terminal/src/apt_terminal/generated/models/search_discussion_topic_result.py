from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="SearchDiscussionTopicResult")


@_attrs_define
class SearchDiscussionTopicResult:
    """
    Attributes:
        id (str):
        title (str):
        reply_count (int):
        last_activity_at (str):
        created (int): Unix timestamp, in seconds.
        category_id (None | str | Unset):
    """

    id: str
    title: str
    reply_count: int
    last_activity_at: str
    created: int
    category_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        title = self.title

        reply_count = self.reply_count

        last_activity_at = self.last_activity_at

        created = self.created

        category_id: None | str | Unset
        if isinstance(self.category_id, Unset):
            category_id = UNSET
        else:
            category_id = self.category_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "title": title,
                "reply_count": reply_count,
                "last_activity_at": last_activity_at,
                "created": created,
            }
        )
        if category_id is not UNSET:
            field_dict["category_id"] = category_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        title = d.pop("title")

        reply_count = d.pop("reply_count")

        last_activity_at = d.pop("last_activity_at")

        created = d.pop("created")

        def _parse_category_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        category_id = _parse_category_id(d.pop("category_id", UNSET))

        search_discussion_topic_result = cls(
            id=id,
            title=title,
            reply_count=reply_count,
            last_activity_at=last_activity_at,
            created=created,
            category_id=category_id,
        )

        search_discussion_topic_result.additional_properties = d
        return search_discussion_topic_result

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
