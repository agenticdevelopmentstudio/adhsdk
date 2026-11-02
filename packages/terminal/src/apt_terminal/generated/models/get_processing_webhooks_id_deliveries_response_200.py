from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.ai_processing_webhook_delivery import AiProcessingWebhookDelivery


T = TypeVar("T", bound="GetProcessingWebhooksIdDeliveriesResponse200")


@_attrs_define
class GetProcessingWebhooksIdDeliveriesResponse200:
    """
    Attributes:
        deliveries (list[AiProcessingWebhookDelivery]):
    """

    deliveries: list[AiProcessingWebhookDelivery]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        deliveries = []
        for deliveries_item_data in self.deliveries:
            deliveries_item = deliveries_item_data.to_dict()
            deliveries.append(deliveries_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "deliveries": deliveries,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_webhook_delivery import (
            AiProcessingWebhookDelivery,
        )

        d = dict(src_dict)
        deliveries = []
        _deliveries = d.pop("deliveries")
        for deliveries_item_data in _deliveries:
            deliveries_item = AiProcessingWebhookDelivery.from_dict(deliveries_item_data)

            deliveries.append(deliveries_item)

        get_processing_webhooks_id_deliveries_response_200 = cls(
            deliveries=deliveries,
        )

        get_processing_webhooks_id_deliveries_response_200.additional_properties = d
        return get_processing_webhooks_id_deliveries_response_200

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
