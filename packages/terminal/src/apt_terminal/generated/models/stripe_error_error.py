from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.stripe_error_error_type import StripeErrorErrorType
from ..types import UNSET, Unset

T = TypeVar("T", bound="StripeErrorError")


@_attrs_define
class StripeErrorError:
    """
    Attributes:
        type_ (StripeErrorErrorType):
        message (str):
        code (str | Unset): A stable, machine-readable reason, e.g. `resource_missing`.
        param (str | Unset): The parameter the error is about, when there is one.
    """

    type_: StripeErrorErrorType
    message: str
    code: str | Unset = UNSET
    param: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        type_ = self.type_.value

        message = self.message

        code = self.code

        param = self.param

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "type": type_,
                "message": message,
            }
        )
        if code is not UNSET:
            field_dict["code"] = code
        if param is not UNSET:
            field_dict["param"] = param

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        type_ = StripeErrorErrorType(d.pop("type"))

        message = d.pop("message")

        code = d.pop("code", UNSET)

        param = d.pop("param", UNSET)

        stripe_error_error = cls(
            type_=type_,
            message=message,
            code=code,
            param=param,
        )

        stripe_error_error.additional_properties = d
        return stripe_error_error

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
