from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_content_events_by_id_body_payload_type_1 import (
        PostV1ContentEventsByIdBodyPayloadType1,
    )


T = TypeVar("T", bound="PostV1ContentEventsByIdBody")


@_attrs_define
class PostV1ContentEventsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        type_ (str | Unset):
        payload (bool | float | list[Any] | None | PostV1ContentEventsByIdBodyPayloadType1 | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    type_: str | Unset = UNSET
    payload: (
        bool | float | list[Any] | None | PostV1ContentEventsByIdBodyPayloadType1 | str | Unset
    ) = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_content_events_by_id_body_payload_type_1 import (
            PostV1ContentEventsByIdBodyPayloadType1,
        )

        ecosystem_id = self.ecosystem_id

        type_ = self.type_

        payload: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.payload, Unset):
            payload = UNSET
        elif isinstance(self.payload, PostV1ContentEventsByIdBodyPayloadType1):
            payload = self.payload.to_dict()
        elif isinstance(self.payload, list):
            payload = self.payload

        else:
            payload = self.payload

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if type_ is not UNSET:
            field_dict["type"] = type_
        if payload is not UNSET:
            field_dict["payload"] = payload

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_content_events_by_id_body_payload_type_1 import (
            PostV1ContentEventsByIdBodyPayloadType1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        type_ = d.pop("type", UNSET)

        def _parse_payload(
            data: object,
        ) -> (
            bool | float | list[Any] | None | PostV1ContentEventsByIdBodyPayloadType1 | str | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                payload_type_1 = PostV1ContentEventsByIdBodyPayloadType1.from_dict(data)

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
                bool
                | float
                | list[Any]
                | None
                | PostV1ContentEventsByIdBodyPayloadType1
                | str
                | Unset,
                data,
            )

        payload = _parse_payload(d.pop("payload", UNSET))

        post_v1_content_events_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            type_=type_,
            payload=payload,
        )

        return post_v1_content_events_by_id_body
