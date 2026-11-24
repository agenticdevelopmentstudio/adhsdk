from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_game_definitions_by_id_body_data_type_0_type_1 import (
        PostV1GameDefinitionsByIdBodyDataType0Type1,
    )


T = TypeVar("T", bound="PostV1GameDefinitionsByIdBody")


@_attrs_define
class PostV1GameDefinitionsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        game_id (str | Unset):
        kind (str | Unset):
        key (str | Unset):
        name (str | Unset):
        description (None | str | Unset):
        status (str | Unset):
        sort_order (int | Unset):
        data (bool | float | list[Any] | None | PostV1GameDefinitionsByIdBodyDataType0Type1 | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    game_id: str | Unset = UNSET
    kind: str | Unset = UNSET
    key: str | Unset = UNSET
    name: str | Unset = UNSET
    description: None | str | Unset = UNSET
    status: str | Unset = UNSET
    sort_order: int | Unset = UNSET
    data: (
        bool | float | list[Any] | None | PostV1GameDefinitionsByIdBodyDataType0Type1 | str | Unset
    ) = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_game_definitions_by_id_body_data_type_0_type_1 import (
            PostV1GameDefinitionsByIdBodyDataType0Type1,
        )

        ecosystem_id = self.ecosystem_id

        game_id = self.game_id

        kind = self.kind

        key = self.key

        name = self.name

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        status = self.status

        sort_order = self.sort_order

        data: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.data, Unset):
            data = UNSET
        elif isinstance(self.data, PostV1GameDefinitionsByIdBodyDataType0Type1):
            data = self.data.to_dict()
        elif isinstance(self.data, list):
            data = self.data

        else:
            data = self.data

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if game_id is not UNSET:
            field_dict["game_id"] = game_id
        if kind is not UNSET:
            field_dict["kind"] = kind
        if key is not UNSET:
            field_dict["key"] = key
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if status is not UNSET:
            field_dict["status"] = status
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_game_definitions_by_id_body_data_type_0_type_1 import (
            PostV1GameDefinitionsByIdBodyDataType0Type1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        game_id = d.pop("game_id", UNSET)

        kind = d.pop("kind", UNSET)

        key = d.pop("key", UNSET)

        name = d.pop("name", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        status = d.pop("status", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        def _parse_data(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1GameDefinitionsByIdBodyDataType0Type1
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
                data_type_0_type_1 = PostV1GameDefinitionsByIdBodyDataType0Type1.from_dict(data)

                return data_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                data_type_0_type_2 = cast(list[Any], data)

                return data_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostV1GameDefinitionsByIdBodyDataType0Type1
                | str
                | Unset,
                data,
            )

        data = _parse_data(d.pop("data", UNSET))

        post_v1_game_definitions_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            game_id=game_id,
            kind=kind,
            key=key,
            name=name,
            description=description,
            status=status,
            sort_order=sort_order,
            data=data,
        )

        return post_v1_game_definitions_by_id_body
