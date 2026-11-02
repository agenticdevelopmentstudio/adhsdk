from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_account_mfa_preference_response_200_preferred_method_type_1 import (
    GetAccountMfaPreferenceResponse200PreferredMethodType1,
)
from ..models.get_account_mfa_preference_response_200_preferred_method_type_2_type_1 import (
    GetAccountMfaPreferenceResponse200PreferredMethodType2Type1,
)
from ..models.get_account_mfa_preference_response_200_preferred_method_type_3_type_1 import (
    GetAccountMfaPreferenceResponse200PreferredMethodType3Type1,
)

T = TypeVar("T", bound="GetAccountMfaPreferenceResponse200")


@_attrs_define
class GetAccountMfaPreferenceResponse200:
    """
    Attributes:
        preferred_method (GetAccountMfaPreferenceResponse200PreferredMethodType1 |
            GetAccountMfaPreferenceResponse200PreferredMethodType2Type1 |
            GetAccountMfaPreferenceResponse200PreferredMethodType3Type1 | None):
    """

    preferred_method: (
        GetAccountMfaPreferenceResponse200PreferredMethodType1
        | GetAccountMfaPreferenceResponse200PreferredMethodType2Type1
        | GetAccountMfaPreferenceResponse200PreferredMethodType3Type1
        | None
    )
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        preferred_method: None | str
        if (
            isinstance(
                self.preferred_method, GetAccountMfaPreferenceResponse200PreferredMethodType1
            )
            or isinstance(
                self.preferred_method, GetAccountMfaPreferenceResponse200PreferredMethodType2Type1
            )
            or isinstance(
                self.preferred_method, GetAccountMfaPreferenceResponse200PreferredMethodType3Type1
            )
        ):
            preferred_method = self.preferred_method.value
        else:
            preferred_method = self.preferred_method

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "preferredMethod": preferred_method,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)

        def _parse_preferred_method(
            data: object,
        ) -> (
            GetAccountMfaPreferenceResponse200PreferredMethodType1
            | GetAccountMfaPreferenceResponse200PreferredMethodType2Type1
            | GetAccountMfaPreferenceResponse200PreferredMethodType3Type1
            | None
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_1 = GetAccountMfaPreferenceResponse200PreferredMethodType1(
                    data
                )

                return preferred_method_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_2_type_1 = (
                    GetAccountMfaPreferenceResponse200PreferredMethodType2Type1(data)
                )

                return preferred_method_type_2_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_3_type_1 = (
                    GetAccountMfaPreferenceResponse200PreferredMethodType3Type1(data)
                )

                return preferred_method_type_3_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                GetAccountMfaPreferenceResponse200PreferredMethodType1
                | GetAccountMfaPreferenceResponse200PreferredMethodType2Type1
                | GetAccountMfaPreferenceResponse200PreferredMethodType3Type1
                | None,
                data,
            )

        preferred_method = _parse_preferred_method(d.pop("preferredMethod"))

        get_account_mfa_preference_response_200 = cls(
            preferred_method=preferred_method,
        )

        get_account_mfa_preference_response_200.additional_properties = d
        return get_account_mfa_preference_response_200

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
