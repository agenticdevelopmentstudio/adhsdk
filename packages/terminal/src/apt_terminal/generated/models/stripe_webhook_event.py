from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.stripe_webhook_event_data import StripeWebhookEventData


T = TypeVar("T", bound="StripeWebhookEvent")


@_attrs_define
class StripeWebhookEvent:
    """
    Attributes:
        id (str):
        type_ (str):
        created (int | Unset):
        data (StripeWebhookEventData | Unset):
    """

    id: str
    type_: str
    created: int | Unset = UNSET
    data: StripeWebhookEventData | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        type_ = self.type_

        created = self.created

        data: dict[str, Any] | Unset = UNSET
        if not isinstance(self.data, Unset):
            data = self.data.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "type": type_,
            }
        )
        if created is not UNSET:
            field_dict["created"] = created
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.stripe_webhook_event_data import StripeWebhookEventData

        d = dict(src_dict)
        id = d.pop("id")

        type_ = d.pop("type")

        created = d.pop("created", UNSET)

        _data = d.pop("data", UNSET)
        data: StripeWebhookEventData | Unset
        if isinstance(_data, Unset):
            data = UNSET
        else:
            data = StripeWebhookEventData.from_dict(_data)

        stripe_webhook_event = cls(
            id=id,
            type_=type_,
            created=created,
            data=data,
        )

        stripe_webhook_event.additional_properties = d
        return stripe_webhook_event

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
