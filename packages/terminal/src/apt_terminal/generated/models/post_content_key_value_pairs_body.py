from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_content_key_value_pairs_body_value_type_1 import (
        PostContentKeyValuePairsBodyValueType1,
    )


T = TypeVar("T", bound="PostContentKeyValuePairsBody")


@_attrs_define
class PostContentKeyValuePairsBody:
    """
    Attributes:
        key (str):
        value (bool | float | list[Any] | None | PostContentKeyValuePairsBodyValueType1 | str):
        ecosystem_id (str | Unset):
        sync_txid (int | Unset):
    """

    key: str
    value: bool | float | list[Any] | None | PostContentKeyValuePairsBodyValueType1 | str
    ecosystem_id: str | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_content_key_value_pairs_body_value_type_1 import (
            PostContentKeyValuePairsBodyValueType1,
        )

        key = self.key

        value: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.value, PostContentKeyValuePairsBodyValueType1):
            value = self.value.to_dict()
        elif isinstance(self.value, list):
            value = self.value

        else:
            value = self.value

        ecosystem_id = self.ecosystem_id

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "key": key,
                "value": value,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_content_key_value_pairs_body_value_type_1 import (
            PostContentKeyValuePairsBodyValueType1,
        )

        d = dict(src_dict)
        key = d.pop("key")

        def _parse_value(
            data: object,
        ) -> bool | float | list[Any] | None | PostContentKeyValuePairsBodyValueType1 | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                value_type_1 = PostContentKeyValuePairsBodyValueType1.from_dict(data)

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
                bool | float | list[Any] | None | PostContentKeyValuePairsBodyValueType1 | str, data
            )

        value = _parse_value(d.pop("value"))

        ecosystem_id = d.pop("ecosystemId", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        post_content_key_value_pairs_body = cls(
            key=key,
            value=value,
            ecosystem_id=ecosystem_id,
            sync_txid=sync_txid,
        )

        return post_content_key_value_pairs_body
