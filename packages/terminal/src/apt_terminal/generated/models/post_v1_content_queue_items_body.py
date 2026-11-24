from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_content_queue_items_body_payload_type_1 import (
        PostV1ContentQueueItemsBodyPayloadType1,
    )


T = TypeVar("T", bound="PostV1ContentQueueItemsBody")


@_attrs_define
class PostV1ContentQueueItemsBody:
    """
    Attributes:
        queue_id (str):
        payload (bool | float | list[Any] | None | PostV1ContentQueueItemsBodyPayloadType1 | str):
        status (str):
        enqueued_at (str):
        ecosystem_id (str | Unset):
        dequeued_at (None | str | Unset):
        acked_at (None | str | Unset):
        nacked_at (None | str | Unset):
    """

    queue_id: str
    payload: bool | float | list[Any] | None | PostV1ContentQueueItemsBodyPayloadType1 | str
    status: str
    enqueued_at: str
    ecosystem_id: str | Unset = UNSET
    dequeued_at: None | str | Unset = UNSET
    acked_at: None | str | Unset = UNSET
    nacked_at: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_content_queue_items_body_payload_type_1 import (
            PostV1ContentQueueItemsBodyPayloadType1,
        )

        queue_id = self.queue_id

        payload: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.payload, PostV1ContentQueueItemsBodyPayloadType1):
            payload = self.payload.to_dict()
        elif isinstance(self.payload, list):
            payload = self.payload

        else:
            payload = self.payload

        status = self.status

        enqueued_at = self.enqueued_at

        ecosystem_id = self.ecosystem_id

        dequeued_at: None | str | Unset
        if isinstance(self.dequeued_at, Unset):
            dequeued_at = UNSET
        else:
            dequeued_at = self.dequeued_at

        acked_at: None | str | Unset
        if isinstance(self.acked_at, Unset):
            acked_at = UNSET
        else:
            acked_at = self.acked_at

        nacked_at: None | str | Unset
        if isinstance(self.nacked_at, Unset):
            nacked_at = UNSET
        else:
            nacked_at = self.nacked_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "queue_id": queue_id,
                "payload": payload,
                "status": status,
                "enqueued_at": enqueued_at,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if dequeued_at is not UNSET:
            field_dict["dequeued_at"] = dequeued_at
        if acked_at is not UNSET:
            field_dict["acked_at"] = acked_at
        if nacked_at is not UNSET:
            field_dict["nacked_at"] = nacked_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_content_queue_items_body_payload_type_1 import (
            PostV1ContentQueueItemsBodyPayloadType1,
        )

        d = dict(src_dict)
        queue_id = d.pop("queue_id")

        def _parse_payload(
            data: object,
        ) -> bool | float | list[Any] | None | PostV1ContentQueueItemsBodyPayloadType1 | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                payload_type_1 = PostV1ContentQueueItemsBodyPayloadType1.from_dict(data)

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
                bool | float | list[Any] | None | PostV1ContentQueueItemsBodyPayloadType1 | str,
                data,
            )

        payload = _parse_payload(d.pop("payload"))

        status = d.pop("status")

        enqueued_at = d.pop("enqueued_at")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        def _parse_dequeued_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        dequeued_at = _parse_dequeued_at(d.pop("dequeued_at", UNSET))

        def _parse_acked_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        acked_at = _parse_acked_at(d.pop("acked_at", UNSET))

        def _parse_nacked_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        nacked_at = _parse_nacked_at(d.pop("nacked_at", UNSET))

        post_v1_content_queue_items_body = cls(
            queue_id=queue_id,
            payload=payload,
            status=status,
            enqueued_at=enqueued_at,
            ecosystem_id=ecosystem_id,
            dequeued_at=dequeued_at,
            acked_at=acked_at,
            nacked_at=nacked_at,
        )

        return post_v1_content_queue_items_body
