from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.get_integration_integration_audiences_response_200_item_raw_type_0_type_1 import (
        GetIntegrationIntegrationAudiencesResponse200ItemRawType0Type1,
    )


T = TypeVar("T", bound="GetIntegrationIntegrationAudiencesResponse200Item")


@_attrs_define
class GetIntegrationIntegrationAudiencesResponse200Item:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        connection_id (str):
        provider (str):
        external_id (str):
        name (str):
        member_count (int | None):
        raw (bool | float | GetIntegrationIntegrationAudiencesResponse200ItemRawType0Type1 | list[Any] | None | str):
        is_deleted (bool):
        deleted_at (None | str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        author_kind (None | str):
        author_id (None | str):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    connection_id: str
    provider: str
    external_id: str
    name: str
    member_count: int | None
    raw: (
        bool
        | float
        | GetIntegrationIntegrationAudiencesResponse200ItemRawType0Type1
        | list[Any]
        | None
        | str
    )
    is_deleted: bool
    deleted_at: None | str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    author_kind: None | str
    author_id: None | str

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_integration_integration_audiences_response_200_item_raw_type_0_type_1 import (
            GetIntegrationIntegrationAudiencesResponse200ItemRawType0Type1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        connection_id = self.connection_id

        provider = self.provider

        external_id = self.external_id

        name = self.name

        member_count: int | None
        member_count = self.member_count

        raw: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.raw, GetIntegrationIntegrationAudiencesResponse200ItemRawType0Type1):
            raw = self.raw.to_dict()
        elif isinstance(self.raw, list):
            raw = self.raw

        else:
            raw = self.raw

        is_deleted = self.is_deleted

        deleted_at: None | str
        deleted_at = self.deleted_at

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "connectionId": connection_id,
                "provider": provider,
                "externalId": external_id,
                "name": name,
                "memberCount": member_count,
                "raw": raw,
                "isDeleted": is_deleted,
                "deletedAt": deleted_at,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
                "authorKind": author_kind,
                "authorId": author_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_integration_integration_audiences_response_200_item_raw_type_0_type_1 import (
            GetIntegrationIntegrationAudiencesResponse200ItemRawType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        connection_id = d.pop("connectionId")

        provider = d.pop("provider")

        external_id = d.pop("externalId")

        name = d.pop("name")

        def _parse_member_count(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        member_count = _parse_member_count(d.pop("memberCount"))

        def _parse_raw(
            data: object,
        ) -> (
            bool
            | float
            | GetIntegrationIntegrationAudiencesResponse200ItemRawType0Type1
            | list[Any]
            | None
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                raw_type_0_type_1 = (
                    GetIntegrationIntegrationAudiencesResponse200ItemRawType0Type1.from_dict(data)
                )

                return raw_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                raw_type_0_type_2 = cast(list[Any], data)

                return raw_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | GetIntegrationIntegrationAudiencesResponse200ItemRawType0Type1
                | list[Any]
                | None
                | str,
                data,
            )

        raw = _parse_raw(d.pop("raw"))

        is_deleted = d.pop("isDeleted")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("authorKind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("authorId"))

        get_integration_integration_audiences_response_200_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            connection_id=connection_id,
            provider=provider,
            external_id=external_id,
            name=name,
            member_count=member_count,
            raw=raw,
            is_deleted=is_deleted,
            deleted_at=deleted_at,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            author_kind=author_kind,
            author_id=author_id,
        )

        return get_integration_integration_audiences_response_200_item
