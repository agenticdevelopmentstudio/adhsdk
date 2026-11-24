from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_memory_blocks_by_id_body_content_type_1 import (
        PostV1MemoryBlocksByIdBodyContentType1,
    )


T = TypeVar("T", bound="PostV1MemoryBlocksByIdBody")


@_attrs_define
class PostV1MemoryBlocksByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        name (str | Unset):
        content (bool | float | list[Any] | None | PostV1MemoryBlocksByIdBodyContentType1 | str | Unset):
        size_limit (int | None | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    name: str | Unset = UNSET
    content: (
        bool | float | list[Any] | None | PostV1MemoryBlocksByIdBodyContentType1 | str | Unset
    ) = UNSET
    size_limit: int | None | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_memory_blocks_by_id_body_content_type_1 import (
            PostV1MemoryBlocksByIdBodyContentType1,
        )

        ecosystem_id = self.ecosystem_id

        name = self.name

        content: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.content, Unset):
            content = UNSET
        elif isinstance(self.content, PostV1MemoryBlocksByIdBodyContentType1):
            content = self.content.to_dict()
        elif isinstance(self.content, list):
            content = self.content

        else:
            content = self.content

        size_limit: int | None | Unset
        if isinstance(self.size_limit, Unset):
            size_limit = UNSET
        else:
            size_limit = self.size_limit

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if name is not UNSET:
            field_dict["name"] = name
        if content is not UNSET:
            field_dict["content"] = content
        if size_limit is not UNSET:
            field_dict["size_limit"] = size_limit

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_memory_blocks_by_id_body_content_type_1 import (
            PostV1MemoryBlocksByIdBodyContentType1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        name = d.pop("name", UNSET)

        def _parse_content(
            data: object,
        ) -> bool | float | list[Any] | None | PostV1MemoryBlocksByIdBodyContentType1 | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                content_type_1 = PostV1MemoryBlocksByIdBodyContentType1.from_dict(data)

                return content_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                content_type_2 = cast(list[Any], data)

                return content_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostV1MemoryBlocksByIdBodyContentType1
                | str
                | Unset,
                data,
            )

        content = _parse_content(d.pop("content", UNSET))

        def _parse_size_limit(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        size_limit = _parse_size_limit(d.pop("size_limit", UNSET))

        post_v1_memory_blocks_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            content=content,
            size_limit=size_limit,
        )

        return post_v1_memory_blocks_by_id_body
