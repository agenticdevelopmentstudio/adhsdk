from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentKeywordsIdBody")


@_attrs_define
class PutContentKeywordsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        label (str | Unset):
        color (str | Unset):
        description (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    label: str | Unset = UNSET
    color: str | Unset = UNSET
    description: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        label = self.label

        color = self.color

        description = self.description

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if label is not UNSET:
            field_dict["label"] = label
        if color is not UNSET:
            field_dict["color"] = color
        if description is not UNSET:
            field_dict["description"] = description

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        label = d.pop("label", UNSET)

        color = d.pop("color", UNSET)

        description = d.pop("description", UNSET)

        put_content_keywords_id_body = cls(
            ecosystem_id=ecosystem_id,
            label=label,
            color=color,
            description=description,
        )

        return put_content_keywords_id_body
