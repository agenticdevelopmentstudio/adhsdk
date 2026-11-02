from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PutEcosystemApplicationsAppIdSchemaGrantsBodyGrantsItemTablesItem")


@_attrs_define
class PutEcosystemApplicationsAppIdSchemaGrantsBodyGrantsItemTablesItem:
    """
    Attributes:
        table_id (str):
        crud (str):
    """

    table_id: str
    crud: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        table_id = self.table_id

        crud = self.crud

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "tableId": table_id,
                "crud": crud,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        table_id = d.pop("tableId")

        crud = d.pop("crud")

        put_ecosystem_applications_app_id_schema_grants_body_grants_item_tables_item = cls(
            table_id=table_id,
            crud=crud,
        )

        put_ecosystem_applications_app_id_schema_grants_body_grants_item_tables_item.additional_properties = d
        return put_ecosystem_applications_app_id_schema_grants_body_grants_item_tables_item

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
