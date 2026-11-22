from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="CustomerEmailVerifyResult")


@_attrs_define
class CustomerEmailVerifyResult:
    """
    Attributes:
        ok (bool):
        signup_list_applied (int): Sign-up list entries applied to the customer by this confirmation
        invitation_accepted (bool): Whether a registered invitation to the address was accepted
    """

    ok: bool
    signup_list_applied: int
    invitation_accepted: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ok = self.ok

        signup_list_applied = self.signup_list_applied

        invitation_accepted = self.invitation_accepted

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ok": ok,
                "signup_list_applied": signup_list_applied,
                "invitation_accepted": invitation_accepted,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ok = d.pop("ok")

        signup_list_applied = d.pop("signup_list_applied")

        invitation_accepted = d.pop("invitation_accepted")

        customer_email_verify_result = cls(
            ok=ok,
            signup_list_applied=signup_list_applied,
            invitation_accepted=invitation_accepted,
        )

        customer_email_verify_result.additional_properties = d
        return customer_email_verify_result

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
