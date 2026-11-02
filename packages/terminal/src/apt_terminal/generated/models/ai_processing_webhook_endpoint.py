from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="AiProcessingWebhookEndpoint")


@_attrs_define
class AiProcessingWebhookEndpoint:
    """
    Attributes:
        id (UUID):
        ecosystem_id (str): Ecosystem that owns this endpoint
        customer_id (str): User who registered the endpoint
        url (str): HTTPS-only delivery target URL
        event_types (list[str]): Subscribed event types (e.g. job.succeeded, job.failed)
        active (bool): Whether the endpoint receives deliveries
        created_at (str): ISO 8601 timestamp
        updated_at (str): ISO 8601 timestamp of last modification
        description (None | str | Unset): Human-readable label
    """

    id: UUID
    ecosystem_id: str
    customer_id: str
    url: str
    event_types: list[str]
    active: bool
    created_at: str
    updated_at: str
    description: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

        url = self.url

        event_types = self.event_types

        active = self.active

        created_at = self.created_at

        updated_at = self.updated_at

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "customerId": customer_id,
                "url": url,
                "eventTypes": event_types,
                "active": active,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        ecosystem_id = d.pop("ecosystemId")

        customer_id = d.pop("customerId")

        url = d.pop("url")

        event_types = cast(list[str], d.pop("eventTypes"))

        active = d.pop("active")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        ai_processing_webhook_endpoint = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
            url=url,
            event_types=event_types,
            active=active,
            created_at=created_at,
            updated_at=updated_at,
            description=description,
        )

        ai_processing_webhook_endpoint.additional_properties = d
        return ai_processing_webhook_endpoint

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
