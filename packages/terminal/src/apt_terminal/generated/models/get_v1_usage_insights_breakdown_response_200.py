from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_insight_breakdown_by import UsageInsightBreakdownBy
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.usage_insight_breakdown_row import UsageInsightBreakdownRow


T = TypeVar("T", bound="GetV1UsageInsightsBreakdownResponse200")


@_attrs_define
class GetV1UsageInsightsBreakdownResponse200:
    """
    Attributes:
        by (UsageInsightBreakdownBy):
        total (int): Rows before paging
        fixed_micros (int): Fixed cost over the range (the shared pool)
        rows (list[UsageInsightBreakdownRow]):
        object_ (Literal['usage.insight'] | Unset):
    """

    by: UsageInsightBreakdownBy
    total: int
    fixed_micros: int
    rows: list[UsageInsightBreakdownRow]
    object_: Literal["usage.insight"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        by = self.by.value

        total = self.total

        fixed_micros = self.fixed_micros

        rows = []
        for rows_item_data in self.rows:
            rows_item = rows_item_data.to_dict()
            rows.append(rows_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "by": by,
                "total": total,
                "fixed_micros": fixed_micros,
                "rows": rows,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_insight_breakdown_row import UsageInsightBreakdownRow

        d = dict(src_dict)
        by = UsageInsightBreakdownBy(d.pop("by"))

        total = d.pop("total")

        fixed_micros = d.pop("fixed_micros")

        rows = []
        _rows = d.pop("rows")
        for rows_item_data in _rows:
            rows_item = UsageInsightBreakdownRow.from_dict(rows_item_data)

            rows.append(rows_item)

        object_ = cast(Literal["usage.insight"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.insight" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.insight', got '{object_}'")

        get_v1_usage_insights_breakdown_response_200 = cls(
            by=by,
            total=total,
            fixed_micros=fixed_micros,
            rows=rows,
            object_=object_,
        )

        get_v1_usage_insights_breakdown_response_200.additional_properties = d
        return get_v1_usage_insights_breakdown_response_200

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
