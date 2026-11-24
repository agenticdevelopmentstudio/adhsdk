from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_content_key_value_pairs_by_id_body_value_type_1 import (
        PostV1ContentKeyValuePairsByIdBodyValueType1,
    )


T = TypeVar("T", bound="PostV1ContentKeyValuePairsByIdBody")


@_attrs_define
class PostV1ContentKeyValuePairsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        key (str | Unset):
        value (bool | float | list[Any] | None | PostV1ContentKeyValuePairsByIdBodyValueType1 | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    key: str | Unset = UNSET
    value: (
        bool | float | list[Any] | None | PostV1ContentKeyValuePairsByIdBodyValueType1 | str | Unset
    ) = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_content_key_value_pairs_by_id_body_value_type_1 import (
            PostV1ContentKeyValuePairsByIdBodyValueType1,
        )

        ecosystem_id = self.ecosystem_id

        key = self.key

        value: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.value, Unset):
            value = UNSET
        elif isinstance(self.value, PostV1ContentKeyValuePairsByIdBodyValueType1):
            value = self.value.to_dict()
        elif isinstance(self.value, list):
            value = self.value

        else:
            value = self.value

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if key is not UNSET:
            field_dict["key"] = key
        if value is not UNSET:
            field_dict["value"] = value

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_content_key_value_pairs_by_id_body_value_type_1 import (
            PostV1ContentKeyValuePairsByIdBodyValueType1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        key = d.pop("key", UNSET)

        def _parse_value(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1ContentKeyValuePairsByIdBodyValueType1
            | str
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                value_type_1 = PostV1ContentKeyValuePairsByIdBodyValueType1.from_dict(data)

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
                | PostV1ContentKeyValuePairsByIdBodyValueType1
                | str
                | Unset,
                data,
            )

        value = _parse_value(d.pop("value", UNSET))

        post_v1_content_key_value_pairs_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            key=key,
            value=value,
        )

        return post_v1_content_key_value_pairs_by_id_body
