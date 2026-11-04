from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.post_content_key_value_pairs_response_201_value_type_1 import (
        PostContentKeyValuePairsResponse201ValueType1,
    )


T = TypeVar("T", bound="PostContentKeyValuePairsResponse201")


@_attrs_define
class PostContentKeyValuePairsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        customer_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        key (str):
        value (bool | float | list[Any] | None | PostContentKeyValuePairsResponse201ValueType1 | str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    customer_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    key: str
    value: bool | float | list[Any] | None | PostContentKeyValuePairsResponse201ValueType1 | str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_content_key_value_pairs_response_201_value_type_1 import (
            PostContentKeyValuePairsResponse201ValueType1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        key = self.key

        value: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.value, PostContentKeyValuePairsResponse201ValueType1):
            value = self.value.to_dict()
        elif isinstance(self.value, list):
            value = self.value

        else:
            value = self.value

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
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "key": key,
                "value": value,
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
        from ..models.post_content_key_value_pairs_response_201_value_type_1 import (
            PostContentKeyValuePairsResponse201ValueType1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        customer_id = d.pop("customerId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        key = d.pop("key")

        def _parse_value(
            data: object,
        ) -> bool | float | list[Any] | None | PostContentKeyValuePairsResponse201ValueType1 | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                value_type_1 = PostContentKeyValuePairsResponse201ValueType1.from_dict(data)

                return value_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                value_type_2 = cast(list[Any], data)

                return value_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostContentKeyValuePairsResponse201ValueType1
                | str,
                data,
            )

        value = _parse_value(d.pop("value"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        post_content_key_value_pairs_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            key=key,
            value=value,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return post_content_key_value_pairs_response_201
