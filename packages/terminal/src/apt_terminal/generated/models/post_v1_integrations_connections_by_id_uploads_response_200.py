from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsConnectionsByIdUploadsResponse200")


@_attrs_define
class PostV1IntegrationsConnectionsByIdUploadsResponse200:
    """
    Attributes:
        upload_token (str):
        object_ (Literal['upload'] | Unset):
    """

    upload_token: str
    object_: Literal["upload"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        upload_token = self.upload_token

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "upload_token": upload_token,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        upload_token = d.pop("upload_token")

        object_ = cast(Literal["upload"] | Unset, d.pop("object", UNSET))
        if object_ != "upload" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'upload', got '{object_}'")

        post_v1_integrations_connections_by_id_uploads_response_200 = cls(
            upload_token=upload_token,
            object_=object_,
        )

        post_v1_integrations_connections_by_id_uploads_response_200.additional_properties = d
        return post_v1_integrations_connections_by_id_uploads_response_200

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
