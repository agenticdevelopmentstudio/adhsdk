from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentPollOptionsBody")


@_attrs_define
class PostV1ContentPollOptionsBody:
    """
    Attributes:
        poll_id (str):
        text (str):
        ecosystem_id (str | Unset):
        sort_order (int | Unset):
    """

    poll_id: str
    text: str
    ecosystem_id: str | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        poll_id = self.poll_id

        text = self.text

        ecosystem_id = self.ecosystem_id

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "poll_id": poll_id,
                "text": text,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        poll_id = d.pop("poll_id")

        text = d.pop("text")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        post_v1_content_poll_options_body = cls(
            poll_id=poll_id,
            text=text,
            ecosystem_id=ecosystem_id,
            sort_order=sort_order,
        )

        return post_v1_content_poll_options_body
