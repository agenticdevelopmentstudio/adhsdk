from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_content_list_items_response_200_data_item_value_type_1 import (
        GetV1ContentListItemsResponse200DataItemValueType1,
    )


T = TypeVar("T", bound="GetV1ContentListItemsResponse200DataItem")


@_attrs_define
class GetV1ContentListItemsResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        list_id (str):
        position (int):
        value (bool | float | GetV1ContentListItemsResponse200DataItemValueType1 | list[Any] | None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['content.list_item'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    list_id: str
    position: int
    value: (
        bool | float | GetV1ContentListItemsResponse200DataItemValueType1 | list[Any] | None | str
    )
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["content.list_item"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.get_v1_content_list_items_response_200_data_item_value_type_1 import (
            GetV1ContentListItemsResponse200DataItemValueType1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        list_id = self.list_id

        position = self.position

        value: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.value, GetV1ContentListItemsResponse200DataItemValueType1):
            value = self.value.to_dict()
        elif isinstance(self.value, list):
            value = self.value

        else:
            value = self.value

        created = self.created

        updated = self.updated

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
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "deleted_at": deleted_at,
                "list_id": list_id,
                "position": position,
                "value": value,
                "created": created,
                "updated": updated,
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
        from ..models.get_v1_content_list_items_response_200_data_item_value_type_1 import (
            GetV1ContentListItemsResponse200DataItemValueType1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        list_id = d.pop("list_id")

        position = d.pop("position")

        def _parse_value(
            data: object,
        ) -> (
            bool
            | float
            | GetV1ContentListItemsResponse200DataItemValueType1
            | list[Any]
            | None
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                value_type_1 = GetV1ContentListItemsResponse200DataItemValueType1.from_dict(data)

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
                | GetV1ContentListItemsResponse200DataItemValueType1
                | list[Any]
                | None
                | str,
                data,
            )

        value = _parse_value(d.pop("value"))

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["content.list_item"] | Unset, d.pop("object", UNSET))
        if object_ != "content.list_item" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'content.list_item', got '{object_}'")

        get_v1_content_list_items_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            list_id=list_id,
            position=position,
            value=value,
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return get_v1_content_list_items_response_200_data_item
