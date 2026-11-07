from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="IntegrationPickerSessionStart")


@_attrs_define
class IntegrationPickerSessionStart:
    """
    Attributes:
        session_id (str):
        picker_uri (str): Send the user here to choose photos.
        expire_time (None | str):
    """

    session_id: str
    picker_uri: str
    expire_time: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        session_id = self.session_id

        picker_uri = self.picker_uri

        expire_time: None | str
        expire_time = self.expire_time

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "sessionId": session_id,
                "pickerUri": picker_uri,
                "expireTime": expire_time,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        session_id = d.pop("sessionId")

        picker_uri = d.pop("pickerUri")

        def _parse_expire_time(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expire_time = _parse_expire_time(d.pop("expireTime"))

        integration_picker_session_start = cls(
            session_id=session_id,
            picker_uri=picker_uri,
            expire_time=expire_time,
        )

        integration_picker_session_start.additional_properties = d
        return integration_picker_session_start

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
