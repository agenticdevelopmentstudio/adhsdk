from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.sync_enrollment_row import SyncEnrollmentRow


T = TypeVar("T", bound="SyncEnrollmentList")


@_attrs_define
class SyncEnrollmentList:
    """
    Attributes:
        tables (list[SyncEnrollmentRow]):
    """

    tables: list[SyncEnrollmentRow]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        tables = []
        for tables_item_data in self.tables:
            tables_item = tables_item_data.to_dict()
            tables.append(tables_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "tables": tables,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.sync_enrollment_row import SyncEnrollmentRow

        d = dict(src_dict)
        tables = []
        _tables = d.pop("tables")
        for tables_item_data in _tables:
            tables_item = SyncEnrollmentRow.from_dict(tables_item_data)

            tables.append(tables_item)

        sync_enrollment_list = cls(
            tables=tables,
        )

        sync_enrollment_list.additional_properties = d
        return sync_enrollment_list

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
