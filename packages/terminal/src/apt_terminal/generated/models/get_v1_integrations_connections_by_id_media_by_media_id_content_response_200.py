from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200")


@_attrs_define
class GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200:
    """
    Attributes:
        url (str):
        expires_at (str):
        object_ (Literal['media'] | Unset):
    """

    url: str
    expires_at: str
    object_: Literal["media"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        url = self.url

        expires_at = self.expires_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "url": url,
                "expires_at": expires_at,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        url = d.pop("url")

        expires_at = d.pop("expires_at")

        object_ = cast(Literal["media"] | Unset, d.pop("object", UNSET))
        if object_ != "media" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'media', got '{object_}'")

        get_v1_integrations_connections_by_id_media_by_media_id_content_response_200 = cls(
            url=url,
            expires_at=expires_at,
            object_=object_,
        )

        get_v1_integrations_connections_by_id_media_by_media_id_content_response_200.additional_properties = d
        return get_v1_integrations_connections_by_id_media_by_media_id_content_response_200

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
