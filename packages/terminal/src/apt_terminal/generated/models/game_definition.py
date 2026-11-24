from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.game_definition_status import GameDefinitionStatus
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_definition_data_type_0 import GameDefinitionDataType0


T = TypeVar("T", bound="GameDefinition")


@_attrs_define
class GameDefinition:
    """
    Attributes:
        id (str):
        game_id (str):
        kind (str):
        key (str):
        name (str):
        status (GameDefinitionStatus):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        description (None | str | Unset):
        author_customer_id (None | str | Unset):
        data (GameDefinitionDataType0 | None | Unset):
    """

    id: str
    game_id: str
    kind: str
    key: str
    name: str
    status: GameDefinitionStatus
    created: int
    updated: int
    description: None | str | Unset = UNSET
    author_customer_id: None | str | Unset = UNSET
    data: GameDefinitionDataType0 | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.game_definition_data_type_0 import GameDefinitionDataType0

        id = self.id

        game_id = self.game_id

        kind = self.kind

        key = self.key

        name = self.name

        status = self.status.value

        created = self.created

        updated = self.updated

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        author_customer_id: None | str | Unset
        if isinstance(self.author_customer_id, Unset):
            author_customer_id = UNSET
        else:
            author_customer_id = self.author_customer_id

        data: dict[str, Any] | None | Unset
        if isinstance(self.data, Unset):
            data = UNSET
        elif isinstance(self.data, GameDefinitionDataType0):
            data = self.data.to_dict()
        else:
            data = self.data

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "game_id": game_id,
                "kind": kind,
                "key": key,
                "name": name,
                "status": status,
                "created": created,
                "updated": updated,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if author_customer_id is not UNSET:
            field_dict["author_customer_id"] = author_customer_id
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_definition_data_type_0 import GameDefinitionDataType0

        d = dict(src_dict)
        id = d.pop("id")

        game_id = d.pop("game_id")

        kind = d.pop("kind")

        key = d.pop("key")

        name = d.pop("name")

        status = GameDefinitionStatus(d.pop("status"))

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        def _parse_author_customer_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        author_customer_id = _parse_author_customer_id(d.pop("author_customer_id", UNSET))

        def _parse_data(data: object) -> GameDefinitionDataType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                data_type_0 = GameDefinitionDataType0.from_dict(data)

                return data_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameDefinitionDataType0 | None | Unset, data)

        data = _parse_data(d.pop("data", UNSET))

        game_definition = cls(
            id=id,
            game_id=game_id,
            kind=kind,
            key=key,
            name=name,
            status=status,
            created=created,
            updated=updated,
            description=description,
            author_customer_id=author_customer_id,
            data=data,
        )

        game_definition.additional_properties = d
        return game_definition

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
