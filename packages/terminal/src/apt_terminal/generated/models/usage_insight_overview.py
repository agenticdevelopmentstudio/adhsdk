from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_insight_overview_interval import UsageInsightOverviewInterval

if TYPE_CHECKING:
    from ..models.usage_insight_overview_point import UsageInsightOverviewPoint


T = TypeVar("T", bound="UsageInsightOverview")


@_attrs_define
class UsageInsightOverview:
    """
    Attributes:
        interval (UsageInsightOverviewInterval):
        points (list[UsageInsightOverviewPoint]):
    """

    interval: UsageInsightOverviewInterval
    points: list[UsageInsightOverviewPoint]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        interval = self.interval.value

        points = []
        for points_item_data in self.points:
            points_item = points_item_data.to_dict()
            points.append(points_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "interval": interval,
                "points": points,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.usage_insight_overview_point import UsageInsightOverviewPoint

        d = dict(src_dict)
        interval = UsageInsightOverviewInterval(d.pop("interval"))

        points = []
        _points = d.pop("points")
        for points_item_data in _points:
            points_item = UsageInsightOverviewPoint.from_dict(points_item_data)

            points.append(points_item)

        usage_insight_overview = cls(
            interval=interval,
            points=points,
        )

        usage_insight_overview.additional_properties = d
        return usage_insight_overview

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
