from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_content_queue_items_response_201_payload_type_1 import (
        PostV1ContentQueueItemsResponse201PayloadType1,
    )


T = TypeVar("T", bound="PostV1ContentQueueItemsResponse201")


@_attrs_define
class PostV1ContentQueueItemsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        queue_id (str):
        payload (bool | float | list[Any] | None | PostV1ContentQueueItemsResponse201PayloadType1 | str):
        status (str):
        enqueued_at (str):
        dequeued_at (None | str):
        acked_at (None | str):
        nacked_at (None | str):
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['content.queue_item'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    queue_id: str
    payload: bool | float | list[Any] | None | PostV1ContentQueueItemsResponse201PayloadType1 | str
    status: str
    enqueued_at: str
    dequeued_at: None | str
    acked_at: None | str
    nacked_at: None | str
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["content.queue_item"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_content_queue_items_response_201_payload_type_1 import (
            PostV1ContentQueueItemsResponse201PayloadType1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        queue_id = self.queue_id

        payload: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.payload, PostV1ContentQueueItemsResponse201PayloadType1):
            payload = self.payload.to_dict()
        elif isinstance(self.payload, list):
            payload = self.payload

        else:
            payload = self.payload

        status = self.status

        enqueued_at = self.enqueued_at

        dequeued_at: None | str
        dequeued_at = self.dequeued_at

        acked_at: None | str
        acked_at = self.acked_at

        nacked_at: None | str
        nacked_at = self.nacked_at

        updated = self.updated

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "deleted_at": deleted_at,
                "queue_id": queue_id,
                "payload": payload,
                "status": status,
                "enqueued_at": enqueued_at,
                "dequeued_at": dequeued_at,
                "acked_at": acked_at,
                "nacked_at": nacked_at,
                "updated": updated,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_content_queue_items_response_201_payload_type_1 import (
            PostV1ContentQueueItemsResponse201PayloadType1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        queue_id = d.pop("queue_id")

        def _parse_payload(
            data: object,
        ) -> bool | float | list[Any] | None | PostV1ContentQueueItemsResponse201PayloadType1 | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                payload_type_1 = PostV1ContentQueueItemsResponse201PayloadType1.from_dict(data)

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
                | PostV1ContentQueueItemsResponse201PayloadType1
                | str,
                data,
            )

        payload = _parse_payload(d.pop("payload"))

        status = d.pop("status")

        enqueued_at = d.pop("enqueued_at")

        def _parse_dequeued_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        dequeued_at = _parse_dequeued_at(d.pop("dequeued_at"))

        def _parse_acked_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        acked_at = _parse_acked_at(d.pop("acked_at"))

        def _parse_nacked_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        nacked_at = _parse_nacked_at(d.pop("nacked_at"))

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["content.queue_item"] | Unset, d.pop("object", UNSET))
        if object_ != "content.queue_item" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'content.queue_item', got '{object_}'")

        post_v1_content_queue_items_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            queue_id=queue_id,
            payload=payload,
            status=status,
            enqueued_at=enqueued_at,
            dequeued_at=dequeued_at,
            acked_at=acked_at,
            nacked_at=nacked_at,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_content_queue_items_response_201
