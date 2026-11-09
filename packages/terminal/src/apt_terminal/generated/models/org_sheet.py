from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.org_sheet_subject_type import OrgSheetSubjectType

if TYPE_CHECKING:
    from ..models.org_sheet_stats import OrgSheetStats


T = TypeVar("T", bound="OrgSheet")


@_attrs_define
class OrgSheet:
    """
    Attributes:
        subject_type (OrgSheetSubjectType):
        subject_id (str):
        name (str):
        slug (str):
        skin (str):
        level (int):
        level_title (None | str):
        xp (int):
        xp_into_level (int):
        xp_for_next (int):
        member_count (int):
        stats (OrgSheetStats):
    """

    subject_type: OrgSheetSubjectType
    subject_id: str
    name: str
    slug: str
    skin: str
    level: int
    level_title: None | str
    xp: int
    xp_into_level: int
    xp_for_next: int
    member_count: int
    stats: OrgSheetStats
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_type = self.subject_type.value

        subject_id = self.subject_id

        name = self.name

        slug = self.slug

        skin = self.skin

        level = self.level

        level_title: None | str
        level_title = self.level_title

        xp = self.xp

        xp_into_level = self.xp_into_level

        xp_for_next = self.xp_for_next

        member_count = self.member_count

        stats = self.stats.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject_type": subject_type,
                "subject_id": subject_id,
                "name": name,
                "slug": slug,
                "skin": skin,
                "level": level,
                "level_title": level_title,
                "xp": xp,
                "xp_into_level": xp_into_level,
                "xp_for_next": xp_for_next,
                "member_count": member_count,
                "stats": stats,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.org_sheet_stats import OrgSheetStats

        d = dict(src_dict)
        subject_type = OrgSheetSubjectType(d.pop("subject_type"))

        subject_id = d.pop("subject_id")

        name = d.pop("name")

        slug = d.pop("slug")

        skin = d.pop("skin")

        level = d.pop("level")

        def _parse_level_title(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        level_title = _parse_level_title(d.pop("level_title"))

        xp = d.pop("xp")

        xp_into_level = d.pop("xp_into_level")

        xp_for_next = d.pop("xp_for_next")

        member_count = d.pop("member_count")

        stats = OrgSheetStats.from_dict(d.pop("stats"))

        org_sheet = cls(
            subject_type=subject_type,
            subject_id=subject_id,
            name=name,
            slug=slug,
            skin=skin,
            level=level,
            level_title=level_title,
            xp=xp,
            xp_into_level=xp_into_level,
            xp_for_next=xp_for_next,
            member_count=member_count,
            stats=stats,
        )

        org_sheet.additional_properties = d
        return org_sheet

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
