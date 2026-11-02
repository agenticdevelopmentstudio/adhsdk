from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.get_integration_integration_audiences_id_response_200_raw_type_0_type_1 import (
        GetIntegrationIntegrationAudiencesIdResponse200RawType0Type1,
    )


T = TypeVar("T", bound="GetIntegrationIntegrationAudiencesIdResponse200")


@_attrs_define
class GetIntegrationIntegrationAudiencesIdResponse200:
    """
    Attributes:
        id (str):
        customer_id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        connection_id (str):
        provider (str):
        external_id (str):
        name (str):
        member_count (int | None):
        raw (bool | float | GetIntegrationIntegrationAudiencesIdResponse200RawType0Type1 | list[Any] | None | str):
        is_deleted (bool):
        deleted_at (None | str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    customer_id: str
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
        | GetIntegrationIntegrationAudiencesIdResponse200RawType0Type1
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

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_integration_integration_audiences_id_response_200_raw_type_0_type_1 import (
            GetIntegrationIntegrationAudiencesIdResponse200RawType0Type1,
        )

        id = self.id

        customer_id = self.customer_id

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
        if isinstance(self.raw, GetIntegrationIntegrationAudiencesIdResponse200RawType0Type1):
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

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "customerId": customer_id,
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
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_integration_integration_audiences_id_response_200_raw_type_0_type_1 import (
            GetIntegrationIntegrationAudiencesIdResponse200RawType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        customer_id = d.pop("customerId")

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
            | GetIntegrationIntegrationAudiencesIdResponse200RawType0Type1
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
                    GetIntegrationIntegrationAudiencesIdResponse200RawType0Type1.from_dict(data)
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
                | GetIntegrationIntegrationAudiencesIdResponse200RawType0Type1
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

        get_integration_integration_audiences_id_response_200 = cls(
            id=id,
            customer_id=customer_id,
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
        )

        return get_integration_integration_audiences_id_response_200
