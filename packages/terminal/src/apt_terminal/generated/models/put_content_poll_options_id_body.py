from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentPollOptionsIdBody")


@_attrs_define
class PutContentPollOptionsIdBody:
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
            field_dict["ecosystemId"] = ecosystem_id
        if poll_id is not UNSET:
            field_dict["pollId"] = poll_id
        if text is not UNSET:
            field_dict["text"] = text
        if sort_order is not UNSET:
            field_dict["sortOrder"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        poll_id = d.pop("pollId", UNSET)

        text = d.pop("text", UNSET)

        sort_order = d.pop("sortOrder", UNSET)

        put_content_poll_options_id_body = cls(
            ecosystem_id=ecosystem_id,
            poll_id=poll_id,
            text=text,
            sort_order=sort_order,
        )

        return put_content_poll_options_id_body
