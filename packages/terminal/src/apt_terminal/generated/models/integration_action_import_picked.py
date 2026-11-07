from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationActionImportPicked")


@_attrs_define
class IntegrationActionImportPicked:
    """actionType=import_picked — google-photos: copy one page (50 items) of a finished Picker session into an album;
    repeat with the next pageToken

        Attributes:
            session_id (str):
            album_id (str):
            page_token (str | Unset):
    """

    session_id: str
    album_id: str
    page_token: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        session_id = self.session_id

        album_id = self.album_id

        page_token = self.page_token

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "sessionId": session_id,
                "albumId": album_id,
            }
        )
        if page_token is not UNSET:
            field_dict["pageToken"] = page_token

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        session_id = d.pop("sessionId")

        album_id = d.pop("albumId")

        page_token = d.pop("pageToken", UNSET)

        integration_action_import_picked = cls(
            session_id=session_id,
            album_id=album_id,
            page_token=page_token,
        )

        integration_action_import_picked.additional_properties = d
        return integration_action_import_picked

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
