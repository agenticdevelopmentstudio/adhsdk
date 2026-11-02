from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.get_persona_memory_blocks_id_response_200_content_type_1 import (
        GetPersonaMemoryBlocksIdResponse200ContentType1,
    )


T = TypeVar("T", bound="GetPersonaMemoryBlocksIdResponse200")


@_attrs_define
class GetPersonaMemoryBlocksIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        customer_id (str):
        deleted_at (None | str):
        name (str):
        content (bool | float | GetPersonaMemoryBlocksIdResponse200ContentType1 | list[Any] | None | str):
        size_limit (int | None):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    customer_id: str
    deleted_at: None | str
    name: str
    content: bool | float | GetPersonaMemoryBlocksIdResponse200ContentType1 | list[Any] | None | str
    size_limit: int | None
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_persona_memory_blocks_id_response_200_content_type_1 import (
            GetPersonaMemoryBlocksIdResponse200ContentType1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        name = self.name

        content: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.content, GetPersonaMemoryBlocksIdResponse200ContentType1):
            content = self.content.to_dict()
        elif isinstance(self.content, list):
            content = self.content

        else:
            content = self.content

        size_limit: int | None
        size_limit = self.size_limit

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
                "customerId": customer_id,
                "deletedAt": deleted_at,
                "name": name,
                "content": content,
                "sizeLimit": size_limit,
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
        from ..models.get_persona_memory_blocks_id_response_200_content_type_1 import (
            GetPersonaMemoryBlocksIdResponse200ContentType1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        customer_id = d.pop("customerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        name = d.pop("name")

        def _parse_content(
            data: object,
        ) -> (
            bool | float | GetPersonaMemoryBlocksIdResponse200ContentType1 | list[Any] | None | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                content_type_1 = GetPersonaMemoryBlocksIdResponse200ContentType1.from_dict(data)

                return content_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                content_type_2 = cast(list[Any], data)

                return content_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | GetPersonaMemoryBlocksIdResponse200ContentType1
                | list[Any]
                | None
                | str,
                data,
            )

        content = _parse_content(d.pop("content"))

        def _parse_size_limit(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        size_limit = _parse_size_limit(d.pop("sizeLimit"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_persona_memory_blocks_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
            deleted_at=deleted_at,
            name=name,
            content=content,
            size_limit=size_limit,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_persona_memory_blocks_id_response_200
