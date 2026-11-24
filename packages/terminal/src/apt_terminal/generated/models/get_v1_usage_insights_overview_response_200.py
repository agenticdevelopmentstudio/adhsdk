from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.usage_insight_overview_interval import UsageInsightOverviewInterval
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.usage_insight_overview_point import UsageInsightOverviewPoint


T = TypeVar("T", bound="GetV1UsageInsightsOverviewResponse200")


@_attrs_define
class GetV1UsageInsightsOverviewResponse200:
    """
    Attributes:
        interval (UsageInsightOverviewInterval):
        points (list[UsageInsightOverviewPoint]):
        object_ (Literal['usage.insight'] | Unset):
    """

    interval: UsageInsightOverviewInterval
    points: list[UsageInsightOverviewPoint]
    object_: Literal["usage.insight"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        interval = self.interval.value

        points = []
        for points_item_data in self.points:
            points_item = points_item_data.to_dict()
            points.append(points_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "interval": interval,
                "points": points,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["usage.insight"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.insight" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.insight', got '{object_}'")

        get_v1_usage_insights_overview_response_200 = cls(
            interval=interval,
            points=points,
            object_=object_,
        )

        get_v1_usage_insights_overview_response_200.additional_properties = d
        return get_v1_usage_insights_overview_response_200

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
