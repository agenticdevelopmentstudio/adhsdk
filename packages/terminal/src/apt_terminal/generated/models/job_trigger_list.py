from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.job_trigger import JobTrigger


T = TypeVar("T", bound="JobTriggerList")


@_attrs_define
class JobTriggerList:
    """
    Attributes:
        triggers (list[JobTrigger]):
    """

    triggers: list[JobTrigger]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        triggers = []
        for triggers_item_data in self.triggers:
            triggers_item = triggers_item_data.to_dict()
            triggers.append(triggers_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "triggers": triggers,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_trigger import JobTrigger

        d = dict(src_dict)
        triggers = []
        _triggers = d.pop("triggers")
        for triggers_item_data in _triggers:
            triggers_item = JobTrigger.from_dict(triggers_item_data)

            triggers.append(triggers_item)

        job_trigger_list = cls(
            triggers=triggers,
        )

        job_trigger_list.additional_properties = d
        return job_trigger_list

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
