from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.chat_definition import ChatDefinition


T = TypeVar("T", bound="GetEcosystemChatDefinitionsEcosystemIdResponse200")


@_attrs_define
class GetEcosystemChatDefinitionsEcosystemIdResponse200:
    """
    Attributes:
        definitions (list[ChatDefinition]):
    """

    definitions: list[ChatDefinition]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        definitions = []
        for definitions_item_data in self.definitions:
            definitions_item = definitions_item_data.to_dict()
            definitions.append(definitions_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "definitions": definitions,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.chat_definition import ChatDefinition

        d = dict(src_dict)
        definitions = []
        _definitions = d.pop("definitions")
        for definitions_item_data in _definitions:
            definitions_item = ChatDefinition.from_dict(definitions_item_data)

            definitions.append(definitions_item)

        get_ecosystem_chat_definitions_ecosystem_id_response_200 = cls(
            definitions=definitions,
        )

        get_ecosystem_chat_definitions_ecosystem_id_response_200.additional_properties = d
        return get_ecosystem_chat_definitions_ecosystem_id_response_200

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
