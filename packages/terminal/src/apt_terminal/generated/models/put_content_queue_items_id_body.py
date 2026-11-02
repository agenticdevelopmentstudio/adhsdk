from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.put_content_queue_items_id_body_payload_type_1 import (
        PutContentQueueItemsIdBodyPayloadType1,
    )


T = TypeVar("T", bound="PutContentQueueItemsIdBody")


@_attrs_define
class PutContentQueueItemsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        queue_id (str | Unset):
        payload (bool | float | list[Any] | None | PutContentQueueItemsIdBodyPayloadType1 | str | Unset):
        status (str | Unset):
        enqueued_at (str | Unset):
        dequeued_at (None | str | Unset):
        acked_at (None | str | Unset):
        nacked_at (None | str | Unset):
        sync_txid (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    queue_id: str | Unset = UNSET
    payload: (
        bool | float | list[Any] | None | PutContentQueueItemsIdBodyPayloadType1 | str | Unset
    ) = UNSET
    status: str | Unset = UNSET
    enqueued_at: str | Unset = UNSET
    dequeued_at: None | str | Unset = UNSET
    acked_at: None | str | Unset = UNSET
    nacked_at: None | str | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.put_content_queue_items_id_body_payload_type_1 import (
            PutContentQueueItemsIdBodyPayloadType1,
        )

        ecosystem_id = self.ecosystem_id

        queue_id = self.queue_id

        payload: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.payload, Unset):
            payload = UNSET
        elif isinstance(self.payload, PutContentQueueItemsIdBodyPayloadType1):
            payload = self.payload.to_dict()
        elif isinstance(self.payload, list):
            payload = self.payload

        else:
            payload = self.payload

        status = self.status

        enqueued_at = self.enqueued_at

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

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if queue_id is not UNSET:
            field_dict["queueId"] = queue_id
        if payload is not UNSET:
            field_dict["payload"] = payload
        if status is not UNSET:
            field_dict["status"] = status
        if enqueued_at is not UNSET:
            field_dict["enqueuedAt"] = enqueued_at
        if dequeued_at is not UNSET:
            field_dict["dequeuedAt"] = dequeued_at
        if acked_at is not UNSET:
            field_dict["ackedAt"] = acked_at
        if nacked_at is not UNSET:
            field_dict["nackedAt"] = nacked_at
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_content_queue_items_id_body_payload_type_1 import (
            PutContentQueueItemsIdBodyPayloadType1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        queue_id = d.pop("queueId", UNSET)

        def _parse_payload(
            data: object,
        ) -> bool | float | list[Any] | None | PutContentQueueItemsIdBodyPayloadType1 | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                payload_type_1 = PutContentQueueItemsIdBodyPayloadType1.from_dict(data)

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
                | PutContentQueueItemsIdBodyPayloadType1
                | str
                | Unset,
                data,
            )

        payload = _parse_payload(d.pop("payload", UNSET))

        status = d.pop("status", UNSET)

        enqueued_at = d.pop("enqueuedAt", UNSET)

        def _parse_dequeued_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        dequeued_at = _parse_dequeued_at(d.pop("dequeuedAt", UNSET))

        def _parse_acked_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        acked_at = _parse_acked_at(d.pop("ackedAt", UNSET))

        def _parse_nacked_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        nacked_at = _parse_nacked_at(d.pop("nackedAt", UNSET))

        sync_txid = d.pop("syncTxid", UNSET)

        put_content_queue_items_id_body = cls(
            ecosystem_id=ecosystem_id,
            queue_id=queue_id,
            payload=payload,
            status=status,
            enqueued_at=enqueued_at,
            dequeued_at=dequeued_at,
            acked_at=acked_at,
            nacked_at=nacked_at,
            sync_txid=sync_txid,
        )

        return put_content_queue_items_id_body
