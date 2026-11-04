from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.put_persona_memory_blocks_id_body_content_type_1 import (
        PutPersonaMemoryBlocksIdBodyContentType1,
    )


T = TypeVar("T", bound="PutPersonaMemoryBlocksIdBody")


@_attrs_define
class PutPersonaMemoryBlocksIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        name (str | Unset):
        content (bool | float | list[Any] | None | PutPersonaMemoryBlocksIdBodyContentType1 | str | Unset):
        size_limit (int | None | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    name: str | Unset = UNSET
    content: (
        bool | float | list[Any] | None | PutPersonaMemoryBlocksIdBodyContentType1 | str | Unset
    ) = UNSET
    size_limit: int | None | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.put_persona_memory_blocks_id_body_content_type_1 import (
            PutPersonaMemoryBlocksIdBodyContentType1,
        )

        ecosystem_id = self.ecosystem_id

        name = self.name

        content: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.content, Unset):
            content = UNSET
        elif isinstance(self.content, PutPersonaMemoryBlocksIdBodyContentType1):
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
            field_dict["ecosystemId"] = ecosystem_id
        if name is not UNSET:
            field_dict["name"] = name
        if content is not UNSET:
            field_dict["content"] = content
        if size_limit is not UNSET:
            field_dict["sizeLimit"] = size_limit

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_persona_memory_blocks_id_body_content_type_1 import (
            PutPersonaMemoryBlocksIdBodyContentType1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        name = d.pop("name", UNSET)

        def _parse_content(
            data: object,
        ) -> (
            bool | float | list[Any] | None | PutPersonaMemoryBlocksIdBodyContentType1 | str | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                content_type_1 = PutPersonaMemoryBlocksIdBodyContentType1.from_dict(data)

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
                | PutPersonaMemoryBlocksIdBodyContentType1
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

        size_limit = _parse_size_limit(d.pop("sizeLimit", UNSET))

        put_persona_memory_blocks_id_body = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            content=content,
            size_limit=size_limit,
        )

        return put_persona_memory_blocks_id_body
