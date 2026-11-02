from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.registry_persona_approval import RegistryPersonaApproval


T = TypeVar("T", bound="GetProcessingPersonasApprovalsResponse200")


@_attrs_define
class GetProcessingPersonasApprovalsResponse200:
    """
    Attributes:
        approvals (list[RegistryPersonaApproval]):
    """

    approvals: list[RegistryPersonaApproval]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        approvals = []
        for approvals_item_data in self.approvals:
            approvals_item = approvals_item_data.to_dict()
            approvals.append(approvals_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "approvals": approvals,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.registry_persona_approval import RegistryPersonaApproval

        d = dict(src_dict)
        approvals = []
        _approvals = d.pop("approvals")
        for approvals_item_data in _approvals:
            approvals_item = RegistryPersonaApproval.from_dict(approvals_item_data)

            approvals.append(approvals_item)

        get_processing_personas_approvals_response_200 = cls(
            approvals=approvals,
        )

        get_processing_personas_approvals_response_200.additional_properties = d
        return get_processing_personas_approvals_response_200

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
