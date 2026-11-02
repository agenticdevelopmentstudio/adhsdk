from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="RegistryIdentifier")


@_attrs_define
class RegistryIdentifier:
    """
    Attributes:
        rdid (str): Reverse-domain identifier (e.g. com.acme.app)
        entity_type (str): e.g. 'namespace', 'ecosystem', 'organization'
        entity_id (str): The UUID the rdid resolves to
        created_by (None | str): Minter; null for system mappings
    """

    rdid: str
    entity_type: str
    entity_id: str
    created_by: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rdid = self.rdid

        entity_type = self.entity_type

        entity_id = self.entity_id

        created_by: None | str
        created_by = self.created_by

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rdid": rdid,
                "entityType": entity_type,
                "entityId": entity_id,
                "createdBy": created_by,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        rdid = d.pop("rdid")

        entity_type = d.pop("entityType")

        entity_id = d.pop("entityId")

        def _parse_created_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by = _parse_created_by(d.pop("createdBy"))

        registry_identifier = cls(
            rdid=rdid,
            entity_type=entity_type,
            entity_id=entity_id,
            created_by=created_by,
        )

        registry_identifier.additional_properties = d
        return registry_identifier

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
