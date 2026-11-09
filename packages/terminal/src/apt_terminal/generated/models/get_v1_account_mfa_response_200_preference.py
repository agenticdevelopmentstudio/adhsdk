from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_account_mfa_response_200_preference_preferred_method_type_1 import (
    GetV1AccountMfaResponse200PreferencePreferredMethodType1,
)
from ..models.get_v1_account_mfa_response_200_preference_preferred_method_type_2_type_1 import (
    GetV1AccountMfaResponse200PreferencePreferredMethodType2Type1,
)
from ..models.get_v1_account_mfa_response_200_preference_preferred_method_type_3_type_1 import (
    GetV1AccountMfaResponse200PreferencePreferredMethodType3Type1,
)

T = TypeVar("T", bound="GetV1AccountMfaResponse200Preference")


@_attrs_define
class GetV1AccountMfaResponse200Preference:
    """
    Attributes:
        preferred_method (GetV1AccountMfaResponse200PreferencePreferredMethodType1 |
            GetV1AccountMfaResponse200PreferencePreferredMethodType2Type1 |
            GetV1AccountMfaResponse200PreferencePreferredMethodType3Type1 | None):
    """

    preferred_method: (
        GetV1AccountMfaResponse200PreferencePreferredMethodType1
        | GetV1AccountMfaResponse200PreferencePreferredMethodType2Type1
        | GetV1AccountMfaResponse200PreferencePreferredMethodType3Type1
        | None
    )
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        preferred_method: None | str
        if (
            isinstance(
                self.preferred_method, GetV1AccountMfaResponse200PreferencePreferredMethodType1
            )
            or isinstance(
                self.preferred_method, GetV1AccountMfaResponse200PreferencePreferredMethodType2Type1
            )
            or isinstance(
                self.preferred_method, GetV1AccountMfaResponse200PreferencePreferredMethodType3Type1
            )
        ):
            preferred_method = self.preferred_method.value
        else:
            preferred_method = self.preferred_method

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "preferred_method": preferred_method,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)

        def _parse_preferred_method(
            data: object,
        ) -> (
            GetV1AccountMfaResponse200PreferencePreferredMethodType1
            | GetV1AccountMfaResponse200PreferencePreferredMethodType2Type1
            | GetV1AccountMfaResponse200PreferencePreferredMethodType3Type1
            | None
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_1 = GetV1AccountMfaResponse200PreferencePreferredMethodType1(
                    data
                )

                return preferred_method_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_2_type_1 = (
                    GetV1AccountMfaResponse200PreferencePreferredMethodType2Type1(data)
                )

                return preferred_method_type_2_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_3_type_1 = (
                    GetV1AccountMfaResponse200PreferencePreferredMethodType3Type1(data)
                )

                return preferred_method_type_3_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                GetV1AccountMfaResponse200PreferencePreferredMethodType1
                | GetV1AccountMfaResponse200PreferencePreferredMethodType2Type1
                | GetV1AccountMfaResponse200PreferencePreferredMethodType3Type1
                | None,
                data,
            )

        preferred_method = _parse_preferred_method(d.pop("preferred_method"))

        get_v1_account_mfa_response_200_preference = cls(
            preferred_method=preferred_method,
        )

        get_v1_account_mfa_response_200_preference.additional_properties = d
        return get_v1_account_mfa_response_200_preference

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
