from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetGameMappingsResponse200Item")


@_attrs_define
class GetGameMappingsResponse200Item:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        game_id (str):
        from_id (str):
        kind (str):
        to_id (str):
        amount (int):
        sort_order (int):
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    game_id: str
    from_id: str
    kind: str
    to_id: str
    amount: int
    sort_order: int
    created_at: str
    updated_at: str
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        game_id = self.game_id

        from_id = self.from_id

        kind = self.kind

        to_id = self.to_id

        amount = self.amount

        sort_order = self.sort_order

        created_at = self.created_at

        updated_at = self.updated_at

        deleted_at: None | str
        deleted_at = self.deleted_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "gameId": game_id,
                "fromId": from_id,
                "kind": kind,
                "toId": to_id,
                "amount": amount,
                "sortOrder": sort_order,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "deletedAt": deleted_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        game_id = d.pop("gameId")

        from_id = d.pop("fromId")

        kind = d.pop("kind")

        to_id = d.pop("toId")

        amount = d.pop("amount")

        sort_order = d.pop("sortOrder")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_game_mappings_response_200_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            game_id=game_id,
            from_id=from_id,
            kind=kind,
            to_id=to_id,
            amount=amount,
            sort_order=sort_order,
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_game_mappings_response_200_item
