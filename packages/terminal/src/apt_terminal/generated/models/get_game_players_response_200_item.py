from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetGamePlayersResponse200Item")


@_attrs_define
class GetGamePlayersResponse200Item:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        customer_id (str):
        owner_kind (str):
        owner_id (str):
        game_id (str):
        character_name (None | str):
        character_avatar_url (None | str):
        visibility (str):
        first_played_at (str):
        last_played_at (str):
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    customer_id: str
    owner_kind: str
    owner_id: str
    game_id: str
    character_name: None | str
    character_avatar_url: None | str
    visibility: str
    first_played_at: str
    last_played_at: str
    created_at: str
    updated_at: str
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        game_id = self.game_id

        character_name: None | str
        character_name = self.character_name

        character_avatar_url: None | str
        character_avatar_url = self.character_avatar_url

        visibility = self.visibility

        first_played_at = self.first_played_at

        last_played_at = self.last_played_at

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
                "customerId": customer_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "gameId": game_id,
                "characterName": character_name,
                "characterAvatarUrl": character_avatar_url,
                "visibility": visibility,
                "firstPlayedAt": first_played_at,
                "lastPlayedAt": last_played_at,
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

        customer_id = d.pop("customerId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        game_id = d.pop("gameId")

        def _parse_character_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        character_name = _parse_character_name(d.pop("characterName"))

        def _parse_character_avatar_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        character_avatar_url = _parse_character_avatar_url(d.pop("characterAvatarUrl"))

        visibility = d.pop("visibility")

        first_played_at = d.pop("firstPlayedAt")

        last_played_at = d.pop("lastPlayedAt")

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

        get_game_players_response_200_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            game_id=game_id,
            character_name=character_name,
            character_avatar_url=character_avatar_url,
            visibility=visibility,
            first_played_at=first_played_at,
            last_played_at=last_played_at,
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_game_players_response_200_item
