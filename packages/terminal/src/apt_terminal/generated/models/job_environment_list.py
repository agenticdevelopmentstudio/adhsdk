from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.job_environment import JobEnvironment


T = TypeVar("T", bound="JobEnvironmentList")


@_attrs_define
class JobEnvironmentList:
    """
    Attributes:
        environments (list[JobEnvironment]):
    """

    environments: list[JobEnvironment]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        environments = []
        for environments_item_data in self.environments:
            environments_item = environments_item_data.to_dict()
            environments.append(environments_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "environments": environments,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_environment import JobEnvironment

        d = dict(src_dict)
        environments = []
        _environments = d.pop("environments")
        for environments_item_data in _environments:
            environments_item = JobEnvironment.from_dict(environments_item_data)

            environments.append(environments_item)

        job_environment_list = cls(
            environments=environments,
        )

        job_environment_list.additional_properties = d
        return job_environment_list

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
