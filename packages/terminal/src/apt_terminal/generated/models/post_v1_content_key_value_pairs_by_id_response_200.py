from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_content_key_value_pairs_by_id_response_200_value_type_1 import (
        PostV1ContentKeyValuePairsByIdResponse200ValueType1,
    )


T = TypeVar("T", bound="PostV1ContentKeyValuePairsByIdResponse200")


@_attrs_define
class PostV1ContentKeyValuePairsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        key (str):
        value (bool | float | list[Any] | None | PostV1ContentKeyValuePairsByIdResponse200ValueType1 | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['content.key_value_pair'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    key: str
    value: (
        bool | float | list[Any] | None | PostV1ContentKeyValuePairsByIdResponse200ValueType1 | str
    )
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["content.key_value_pair"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_content_key_value_pairs_by_id_response_200_value_type_1 import (
            PostV1ContentKeyValuePairsByIdResponse200ValueType1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        key = self.key

        value: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.value, PostV1ContentKeyValuePairsByIdResponse200ValueType1):
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
                "key": key,
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
        from ..models.post_v1_content_key_value_pairs_by_id_response_200_value_type_1 import (
            PostV1ContentKeyValuePairsByIdResponse200ValueType1,
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

        key = d.pop("key")

        def _parse_value(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1ContentKeyValuePairsByIdResponse200ValueType1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                value_type_1 = PostV1ContentKeyValuePairsByIdResponse200ValueType1.from_dict(data)

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
                | PostV1ContentKeyValuePairsByIdResponse200ValueType1
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

        object_ = cast(Literal["content.key_value_pair"] | Unset, d.pop("object", UNSET))
        if object_ != "content.key_value_pair" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'content.key_value_pair', got '{object_}'")

        post_v1_content_key_value_pairs_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            key=key,
            value=value,
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_content_key_value_pairs_by_id_response_200
