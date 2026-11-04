from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostContentKeywordsBody")


@_attrs_define
class PostContentKeywordsBody:
    """
    Attributes:
        label (str):
        ecosystem_id (str | Unset):
        color (str | Unset):
        description (str | Unset):
    """

    label: str
    ecosystem_id: str | Unset = UNSET
    color: str | Unset = UNSET
    description: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        label = self.label

        ecosystem_id = self.ecosystem_id

        color = self.color

        description = self.description

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "label": label,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if color is not UNSET:
            field_dict["color"] = color
        if description is not UNSET:
            field_dict["description"] = description

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        label = d.pop("label")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        color = d.pop("color", UNSET)

        description = d.pop("description", UNSET)

        post_content_keywords_body = cls(
            label=label,
            ecosystem_id=ecosystem_id,
            color=color,
            description=description,
        )

        return post_content_keywords_body
