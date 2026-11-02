from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProcessingWebhooksBody")


@_attrs_define
class PostProcessingWebhooksBody:
    """
    Attributes:
        url (str): HTTPS delivery target. Private/loopback/link-local URLs are rejected.
        event_types (list[str]): Event types to subscribe to (e.g. ["job.succeeded", "job.failed"])
        description (str | Unset): Optional human-readable label
    """

    url: str
    event_types: list[str]
    description: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        url = self.url

        event_types = self.event_types

        description = self.description

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "url": url,
                "eventTypes": event_types,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        url = d.pop("url")

        event_types = cast(list[str], d.pop("eventTypes"))

        description = d.pop("description", UNSET)

        post_processing_webhooks_body = cls(
            url=url,
            event_types=event_types,
            description=description,
        )

        post_processing_webhooks_body.additional_properties = d
        return post_processing_webhooks_body

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
