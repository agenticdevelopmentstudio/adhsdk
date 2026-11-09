from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.integration_connection_data_page_rows_item import (
        IntegrationConnectionDataPageRowsItem,
    )


T = TypeVar("T", bound="IntegrationConnectionDataPage")


@_attrs_define
class IntegrationConnectionDataPage:
    """
    Attributes:
        rows (list[IntegrationConnectionDataPageRowsItem]):
        next_cursor (None | str): Pass as `cursor` for the next page. null on the last page.
    """

    rows: list[IntegrationConnectionDataPageRowsItem]
    next_cursor: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rows = []
        for rows_item_data in self.rows:
            rows_item = rows_item_data.to_dict()
            rows.append(rows_item)

        next_cursor: None | str
        next_cursor = self.next_cursor

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rows": rows,
                "next_cursor": next_cursor,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_connection_data_page_rows_item import (
            IntegrationConnectionDataPageRowsItem,
        )

        d = dict(src_dict)
        rows = []
        _rows = d.pop("rows")
        for rows_item_data in _rows:
            rows_item = IntegrationConnectionDataPageRowsItem.from_dict(rows_item_data)

            rows.append(rows_item)

        def _parse_next_cursor(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        next_cursor = _parse_next_cursor(d.pop("next_cursor"))

        integration_connection_data_page = cls(
            rows=rows,
            next_cursor=next_cursor,
        )

        integration_connection_data_page.additional_properties = d
        return integration_connection_data_page

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
