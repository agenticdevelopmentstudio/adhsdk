from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.invite_accept_result_status import InviteAcceptResultStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="InviteAcceptResult")


@_attrs_define
class InviteAcceptResult:
    """
    Attributes:
        status (InviteAcceptResultStatus):
        ecosystem_name (str | Unset):
    """

    status: InviteAcceptResultStatus
    ecosystem_name: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        status = self.status.value

        ecosystem_name = self.ecosystem_name

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "status": status,
            }
        )
        if ecosystem_name is not UNSET:
            field_dict["ecosystemName"] = ecosystem_name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        status = InviteAcceptResultStatus(d.pop("status"))

        ecosystem_name = d.pop("ecosystemName", UNSET)

        invite_accept_result = cls(
            status=status,
            ecosystem_name=ecosystem_name,
        )

        invite_accept_result.additional_properties = d
        return invite_accept_result

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
