from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.put_content_list_items_id_body_value_type_1 import (
        PutContentListItemsIdBodyValueType1,
    )


T = TypeVar("T", bound="PutContentListItemsIdBody")


@_attrs_define
class PutContentListItemsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        list_id (str | Unset):
        position (int | Unset):
        value (bool | float | list[Any] | None | PutContentListItemsIdBodyValueType1 | str | Unset):
        sync_txid (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    list_id: str | Unset = UNSET
    position: int | Unset = UNSET
    value: bool | float | list[Any] | None | PutContentListItemsIdBodyValueType1 | str | Unset = (
        UNSET
    )
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.put_content_list_items_id_body_value_type_1 import (
            PutContentListItemsIdBodyValueType1,
        )

        ecosystem_id = self.ecosystem_id

        list_id = self.list_id

        position = self.position

        value: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.value, Unset):
            value = UNSET
        elif isinstance(self.value, PutContentListItemsIdBodyValueType1):
            value = self.value.to_dict()
        elif isinstance(self.value, list):
            value = self.value

        else:
            value = self.value

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if list_id is not UNSET:
            field_dict["listId"] = list_id
        if position is not UNSET:
            field_dict["position"] = position
        if value is not UNSET:
            field_dict["value"] = value
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_content_list_items_id_body_value_type_1 import (
            PutContentListItemsIdBodyValueType1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        list_id = d.pop("listId", UNSET)

        position = d.pop("position", UNSET)

        def _parse_value(
            data: object,
        ) -> bool | float | list[Any] | None | PutContentListItemsIdBodyValueType1 | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                value_type_1 = PutContentListItemsIdBodyValueType1.from_dict(data)

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
                bool | float | list[Any] | None | PutContentListItemsIdBodyValueType1 | str | Unset,
                data,
            )

        value = _parse_value(d.pop("value", UNSET))

        sync_txid = d.pop("syncTxid", UNSET)

        put_content_list_items_id_body = cls(
            ecosystem_id=ecosystem_id,
            list_id=list_id,
            position=position,
            value=value,
            sync_txid=sync_txid,
        )

        return put_content_list_items_id_body
