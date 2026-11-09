from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.post_v1_gamification_levels_body_rungs_item import (
        PostV1GamificationLevelsBodyRungsItem,
    )


T = TypeVar("T", bound="PostV1GamificationLevelsBody")


@_attrs_define
class PostV1GamificationLevelsBody:
    """
    Attributes:
        rungs (list[PostV1GamificationLevelsBodyRungsItem]):
        ecosystem (str): Scopes the call; the caller passes it as a parameter, not in the path.
    """

    rungs: list[PostV1GamificationLevelsBodyRungsItem]
    ecosystem: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rungs = []
        for rungs_item_data in self.rungs:
            rungs_item = rungs_item_data.to_dict()
            rungs.append(rungs_item)

        ecosystem = self.ecosystem

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rungs": rungs,
                "ecosystem": ecosystem,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_gamification_levels_body_rungs_item import (
            PostV1GamificationLevelsBodyRungsItem,
        )

        d = dict(src_dict)
        rungs = []
        _rungs = d.pop("rungs")
        for rungs_item_data in _rungs:
            rungs_item = PostV1GamificationLevelsBodyRungsItem.from_dict(rungs_item_data)

            rungs.append(rungs_item)

        ecosystem = d.pop("ecosystem")

        post_v1_gamification_levels_body = cls(
            rungs=rungs,
            ecosystem=ecosystem,
        )

        post_v1_gamification_levels_body.additional_properties = d
        return post_v1_gamification_levels_body

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
