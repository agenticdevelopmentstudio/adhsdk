from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.get_content_list_items_id_response_200_value_type_1 import (
        GetContentListItemsIdResponse200ValueType1,
    )


T = TypeVar("T", bound="GetContentListItemsIdResponse200")


@_attrs_define
class GetContentListItemsIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        customer_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        list_id (str):
        position (int):
        value (bool | float | GetContentListItemsIdResponse200ValueType1 | list[Any] | None | str):
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
    list_id: str
    position: int
    value: bool | float | GetContentListItemsIdResponse200ValueType1 | list[Any] | None | str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_content_list_items_id_response_200_value_type_1 import (
            GetContentListItemsIdResponse200ValueType1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        list_id = self.list_id

        position = self.position

        value: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.value, GetContentListItemsIdResponse200ValueType1):
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
                "listId": list_id,
                "position": position,
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
        from ..models.get_content_list_items_id_response_200_value_type_1 import (
            GetContentListItemsIdResponse200ValueType1,
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

        list_id = d.pop("listId")

        position = d.pop("position")

        def _parse_value(
            data: object,
        ) -> bool | float | GetContentListItemsIdResponse200ValueType1 | list[Any] | None | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                value_type_1 = GetContentListItemsIdResponse200ValueType1.from_dict(data)

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
                bool | float | GetContentListItemsIdResponse200ValueType1 | list[Any] | None | str,
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

        get_content_list_items_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            list_id=list_id,
            position=position,
            value=value,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_content_list_items_id_response_200
