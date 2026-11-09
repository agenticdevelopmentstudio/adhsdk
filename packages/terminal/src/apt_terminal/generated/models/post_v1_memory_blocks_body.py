from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_memory_blocks_body_content_type_1 import (
        PostV1MemoryBlocksBodyContentType1,
    )


T = TypeVar("T", bound="PostV1MemoryBlocksBody")


@_attrs_define
class PostV1MemoryBlocksBody:
    """
    Attributes:
        name (str):
        content (bool | float | list[Any] | None | PostV1MemoryBlocksBodyContentType1 | str):
        ecosystem_id (str | Unset):
        size_limit (int | None | Unset):
    """

    name: str
    content: bool | float | list[Any] | None | PostV1MemoryBlocksBodyContentType1 | str
    ecosystem_id: str | Unset = UNSET
    size_limit: int | None | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_memory_blocks_body_content_type_1 import (
            PostV1MemoryBlocksBodyContentType1,
        )

        name = self.name

        content: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.content, PostV1MemoryBlocksBodyContentType1):
            content = self.content.to_dict()
        elif isinstance(self.content, list):
            content = self.content

        else:
            content = self.content

        ecosystem_id = self.ecosystem_id

        size_limit: int | None | Unset
        if isinstance(self.size_limit, Unset):
            size_limit = UNSET
        else:
            size_limit = self.size_limit

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "name": name,
                "content": content,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if size_limit is not UNSET:
            field_dict["size_limit"] = size_limit

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_memory_blocks_body_content_type_1 import (
            PostV1MemoryBlocksBodyContentType1,
        )

        d = dict(src_dict)
        name = d.pop("name")

        def _parse_content(
            data: object,
        ) -> bool | float | list[Any] | None | PostV1MemoryBlocksBodyContentType1 | str:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                content_type_1 = PostV1MemoryBlocksBodyContentType1.from_dict(data)

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
                bool | float | list[Any] | None | PostV1MemoryBlocksBodyContentType1 | str, data
            )

        content = _parse_content(d.pop("content"))

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        def _parse_size_limit(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        size_limit = _parse_size_limit(d.pop("size_limit", UNSET))

        post_v1_memory_blocks_body = cls(
            name=name,
            content=content,
            ecosystem_id=ecosystem_id,
            size_limit=size_limit,
        )

        return post_v1_memory_blocks_body
