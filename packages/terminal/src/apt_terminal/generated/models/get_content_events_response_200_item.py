from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.get_content_events_response_200_item_payload_type_1 import (
        GetContentEventsResponse200ItemPayloadType1,
    )


T = TypeVar("T", bound="GetContentEventsResponse200Item")


@_attrs_define
class GetContentEventsResponse200Item:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        type_ (str):
        payload (bool | float | GetContentEventsResponse200ItemPayloadType1 | list[Any] | None | str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    type_: str
    payload: bool | float | GetContentEventsResponse200ItemPayloadType1 | list[Any] | None | str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_content_events_response_200_item_payload_type_1 import (
            GetContentEventsResponse200ItemPayloadType1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        type_ = self.type_

        payload: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.payload, GetContentEventsResponse200ItemPayloadType1):
            payload = self.payload.to_dict()
        elif isinstance(self.payload, list):
            payload = self.payload

        else:
            payload = self.payload

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "type": type_,
                "payload": payload,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_content_events_response_200_item_payload_type_1 import (
            GetContentEventsResponse200ItemPayloadType1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        type_ = d.pop("type")

        def _parse_payload(
            data: object,
        ) -> bool | float | GetContentEventsResponse200ItemPayloadType1 | list[Any] | None | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                payload_type_1 = GetContentEventsResponse200ItemPayloadType1.from_dict(data)

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
                bool | float | GetContentEventsResponse200ItemPayloadType1 | list[Any] | None | str,
                data,
            )

        payload = _parse_payload(d.pop("payload"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_content_events_response_200_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            type_=type_,
            payload=payload,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_content_events_response_200_item
