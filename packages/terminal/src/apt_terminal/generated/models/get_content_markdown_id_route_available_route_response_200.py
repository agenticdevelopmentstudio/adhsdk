from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_content_markdown_id_route_available_route_response_200_reason import (
    GetContentMarkdownIdRouteAvailableRouteResponse200Reason,
)

T = TypeVar("T", bound="GetContentMarkdownIdRouteAvailableRouteResponse200")


@_attrs_define
class GetContentMarkdownIdRouteAvailableRouteResponse200:
    """
    Attributes:
        available (bool):
        reason (GetContentMarkdownIdRouteAvailableRouteResponse200Reason): `ok` when available. `invalid` — wrong shape
            (lowercase, [a-z0-9_-], leading alphanumeric, 2–128 chars). `reserved` — a word the site’s own routing owns.
            `taken` — another live paper of this author already publishes there.
    """

    available: bool
    reason: GetContentMarkdownIdRouteAvailableRouteResponse200Reason
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        available = self.available

        reason = self.reason.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "available": available,
                "reason": reason,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        available = d.pop("available")

        reason = GetContentMarkdownIdRouteAvailableRouteResponse200Reason(d.pop("reason"))

        get_content_markdown_id_route_available_route_response_200 = cls(
            available=available,
            reason=reason,
        )

        get_content_markdown_id_route_available_route_response_200.additional_properties = d
        return get_content_markdown_id_route_available_route_response_200

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
