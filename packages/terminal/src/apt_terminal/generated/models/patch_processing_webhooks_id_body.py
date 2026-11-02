from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PatchProcessingWebhooksIdBody")


@_attrs_define
class PatchProcessingWebhooksIdBody:
    """
    Attributes:
        active (bool | Unset): Enable or disable delivery
        event_types (list[str] | Unset): Replace the subscribed event-type list
    """

    active: bool | Unset = UNSET
    event_types: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        active = self.active

        event_types: list[str] | Unset = UNSET
        if not isinstance(self.event_types, Unset):
            event_types = self.event_types

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if active is not UNSET:
            field_dict["active"] = active
        if event_types is not UNSET:
            field_dict["eventTypes"] = event_types

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        active = d.pop("active", UNSET)

        event_types = cast(list[str], d.pop("eventTypes", UNSET))

        patch_processing_webhooks_id_body = cls(
            active=active,
            event_types=event_types,
        )

        patch_processing_webhooks_id_body.additional_properties = d
        return patch_processing_webhooks_id_body

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
