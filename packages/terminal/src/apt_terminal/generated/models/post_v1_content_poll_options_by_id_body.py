from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentPollOptionsByIdBody")


@_attrs_define
class PostV1ContentPollOptionsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        poll_id (str | Unset):
        text (str | Unset):
        sort_order (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    poll_id: str | Unset = UNSET
    text: str | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        poll_id = self.poll_id

        text = self.text

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if poll_id is not UNSET:
            field_dict["poll_id"] = poll_id
        if text is not UNSET:
            field_dict["text"] = text
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        poll_id = d.pop("poll_id", UNSET)

        text = d.pop("text", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        post_v1_content_poll_options_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            poll_id=poll_id,
            text=text,
            sort_order=sort_order,
        )

        return post_v1_content_poll_options_by_id_body
