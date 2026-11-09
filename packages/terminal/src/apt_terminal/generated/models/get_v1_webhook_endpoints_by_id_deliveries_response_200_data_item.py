from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.ai_processing_webhook_delivery_payload import AiProcessingWebhookDeliveryPayload


T = TypeVar("T", bound="GetV1WebhookEndpointsByIdDeliveriesResponse200DataItem")


@_attrs_define
class GetV1WebhookEndpointsByIdDeliveriesResponse200DataItem:
    """
    Attributes:
        id (UUID):
        ecosystem_id (str):
        endpoint_id (UUID):
        event_id (UUID):
        event_type (str):
        payload (AiProcessingWebhookDeliveryPayload):
        status (str): pending | delivered | failed | dead
        attempts (int):
        max_attempts (int):
        next_attempt_at (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        response_status (int | None | Unset):
        last_error (None | str | Unset):
        delivered_at (None | str | Unset):
        object_ (Literal['delivery'] | Unset):
    """

    id: UUID
    ecosystem_id: str
    endpoint_id: UUID
    event_id: UUID
    event_type: str
    payload: AiProcessingWebhookDeliveryPayload
    status: str
    attempts: int
    max_attempts: int
    next_attempt_at: str
    created: int
    updated: int
    response_status: int | None | Unset = UNSET
    last_error: None | str | Unset = UNSET
    delivered_at: None | str | Unset = UNSET
    object_: Literal["delivery"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        ecosystem_id = self.ecosystem_id

        endpoint_id = str(self.endpoint_id)

        event_id = str(self.event_id)

        event_type = self.event_type

        payload = self.payload.to_dict()

        status = self.status

        attempts = self.attempts

        max_attempts = self.max_attempts

        next_attempt_at = self.next_attempt_at

        created = self.created

        updated = self.updated

        response_status: int | None | Unset
        if isinstance(self.response_status, Unset):
            response_status = UNSET
        else:
            response_status = self.response_status

        last_error: None | str | Unset
        if isinstance(self.last_error, Unset):
            last_error = UNSET
        else:
            last_error = self.last_error

        delivered_at: None | str | Unset
        if isinstance(self.delivered_at, Unset):
            delivered_at = UNSET
        else:
            delivered_at = self.delivered_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "endpoint_id": endpoint_id,
                "event_id": event_id,
                "event_type": event_type,
                "payload": payload,
                "status": status,
                "attempts": attempts,
                "max_attempts": max_attempts,
                "next_attempt_at": next_attempt_at,
                "created": created,
                "updated": updated,
            }
        )
        if response_status is not UNSET:
            field_dict["response_status"] = response_status
        if last_error is not UNSET:
            field_dict["last_error"] = last_error
        if delivered_at is not UNSET:
            field_dict["delivered_at"] = delivered_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_webhook_delivery_payload import (
            AiProcessingWebhookDeliveryPayload,
        )

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        ecosystem_id = d.pop("ecosystem_id")

        endpoint_id = UUID(d.pop("endpoint_id"))

        event_id = UUID(d.pop("event_id"))

        event_type = d.pop("event_type")

        payload = AiProcessingWebhookDeliveryPayload.from_dict(d.pop("payload"))

        status = d.pop("status")

        attempts = d.pop("attempts")

        max_attempts = d.pop("max_attempts")

        next_attempt_at = d.pop("next_attempt_at")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_response_status(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        response_status = _parse_response_status(d.pop("response_status", UNSET))

        def _parse_last_error(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_error = _parse_last_error(d.pop("last_error", UNSET))

        def _parse_delivered_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        delivered_at = _parse_delivered_at(d.pop("delivered_at", UNSET))

        object_ = cast(Literal["delivery"] | Unset, d.pop("object", UNSET))
        if object_ != "delivery" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'delivery', got '{object_}'")

        get_v1_webhook_endpoints_by_id_deliveries_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            endpoint_id=endpoint_id,
            event_id=event_id,
            event_type=event_type,
            payload=payload,
            status=status,
            attempts=attempts,
            max_attempts=max_attempts,
            next_attempt_at=next_attempt_at,
            created=created,
            updated=updated,
            response_status=response_status,
            last_error=last_error,
            delivered_at=delivered_at,
            object_=object_,
        )

        get_v1_webhook_endpoints_by_id_deliveries_response_200_data_item.additional_properties = d
        return get_v1_webhook_endpoints_by_id_deliveries_response_200_data_item

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
