from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_cost_report_group_by import UsageCostReportGroupBy
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.usage_cost_row import UsageCostRow


T = TypeVar("T", bound="GetV1UsageCostsResponse200")


@_attrs_define
class GetV1UsageCostsResponse200:
    """
    Attributes:
        from_ (datetime.date):
        to (datetime.date): Inclusive
        group_by (UsageCostReportGroupBy):
        rows (list[UsageCostRow]):
        object_ (Literal['usage.cost'] | Unset):
    """

    from_: datetime.date
    to: datetime.date
    group_by: UsageCostReportGroupBy
    rows: list[UsageCostRow]
    object_: Literal["usage.cost"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from_ = self.from_.isoformat()

        to = self.to.isoformat()

        group_by = self.group_by.value

        rows = []
        for rows_item_data in self.rows:
            rows_item = rows_item_data.to_dict()
            rows.append(rows_item)

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["usage.cost"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.cost" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.cost', got '{object_}'")

        get_v1_usage_costs_response_200 = cls(
            from_=from_,
            to=to,
            group_by=group_by,
            rows=rows,
            object_=object_,
        )

        get_v1_usage_costs_response_200.additional_properties = d
        return get_v1_usage_costs_response_200

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
