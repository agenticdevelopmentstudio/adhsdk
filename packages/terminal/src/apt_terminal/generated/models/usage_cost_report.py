from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_cost_report_group_by import UsageCostReportGroupBy

if TYPE_CHECKING:
    from ..models.usage_cost_row import UsageCostRow


T = TypeVar("T", bound="UsageCostReport")


@_attrs_define
class UsageCostReport:
    """
    Attributes:
        from_ (datetime.date):
        to (datetime.date): Inclusive
        group_by (UsageCostReportGroupBy):
        rows (list[UsageCostRow]):
    """

    from_: datetime.date
    to: datetime.date
    group_by: UsageCostReportGroupBy
    rows: list[UsageCostRow]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from_ = self.from_.isoformat()

        to = self.to.isoformat()

        group_by = self.group_by.value

        rows = []
        for rows_item_data in self.rows:
            rows_item = rows_item_data.to_dict()
            rows.append(rows_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "from": from_,
                "to": to,
                "group_by": group_by,
                "rows": rows,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_cost_row import UsageCostRow

        d = dict(src_dict)
        from_ = datetime.date.fromisoformat(d.pop("from"))

        to = datetime.date.fromisoformat(d.pop("to"))

        group_by = UsageCostReportGroupBy(d.pop("group_by"))

        rows = []
        _rows = d.pop("rows")
        for rows_item_data in _rows:
            rows_item = UsageCostRow.from_dict(rows_item_data)

            rows.append(rows_item)

        usage_cost_report = cls(
            from_=from_,
            to=to,
            group_by=group_by,
            rows=rows,
        )

        usage_cost_report.additional_properties = d
        return usage_cost_report

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
