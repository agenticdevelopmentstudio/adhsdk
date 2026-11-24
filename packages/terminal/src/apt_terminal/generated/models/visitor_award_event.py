from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.visitor_award_badge import VisitorAwardBadge


T = TypeVar("T", bound="VisitorAwardEvent")


@_attrs_define
class VisitorAwardEvent:
    """award — the turn earned badges or XP

    Attributes:
        badges (list[VisitorAwardBadge]):
        xp_gained (int):
        leveled_up_to (int | None):
    """

    badges: list[VisitorAwardBadge]
    xp_gained: int
    leveled_up_to: int | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        badges = []
        for badges_item_data in self.badges:
            badges_item = badges_item_data.to_dict()
            badges.append(badges_item)

        xp_gained = self.xp_gained

        leveled_up_to: int | None
        leveled_up_to = self.leveled_up_to

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "badges": badges,
                "xp_gained": xp_gained,
                "leveled_up_to": leveled_up_to,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.visitor_award_badge import VisitorAwardBadge

        d = dict(src_dict)
        badges = []
        _badges = d.pop("badges")
        for badges_item_data in _badges:
            badges_item = VisitorAwardBadge.from_dict(badges_item_data)

            badges.append(badges_item)

        xp_gained = d.pop("xp_gained")

        def _parse_leveled_up_to(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        leveled_up_to = _parse_leveled_up_to(d.pop("leveled_up_to"))

        visitor_award_event = cls(
            badges=badges,
            xp_gained=xp_gained,
            leveled_up_to=leveled_up_to,
        )

        visitor_award_event.additional_properties = d
        return visitor_award_event

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
