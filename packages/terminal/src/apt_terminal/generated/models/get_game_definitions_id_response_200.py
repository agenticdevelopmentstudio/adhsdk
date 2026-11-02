from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.get_game_definitions_id_response_200_data_type_0_type_1 import (
        GetGameDefinitionsIdResponse200DataType0Type1,
    )


T = TypeVar("T", bound="GetGameDefinitionsIdResponse200")


@_attrs_define
class GetGameDefinitionsIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        author_customer_id (str):
        game_id (str):
        kind (str):
        key (str):
        name (str):
        description (None | str):
        status (str):
        sort_order (int):
        data (bool | float | GetGameDefinitionsIdResponse200DataType0Type1 | list[Any] | None | str):
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    author_customer_id: str
    game_id: str
    kind: str
    key: str
    name: str
    description: None | str
    status: str
    sort_order: int
    data: bool | float | GetGameDefinitionsIdResponse200DataType0Type1 | list[Any] | None | str
    created_at: str
    updated_at: str
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_game_definitions_id_response_200_data_type_0_type_1 import (
            GetGameDefinitionsIdResponse200DataType0Type1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        author_customer_id = self.author_customer_id

        game_id = self.game_id

        kind = self.kind

        key = self.key

        name = self.name

        description: None | str
        description = self.description

        status = self.status

        sort_order = self.sort_order

        data: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.data, GetGameDefinitionsIdResponse200DataType0Type1):
            data = self.data.to_dict()
        elif isinstance(self.data, list):
            data = self.data

        else:
            data = self.data

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
                "authorCustomerId": author_customer_id,
                "gameId": game_id,
                "kind": kind,
                "key": key,
                "name": name,
                "description": description,
                "status": status,
                "sortOrder": sort_order,
                "data": data,
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
        from ..models.get_game_definitions_id_response_200_data_type_0_type_1 import (
            GetGameDefinitionsIdResponse200DataType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        author_customer_id = d.pop("authorCustomerId")

        game_id = d.pop("gameId")

        kind = d.pop("kind")

        key = d.pop("key")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        status = d.pop("status")

        sort_order = d.pop("sortOrder")

        def _parse_data(
            data: object,
        ) -> bool | float | GetGameDefinitionsIdResponse200DataType0Type1 | list[Any] | None | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                data_type_0_type_1 = GetGameDefinitionsIdResponse200DataType0Type1.from_dict(data)

                return data_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                data_type_0_type_2 = cast(list[Any], data)

                return data_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | GetGameDefinitionsIdResponse200DataType0Type1
                | list[Any]
                | None
                | str,
                data,
            )

        data = _parse_data(d.pop("data"))

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

        get_game_definitions_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            author_customer_id=author_customer_id,
            game_id=game_id,
            kind=kind,
            key=key,
            name=name,
            description=description,
            status=status,
            sort_order=sort_order,
            data=data,
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_game_definitions_id_response_200
