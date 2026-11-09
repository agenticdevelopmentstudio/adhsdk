from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="IntegrationPickerSessionState")


@_attrs_define
class IntegrationPickerSessionState:
    """
    Attributes:
        session_id (str):
        media_items_set (bool): true once the user has finished choosing.
        expire_time (None | str):
    """

    session_id: str
    media_items_set: bool
    expire_time: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        session_id = self.session_id

        media_items_set = self.media_items_set

        expire_time: None | str
        expire_time = self.expire_time

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "session_id": session_id,
                "media_items_set": media_items_set,
                "expire_time": expire_time,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        session_id = d.pop("session_id")

        media_items_set = d.pop("media_items_set")

        def _parse_expire_time(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expire_time = _parse_expire_time(d.pop("expire_time"))

        integration_picker_session_state = cls(
            session_id=session_id,
            media_items_set=media_items_set,
            expire_time=expire_time,
        )

        integration_picker_session_state.additional_properties = d
        return integration_picker_session_state

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
