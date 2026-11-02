from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.put_gamification_realms_ecosystem_id_levels_body_rungs_item import (
        PutGamificationRealmsEcosystemIdLevelsBodyRungsItem,
    )


T = TypeVar("T", bound="PutGamificationRealmsEcosystemIdLevelsBody")


@_attrs_define
class PutGamificationRealmsEcosystemIdLevelsBody:
    """
    Attributes:
        rungs (list[PutGamificationRealmsEcosystemIdLevelsBodyRungsItem]):
    """

    rungs: list[PutGamificationRealmsEcosystemIdLevelsBodyRungsItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rungs = []
        for rungs_item_data in self.rungs:
            rungs_item = rungs_item_data.to_dict()
            rungs.append(rungs_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rungs": rungs,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_gamification_realms_ecosystem_id_levels_body_rungs_item import (
            PutGamificationRealmsEcosystemIdLevelsBodyRungsItem,
        )

        d = dict(src_dict)
        rungs = []
        _rungs = d.pop("rungs")
        for rungs_item_data in _rungs:
            rungs_item = PutGamificationRealmsEcosystemIdLevelsBodyRungsItem.from_dict(
                rungs_item_data
            )

            rungs.append(rungs_item)

        put_gamification_realms_ecosystem_id_levels_body = cls(
            rungs=rungs,
        )

        put_gamification_realms_ecosystem_id_levels_body.additional_properties = d
        return put_gamification_realms_ecosystem_id_levels_body

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
