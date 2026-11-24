from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1BillingEventsResponse200DataItem")


@_attrs_define
class GetV1BillingEventsResponse200DataItem:
    """
    Attributes:
        id (str):
        stripe_event_id (str):
        type_ (str):
        received_at (str):
        processed_at (None | str | Unset):
        error (None | str | Unset):
        object_ (Literal['billing.event'] | Unset):
    """

    id: str
    stripe_event_id: str
    type_: str
    received_at: str
    processed_at: None | str | Unset = UNSET
    error: None | str | Unset = UNSET
    object_: Literal["billing.event"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        stripe_event_id = self.stripe_event_id

        type_ = self.type_

        received_at = self.received_at

        processed_at: None | str | Unset
        if isinstance(self.processed_at, Unset):
            processed_at = UNSET
        else:
            processed_at = self.processed_at

        error: None | str | Unset
        if isinstance(self.error, Unset):
            error = UNSET
        else:
            error = self.error

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "stripe_event_id": stripe_event_id,
                "type": type_,
                "received_at": received_at,
            }
        )
        if processed_at is not UNSET:
            field_dict["processed_at"] = processed_at
        if error is not UNSET:
            field_dict["error"] = error
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        stripe_event_id = d.pop("stripe_event_id")

        type_ = d.pop("type")

        received_at = d.pop("received_at")

        def _parse_processed_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        processed_at = _parse_processed_at(d.pop("processed_at", UNSET))

        def _parse_error(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        error = _parse_error(d.pop("error", UNSET))

        object_ = cast(Literal["billing.event"] | Unset, d.pop("object", UNSET))
        if object_ != "billing.event" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'billing.event', got '{object_}'")

        get_v1_billing_events_response_200_data_item = cls(
            id=id,
            stripe_event_id=stripe_event_id,
            type_=type_,
            received_at=received_at,
            processed_at=processed_at,
            error=error,
            object_=object_,
        )

        get_v1_billing_events_response_200_data_item.additional_properties = d
        return get_v1_billing_events_response_200_data_item

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
