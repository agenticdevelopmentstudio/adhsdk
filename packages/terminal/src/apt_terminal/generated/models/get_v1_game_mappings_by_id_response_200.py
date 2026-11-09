from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1GameMappingsByIdResponse200")


@_attrs_define
class GetV1GameMappingsByIdResponse200:
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['game.mapping'] | Unset):
    """

    id: str
    ecosystem_id: str
    game_id: str
    from_id: str
    kind: str
    to_id: str
    amount: int
    sort_order: int
    created: int
    updated: int
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["game.mapping"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        game_id = self.game_id

        from_id = self.from_id

        kind = self.kind

        to_id = self.to_id

        amount = self.amount

        sort_order = self.sort_order

        created = self.created

        updated = self.updated

        deleted_at: None | str
        deleted_at = self.deleted_at

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
                "game_id": game_id,
                "from_id": from_id,
                "kind": kind,
                "to_id": to_id,
                "amount": amount,
                "sort_order": sort_order,
                "created": created,
                "updated": updated,
                "deleted_at": deleted_at,
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
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        game_id = d.pop("game_id")

        from_id = d.pop("from_id")

        kind = d.pop("kind")

        to_id = d.pop("to_id")

        amount = d.pop("amount")

        sort_order = d.pop("sort_order")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["game.mapping"] | Unset, d.pop("object", UNSET))
        if object_ != "game.mapping" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'game.mapping', got '{object_}'")

        get_v1_game_mappings_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            game_id=game_id,
            from_id=from_id,
            kind=kind,
            to_id=to_id,
            amount=amount,
            sort_order=sort_order,
            created=created,
            updated=updated,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return get_v1_game_mappings_by_id_response_200
