from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.gamification_badge import GamificationBadge


T = TypeVar("T", bound="GamificationAwardResult")


@_attrs_define
class GamificationAwardResult:
    """
    Attributes:
        awarded (bool): false when the subject has opted out
        total (int): The subject’s new point total
        new_badges (list[GamificationBadge]):
    """

    awarded: bool
    total: int
    new_badges: list[GamificationBadge]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        awarded = self.awarded

        total = self.total

        new_badges = []
        for new_badges_item_data in self.new_badges:
            new_badges_item = new_badges_item_data.to_dict()
            new_badges.append(new_badges_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "awarded": awarded,
                "total": total,
                "newBadges": new_badges,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.gamification_badge import GamificationBadge

        d = dict(src_dict)
        awarded = d.pop("awarded")

        total = d.pop("total")

        new_badges = []
        _new_badges = d.pop("newBadges")
        for new_badges_item_data in _new_badges:
            new_badges_item = GamificationBadge.from_dict(new_badges_item_data)

            new_badges.append(new_badges_item)

        gamification_award_result = cls(
            awarded=awarded,
            total=total,
            new_badges=new_badges,
        )

        gamification_award_result.additional_properties = d
        return gamification_award_result

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
