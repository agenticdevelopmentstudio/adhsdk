from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_content_events_body_payload_type_1 import (
        PostV1ContentEventsBodyPayloadType1,
    )


T = TypeVar("T", bound="PostV1ContentEventsBody")


@_attrs_define
class PostV1ContentEventsBody:
    """
    Attributes:
        type_ (str):
        payload (bool | float | list[Any] | None | PostV1ContentEventsBodyPayloadType1 | str):
        ecosystem_id (str | Unset):
    """

    type_: str
    payload: bool | float | list[Any] | None | PostV1ContentEventsBodyPayloadType1 | str
    ecosystem_id: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_content_events_body_payload_type_1 import (
            PostV1ContentEventsBodyPayloadType1,
        )

        type_ = self.type_

        payload: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.payload, PostV1ContentEventsBodyPayloadType1):
            payload = self.payload.to_dict()
        elif isinstance(self.payload, list):
            payload = self.payload

        else:
            payload = self.payload

        ecosystem_id = self.ecosystem_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "type": type_,
                "payload": payload,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_content_events_body_payload_type_1 import (
            PostV1ContentEventsBodyPayloadType1,
        )

        d = dict(src_dict)
        type_ = d.pop("type")

        def _parse_payload(
            data: object,
        ) -> bool | float | list[Any] | None | PostV1ContentEventsBodyPayloadType1 | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                payload_type_1 = PostV1ContentEventsBodyPayloadType1.from_dict(data)

                return payload_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                payload_type_2 = cast(list[Any], data)

                return payload_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool | float | list[Any] | None | PostV1ContentEventsBodyPayloadType1 | str, data
            )

        payload = _parse_payload(d.pop("payload"))

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        post_v1_content_events_body = cls(
            type_=type_,
            payload=payload,
            ecosystem_id=ecosystem_id,
        )

        return post_v1_content_events_body
