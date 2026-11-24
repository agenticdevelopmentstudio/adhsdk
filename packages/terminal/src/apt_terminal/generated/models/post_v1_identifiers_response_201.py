from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IdentifiersResponse201")


@_attrs_define
class PostV1IdentifiersResponse201:
    """
    Attributes:
        rdid (str): Reverse-domain identifier (e.g. com.acme.app)
        entity_type (str): e.g. 'namespace', 'ecosystem', 'organization'
        entity_id (str): The UUID the rdid resolves to
        created_by (None | str): Minter; null for system mappings
        object_ (Literal['identifier'] | Unset):
    """

    rdid: str
    entity_type: str
    entity_id: str
    created_by: None | str
    object_: Literal["identifier"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rdid = self.rdid

        entity_type = self.entity_type

        entity_id = self.entity_id

        created_by: None | str
        created_by = self.created_by

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rdid": rdid,
                "entity_type": entity_type,
                "entity_id": entity_id,
                "created_by": created_by,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        rdid = d.pop("rdid")

        entity_type = d.pop("entity_type")

        entity_id = d.pop("entity_id")

        def _parse_created_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by = _parse_created_by(d.pop("created_by"))

        object_ = cast(Literal["identifier"] | Unset, d.pop("object", UNSET))
        if object_ != "identifier" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'identifier', got '{object_}'")

        post_v1_identifiers_response_201 = cls(
            rdid=rdid,
            entity_type=entity_type,
            entity_id=entity_id,
            created_by=created_by,
            object_=object_,
        )

        post_v1_identifiers_response_201.additional_properties = d
        return post_v1_identifiers_response_201

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
