from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostContentAddressesResponse201")


@_attrs_define
class PostContentAddressesResponse201:
    """
    Attributes:
        id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        label (str):
        line1 (str):
        line2 (str):
        city (str):
        region (str):
        postal_code (str):
        country (str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        author_kind (None | str):
        author_id (None | str):
    """

    id: str
    deleted_at: None | str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    label: str
    line1: str
    line2: str
    city: str
    region: str
    postal_code: str
    country: str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    author_kind: None | str
    author_id: None | str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        label = self.label

        line1 = self.line1

        line2 = self.line2

        city = self.city

        region = self.region

        postal_code = self.postal_code

        country = self.country

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
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "label": label,
                "line1": line1,
                "line2": line2,
                "city": city,
                "region": region,
                "postalCode": postal_code,
                "country": country,
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
        d = dict(src_dict)
        id = d.pop("id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        label = d.pop("label")

        line1 = d.pop("line1")

        line2 = d.pop("line2")

        city = d.pop("city")

        region = d.pop("region")

        postal_code = d.pop("postalCode")

        country = d.pop("country")

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

        post_content_addresses_response_201 = cls(
            id=id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            label=label,
            line1=line1,
            line2=line2,
            city=city,
            region=region,
            postal_code=postal_code,
            country=country,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            author_kind=author_kind,
            author_id=author_id,
        )

        return post_content_addresses_response_201
