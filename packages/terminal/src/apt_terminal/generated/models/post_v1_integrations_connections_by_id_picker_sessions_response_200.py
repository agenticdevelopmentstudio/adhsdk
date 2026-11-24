from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsConnectionsByIdPickerSessionsResponse200")


@_attrs_define
class PostV1IntegrationsConnectionsByIdPickerSessionsResponse200:
    """
    Attributes:
        session_id (str):
        picker_uri (str): Send the user here to choose photos.
        expire_time (None | str):
        object_ (Literal['picker_session'] | Unset):
    """

    session_id: str
    picker_uri: str
    expire_time: None | str
    object_: Literal["picker_session"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        session_id = self.session_id

        picker_uri = self.picker_uri

        expire_time: None | str
        expire_time = self.expire_time

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "session_id": session_id,
                "picker_uri": picker_uri,
                "expire_time": expire_time,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        session_id = d.pop("session_id")

        picker_uri = d.pop("picker_uri")

        def _parse_expire_time(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expire_time = _parse_expire_time(d.pop("expire_time"))

        object_ = cast(Literal["picker_session"] | Unset, d.pop("object", UNSET))
        if object_ != "picker_session" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'picker_session', got '{object_}'")

        post_v1_integrations_connections_by_id_picker_sessions_response_200 = cls(
            session_id=session_id,
            picker_uri=picker_uri,
            expire_time=expire_time,
            object_=object_,
        )

        post_v1_integrations_connections_by_id_picker_sessions_response_200.additional_properties = d
        return post_v1_integrations_connections_by_id_picker_sessions_response_200

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
