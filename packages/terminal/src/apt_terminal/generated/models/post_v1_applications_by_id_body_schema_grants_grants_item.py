from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.post_v1_applications_by_id_body_schema_grants_grants_item_tables_item import (
        PostV1ApplicationsByIdBodySchemaGrantsGrantsItemTablesItem,
    )


T = TypeVar("T", bound="PostV1ApplicationsByIdBodySchemaGrantsGrantsItem")


@_attrs_define
class PostV1ApplicationsByIdBodySchemaGrantsGrantsItem:
    """
    Attributes:
        schema_id (str): the bucket id the grant is for
        crud (str):
        tables (list[PostV1ApplicationsByIdBodySchemaGrantsGrantsItemTablesItem]):
    """

    schema_id: str
    crud: str
    tables: list[PostV1ApplicationsByIdBodySchemaGrantsGrantsItemTablesItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        schema_id = self.schema_id

        crud = self.crud

        tables = []
        for tables_item_data in self.tables:
            tables_item = tables_item_data.to_dict()
            tables.append(tables_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "schema_id": schema_id,
                "crud": crud,
                "tables": tables,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_applications_by_id_body_schema_grants_grants_item_tables_item import (
            PostV1ApplicationsByIdBodySchemaGrantsGrantsItemTablesItem,
        )

        d = dict(src_dict)
        schema_id = d.pop("schema_id")

        crud = d.pop("crud")

        tables = []
        _tables = d.pop("tables")
        for tables_item_data in _tables:
            tables_item = PostV1ApplicationsByIdBodySchemaGrantsGrantsItemTablesItem.from_dict(
                tables_item_data
            )

            tables.append(tables_item)

        post_v1_applications_by_id_body_schema_grants_grants_item = cls(
            schema_id=schema_id,
            crud=crud,
            tables=tables,
        )

        post_v1_applications_by_id_body_schema_grants_grants_item.additional_properties = d
        return post_v1_applications_by_id_body_schema_grants_grants_item

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
