from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.mfa_challenge_methods_item import MfaChallengeMethodsItem

T = TypeVar("T", bound="MfaChallenge")


@_attrs_define
class MfaChallenge:
    """
    Attributes:
        mfa_required (bool):
        token (str): Short-lived MFA pending token
        methods (list[MfaChallengeMethodsItem]): Second factors the user can satisfy
    """

    mfa_required: bool
    token: str
    methods: list[MfaChallengeMethodsItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        mfa_required = self.mfa_required

        token = self.token

        methods = []
        for methods_item_data in self.methods:
            methods_item = methods_item_data.value
            methods.append(methods_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "mfaRequired": mfa_required,
                "token": token,
                "methods": methods,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        mfa_required = d.pop("mfaRequired")

        token = d.pop("token")

        methods = []
        _methods = d.pop("methods")
        for methods_item_data in _methods:
            methods_item = MfaChallengeMethodsItem(methods_item_data)

            methods.append(methods_item)

        mfa_challenge = cls(
            mfa_required=mfa_required,
            token=token,
            methods=methods,
        )

        mfa_challenge.additional_properties = d
        return mfa_challenge

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
