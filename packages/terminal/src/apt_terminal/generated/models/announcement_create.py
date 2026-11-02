from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="AnnouncementCreate")


@_attrs_define
class AnnouncementCreate:
    """
    Attributes:
        title (str):
        body (str):
        audience (str | Unset): Reserved for targeting. Stored and echoed back, but fan-out currently reaches every live
            customer of the ecosystem whatever this says — it is not yet an enum, and no value narrows the audience.
            Default: 'all_hub'.
    """

    title: str
    body: str
    audience: str | Unset = "all_hub"
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        body = self.body

        audience = self.audience

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "title": title,
                "body": body,
            }
        )
        if audience is not UNSET:
            field_dict["audience"] = audience

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        title = d.pop("title")

        body = d.pop("body")

        audience = d.pop("audience", UNSET)

        announcement_create = cls(
            title=title,
            body=body,
            audience=audience,
        )

        announcement_create.additional_properties = d
        return announcement_create

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
