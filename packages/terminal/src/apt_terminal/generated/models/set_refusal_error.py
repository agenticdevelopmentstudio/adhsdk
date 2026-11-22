from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.set_refusal_error_code import SetRefusalErrorCode
from ..models.set_refusal_error_rule import SetRefusalErrorRule
from ..types import UNSET, Unset

T = TypeVar("T", bound="SetRefusalError")


@_attrs_define
class SetRefusalError:
    """
    Attributes:
        code (SetRefusalErrorCode):
        message (str):
        rule (SetRefusalErrorRule): 3: the set must define a limit its contained sets disagree on; 4: the customer holds
            a conflicting set; 6: a containment loop; 8: the edit unsettles a container or puts a holder in conflict; 9: the
            set conflicts with another live offer's set.
        limits (list[str] | Unset): The limits at issue.
        containers (list[UUID] | Unset): Rule 8: the containers left unsettled.
        customers (int | Unset): Rule 8: how many holders would conflict.
    """

    code: SetRefusalErrorCode
    message: str
    rule: SetRefusalErrorRule
    limits: list[str] | Unset = UNSET
    containers: list[UUID] | Unset = UNSET
    customers: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        code = self.code.value

        message = self.message

        rule = self.rule.value

        limits: list[str] | Unset = UNSET
        if not isinstance(self.limits, Unset):
            limits = self.limits

        containers: list[str] | Unset = UNSET
        if not isinstance(self.containers, Unset):
            containers = []
            for containers_item_data in self.containers:
                containers_item = str(containers_item_data)
                containers.append(containers_item)

        customers = self.customers

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "code": code,
                "message": message,
                "rule": rule,
            }
        )
        if limits is not UNSET:
            field_dict["limits"] = limits
        if containers is not UNSET:
            field_dict["containers"] = containers
        if customers is not UNSET:
            field_dict["customers"] = customers

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        code = SetRefusalErrorCode(d.pop("code"))

        message = d.pop("message")

        rule = SetRefusalErrorRule(d.pop("rule"))

        limits = cast(list[str], d.pop("limits", UNSET))

        _containers = d.pop("containers", UNSET)
        containers: list[UUID] | Unset = UNSET
        if _containers is not UNSET:
            containers = []
            for containers_item_data in _containers:
                containers_item = UUID(containers_item_data)

                containers.append(containers_item)

        customers = d.pop("customers", UNSET)

        set_refusal_error = cls(
            code=code,
            message=message,
            rule=rule,
            limits=limits,
            containers=containers,
            customers=customers,
        )

        set_refusal_error.additional_properties = d
        return set_refusal_error

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
